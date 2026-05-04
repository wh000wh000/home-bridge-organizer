# Home Bridge Organizer

[English](README.md) | [简体中文](docs/README.zh-CN.md) | [日本語](docs/README.ja.md)

[![CI](https://github.com/wh000wh000/home-bridge-organizer/actions/workflows/ci.yml/badge.svg)](https://github.com/wh000wh000/home-bridge-organizer/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/wh000wh000/home-bridge-organizer)](https://github.com/wh000wh000/home-bridge-organizer/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Mac%20Catalyst-blue.svg)](README.md)

Chinese name: **家桥整理器**

Too many bridged accessories in Apple Home. Too little patience to drag them into rooms one by one.

**Home Bridge Organizer** turns that tiny domestic tragedy into a local, reviewable, preview-and-apply workflow.

## The Lazy Origin Story

I wanted Siri to understand my smart home. Reasonable.

Then Apple Home said: "Great. Please sort these 47 bridged accessories into rooms by hand."

Less reasonable.

So this app exists for a very specific kind of laziness: the productive kind. If Home Assistant, Homebridge, HOOBS, Node-RED, or another bridge already knows where your devices live, Apple Home should not make your thumb repeat that knowledge accessory by accessory.

## What Problem Does It Solve?

Apple Home stores room assignments on the Apple Home side. A HomeKit bridge can expose accessories, names, services, and states, but it does not reliably push "this accessory belongs in the Kitchen" into Apple Home.

That means bridged accessories often land in a default room, especially when you:

- pair a large Home Assistant HomeKit Bridge,
- rebuild or re-pair a HomeKit bridge,
- migrate a Homebridge or HOOBS setup,
- expose many Node-RED or custom bridge accessories,
- add lots of smart-home devices over time.

Home Bridge Organizer fixes the boring part: it reads a local room map, shows what would move, and applies only the changes you select.

## Best For

- Home Assistant users exposing many entities through HomeKit Bridge.
- Homebridge / HOOBS users with dozens of bridged accessories.
- Apple Home users who rebuilt a bridge and lost room assignments.
- Smart-home tinkerers who maintain room metadata elsewhere.
- Anyone who wants Siri to understand rooms without a tiny admin marathon.

## How It Works

1. Export or write a local room map: accessory name -> target Apple Home room.
2. Open Home Bridge Organizer on Mac.
3. Import the JSON room map.
4. Pick the Apple Home bridge.
5. Review current room -> target room.
6. Apply only the selected changes.

No cloud. No mystery sync. No surprise light toggles. Just room metadata, locally applied.

## Works With

- Apple Home / HomeKit
- Home Assistant HomeKit Bridge
- Homebridge
- HOOBS
- Node-RED HomeKit bridges
- Manual JSON room maps

The built-in exporter currently targets Home Assistant YAML HomeKit Bridge setups. Other bridges can use the manual JSON format.

## Features

- Reads Apple Home homes, rooms, bridges, and bridged accessories through Apple's public HomeKit API.
- Imports a local JSON room map.
- Matches accessory names and aliases.
- Shows a preview: current room -> target room.
- Applies only selected changes.
- Creates missing Apple Home rooms when needed.
- Keeps everything local.

It does not control device power/state, does not upload data, and does not require a server.

## Requirements

- macOS with Xcode.
- A signed Mac Catalyst build with the HomeKit capability enabled.
- Apple Home permission granted on first launch.
- A room map JSON file.

HomeKit is unavailable to ordinary macOS command-line tools. This project uses Mac Catalyst because HomeKit management APIs are available there.

## Build

1. Open `HomeBridgeOrganizer/HomeBridgeOrganizer.xcodeproj`.
2. Select the `HomeBridgeOrganizer` target.
3. In `Signing & Capabilities`, choose your Development Team.
4. Make sure the `HomeKit` capability is present.
5. Select `My Mac (Mac Catalyst)`.
6. Build and run.

Unsigned compile check:

```bash
xcodebuild \
  -project HomeBridgeOrganizer/HomeBridgeOrganizer.xcodeproj \
  -scheme HomeBridgeOrganizer \
  -configuration Debug \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Room Map

The app imports JSON shaped like this:

```json
{
  "schema_version": 1,
  "generated_at": "2026-05-04T00:00:00Z",
  "source": {
    "generator": "manual",
    "bridge_name": "HA Bridge"
  },
  "entries": [
    {
      "accessory_name": "Kitchen Light",
      "room": "Kitchen",
      "aliases": ["Kitchen Ceiling"]
    }
  ]
}
```

Each entry can also use `homekit_name` instead of `accessory_name`. `entity_id`, `area_id`, `domain`, `underlying_entity_id`, and `confidence` are optional metadata fields used by the Home Assistant exporter.

## Home Assistant Export

If your Home Assistant config lives locally:

```bash
./scripts/export_homekit_room_map.rb \
  --ha-config /path/to/homeassistant/config \
  --output room_map.json \
  --bridge-name "HA Bridge"
```

If your Home Assistant host is reachable over SSH:

```bash
HA_SSH_HOST=homeassistant.local \
HA_SSH_PORT=22 \
HA_SSH_USER=root \
HA_BRIDGE_NAME="HA Bridge" \
./scripts/export_from_ha_ssh.sh room_map.json
```

Optional room overrides are useful when a physical wall switch lives in one area but the light it controls belongs to another:

```bash
ROOM_OVERRIDES=room_overrides.json ./scripts/export_from_ha_ssh.sh room_map.json
```

See `room_overrides.example.json`.

## Search Keywords

Apple Home room sync, HomeKit room organizer, HomeKit Bridge room assignment, Home Assistant HomeKit Bridge rooms, Homebridge room sync, HOOBS Apple Home rooms, Node-RED HomeKit rooms, bridged accessories, Siri room control, smart home room mapping.

## Roadmap

- CSV import.
- Rollback UI.
- Persisted HomeKit accessory UUID mapping.
- Better duplicate-name handling.
- Signed release builds if distribution becomes practical.

## Safety

- Always preview before applying.
- Low-confidence or unmatched accessories are not selected automatically.
- Keep your bridge identity stable. Do not delete and recreate bridges if you want Apple Home room assignments to persist.
- For public bug reports, do not paste private room maps unless you have redacted home names, accessory names, and entity IDs.

## Release

Current release: `v0.1.0`.

The first public release is source-first. Signed binaries are not distributed yet because HomeKit apps require developer-team signing and user-granted HomeKit access.

## Not Affiliated

Home Bridge Organizer is not affiliated with Apple, Home Assistant, Homebridge, HOOBS, or Node-RED. It uses Apple's public HomeKit APIs.

## License

MIT
