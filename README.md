# Home Bridge Organizer

中文名：**家桥整理器**

Home Bridge Organizer is a small Mac Catalyst utility that moves bridged Apple Home accessories into rooms from a local, reviewable room map.

It is useful when Home Assistant, Homebridge, HOOBS, Node-RED, or another bridge exposes many accessories to Apple Home and Apple Home places them all in the default room.

## What It Does

- Reads Apple Home homes, rooms, bridges, and bridged accessories through Apple's public HomeKit API.
- Imports a local JSON room map.
- Matches accessory names and aliases.
- Shows a preview: current room -> target room.
- Applies only selected changes.
- Creates missing Apple Home rooms when needed.

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

## Safety

- Always preview before applying.
- Low-confidence or unmatched accessories are not selected automatically.
- Keep your bridge identity stable. Do not delete and recreate bridges if you want Apple Home room assignments to persist.
- For public bug reports, do not paste private room maps unless you have redacted home names, accessory names, and entity IDs.

## Release

Current planned release: `v0.1.0`.

The first public release is source-first. Signed binaries are not distributed yet because HomeKit apps require developer-team signing and user-granted HomeKit access.

## License

MIT
