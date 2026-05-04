#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "time"
require "yaml"

options = {
  ha_config: nil,
  output: nil,
  bridge_name: nil,
  overrides: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: export_homekit_room_map.rb --ha-config PATH --output PATH [--bridge-name NAME] [--overrides PATH]"
  opts.on("--ha-config PATH", "Path containing packages/ and .storage/") { |v| options[:ha_config] = v }
  opts.on("--output PATH", "Output JSON path") { |v| options[:output] = v }
  opts.on("--bridge-name NAME", "Home Assistant HomeKit bridge name to export") { |v| options[:bridge_name] = v }
  opts.on("--overrides PATH", "Optional JSON accessory-name -> room overrides") { |v| options[:overrides] = v }
end.parse!

unless options[:ha_config] && options[:output]
  warn "Missing --ha-config or --output"
  exit 2
end

root = File.expand_path(options[:ha_config])
output = File.expand_path(options[:output])

def read_json(path)
  JSON.parse(File.read(path))
end

def registry_items(data, key)
  data.fetch("data", {}).fetch(key, [])
end

areas = registry_items(read_json(File.join(root, ".storage/core.area_registry")), "areas")
devices = registry_items(read_json(File.join(root, ".storage/core.device_registry")), "devices")
entities = registry_items(read_json(File.join(root, ".storage/core.entity_registry")), "entities")
overrides_path = options[:overrides] ? File.expand_path(options[:overrides]) : File.expand_path("../room_overrides.json", __dir__)
room_overrides = File.exist?(overrides_path) ? JSON.parse(File.read(overrides_path)) : {}

area_by_id = areas.to_h { |a| [a["id"], a] }
device_by_id = devices.to_h { |d| [d["id"], d] }
entity_by_id = entities.to_h { |e| [e["entity_id"], e] }
entity_by_unique_id = entities.group_by { |e| e["unique_id"] }

bridge_config = YAML.safe_load(File.read(File.join(root, "packages/homekit_bridge.yaml")), aliases: true)
template_path = File.join(root, "packages/homekit_template_lights.yaml")
template_config = File.exist?(template_path) ? YAML.safe_load(File.read(template_path), aliases: true) : {}

bridges = bridge_config.fetch("homekit")
bridge = if options[:bridge_name]
  bridges.find { |item| item["name"] == options[:bridge_name] }
else
  bridges.first
end

unless bridge
  warn "HomeKit bridge not found. Available bridges: #{bridges.map { |item| item["name"] }.compact.join(", ")}"
  exit 1
end

include_entities = bridge.fetch("filter", {}).fetch("include_entities", [])
entity_config = bridge.fetch("entity_config", {})

template_underlying_by_entity_id = {}
Array(template_config["template"]).each do |block|
  Array(block["light"]).each do |light|
    unique_id = light["unique_id"]
    next unless unique_id

    template_entity = Array(entity_by_unique_id[unique_id]).find { |e| e["platform"] == "template" }
    next unless template_entity

    haystack = [
      light["state"],
      light.dig("turn_on", 0, "target", "entity_id"),
      light.dig("turn_off", 0, "target", "entity_id")
    ].compact.join(" ")
    underlying = haystack.scan(/(?:switch|light|fan|cover|climate)\.[a-zA-Z0-9_]+/).first
    template_underlying_by_entity_id[template_entity["entity_id"]] = underlying if underlying
  end
end

def entity_area_id(entity, device_by_id)
  return nil unless entity

  entity["area_id"] ||
    (entity["device_id"] && device_by_id[entity["device_id"]] && device_by_id[entity["device_id"]]["area_id"])
end

def display_name(entity)
  return nil unless entity

  entity["name"] || entity["original_name"] || entity["object_id_base"] || entity["entity_id"]
end

entries = include_entities.map do |entity_id|
  entity = entity_by_id[entity_id]
  underlying_entity_id = template_underlying_by_entity_id[entity_id]
  underlying_entity = entity_by_id[underlying_entity_id]

  homekit_name = entity_config.dig(entity_id, "name") || display_name(entity) || entity_id
  area_id = entity_area_id(entity, device_by_id) || entity_area_id(underlying_entity, device_by_id)
  area = area_id && area_by_id[area_id]
  target_room = room_overrides[homekit_name] || area&.dig("name")
  confidence = area ? "high" : "missing_room"
  confidence = "override" if room_overrides.key?(homekit_name)
  aliases = [
    display_name(entity),
    entity&.dig("original_name"),
    entity&.dig("object_id_base"),
    underlying_entity && display_name(underlying_entity),
    underlying_entity&.dig("original_name"),
    underlying_entity&.dig("object_id_base")
  ].compact.uniq - [homekit_name]

  {
    "entity_id" => entity_id,
    "homekit_name" => homekit_name,
    "room" => target_room,
    "area_id" => area_id,
    "domain" => entity_id.split(".", 2).first,
    "underlying_entity_id" => underlying_entity_id,
    "aliases" => aliases,
    "confidence" => confidence
  }
end

payload = {
  "schema_version" => 1,
  "generated_at" => Time.now.iso8601,
  "source" => {
    "generator" => "home-assistant-yaml",
    "bridge_name" => bridge["name"],
    "bridge_port" => bridge["port"],
    "homeassistant_bridge_name" => bridge["name"],
    "homeassistant_bridge_port" => bridge["port"],
    "include_count" => include_entities.length
  },
  "entries" => entries
}

File.write(output, JSON.pretty_generate(payload) + "\n")
puts "Wrote #{entries.length} entries to #{output}"
