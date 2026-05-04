#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  HA_SSH_HOST=homeassistant.local ./scripts/export_from_ha_ssh.sh [output.json]

Optional environment variables:
  HA_SSH_PORT        SSH port, default 22
  HA_SSH_USER        SSH user, default root
  HA_CONFIG_ROOT     HA config root on host, default /mnt/data/supervisor/homeassistant
  HA_BRIDGE_NAME     Optional HomeKit bridge name to export
  ROOM_OVERRIDES     Optional JSON accessory-name -> room overrides

The script reads Home Assistant HomeKit YAML and HA registries over SSH,
then writes a local room-map JSON suitable for Home Bridge Organizer.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$ROOT_DIR/room_map.json}"
HA_SSH_HOST="${HA_SSH_HOST:?Set HA_SSH_HOST, for example HA_SSH_HOST=homeassistant.local}"
HA_SSH_PORT="${HA_SSH_PORT:-22}"
HA_SSH_USER="${HA_SSH_USER:-root}"
HA_CONFIG_ROOT="${HA_CONFIG_ROOT:-/mnt/data/supervisor/homeassistant}"
TMP_DIR="$(mktemp -d /tmp/home-bridge-organizer.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

ssh -p "$HA_SSH_PORT" "$HA_SSH_USER@$HA_SSH_HOST" \
  "cd '$HA_CONFIG_ROOT' && tar cf - packages/homekit_bridge.yaml packages/homekit_template_lights.yaml .storage/core.area_registry .storage/core.device_registry .storage/core.entity_registry 2>/dev/null" \
  | tar xf - -C "$TMP_DIR"

ARGS=(--ha-config "$TMP_DIR" --output "$OUTPUT")
if [[ -n "${HA_BRIDGE_NAME:-}" ]]; then
  ARGS+=(--bridge-name "$HA_BRIDGE_NAME")
fi
if [[ -n "${ROOM_OVERRIDES:-}" ]]; then
  ARGS+=(--overrides "$ROOM_OVERRIDES")
fi

"$ROOT_DIR/scripts/export_homekit_room_map.rb" "${ARGS[@]}"
