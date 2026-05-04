# Home Bridge Organizer / 家桥整理器

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

[![CI](https://github.com/wh000wh000/home-bridge-organizer/actions/workflows/ci.yml/badge.svg)](https://github.com/wh000wh000/home-bridge-organizer/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/wh000wh000/home-bridge-organizer)](https://github.com/wh000wh000/home-bridge-organizer/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](../LICENSE)
[![Platform](https://img.shields.io/badge/platform-Mac%20Catalyst-blue.svg)](../README.md)

Apple 家庭里桥接进来一堆灯、空调、窗帘，结果全都挤在默认房间？

**家桥整理器** 把“逐个点开、逐个分房间”的苦活，变成“导入映射、预览、勾选、应用”。

## 懒人起源故事

我只是想让 Siri 听懂我的智能家居。很合理。

然后 Apple 家庭说：好呀，那请你把这 47 个桥接配件一个一个分到房间里。

这就不太合理了。

所以这个工具诞生于一种非常具体的懒：有建设性的懒。如果 Home Assistant、Homebridge、HOOBS、Node-RED 或者其他系统已经知道设备在哪个房间，Apple Home 就不该让你的手指再重复教它一遍。

## 解决什么问题？

Apple Home 的房间归属保存在 Apple 家庭侧。HomeKit Bridge 可以暴露配件、名称、服务和状态，但不能可靠地把“这个配件属于厨房”这种房间信息直接写进 Apple Home。

所以你经常会遇到：

- 第一次把大量 Home Assistant 实体暴露到 Apple Home；
- 重建或重新配对 HomeKit Bridge 后，房间归类全没了；
- Homebridge / HOOBS 迁移后，一堆配件进了默认房间；
- Node-RED 或自定义桥接暴露了很多配件；
- 后续不断新增设备，每次都要手工整理。

家桥整理器处理的就是这件无聊但痛的事情：读取本地房间映射，预览将要移动的配件，只应用你选中的变更。

## 适合谁？

- 使用 Home Assistant HomeKit Bridge 暴露大量实体的人。
- 使用 Homebridge / HOOBS 并且配件很多的人。
- Apple Home 重配桥后丢失房间归类的人。
- 已经在其他系统里维护好真实房间信息的人。
- 想让 Siri 正常理解“关掉客厅灯”，但不想做几十次重复劳动的人。

## 怎么用？

1. 导出或手写一个本地 room map：配件名 -> 目标 Apple Home 房间。
2. 在 Mac 上打开 Home Bridge Organizer。
3. 导入 JSON room map。
4. 选择 Apple Home 里的桥。
5. 预览：当前房间 -> 目标房间。
6. 只应用勾选的变更。

没有云端同步，没有神秘自动化，不会突然开关你的灯。它只处理房间元数据，并且在本地完成。

## 支持场景

- Apple Home / HomeKit
- Home Assistant HomeKit Bridge
- Homebridge
- HOOBS
- Node-RED HomeKit 桥
- 手写 JSON room map

当前内置导出脚本主要支持 Home Assistant YAML HomeKit Bridge 配置。其他桥可以使用手写 JSON 格式。

## 功能

- 通过 Apple 官方 HomeKit API 读取家庭、房间、桥和桥接配件。
- 导入本地 JSON room map。
- 按配件名称和别名匹配。
- 预览：当前房间 -> 目标房间。
- 只应用选中的变更。
- 目标房间不存在时可以创建。
- 全程本地处理。

它不会控制设备开关，不上传数据，也不需要服务端。

## 要求

- macOS 和 Xcode。
- 使用 HomeKit capability 签名的 Mac Catalyst build。
- 第一次运行时授权访问 Apple Home。
- 一个 room map JSON 文件。

普通 macOS 命令行工具无法使用 HomeKit 管理 API。本项目使用 Mac Catalyst，是因为 HomeKit 管理 API 在这条路线可用。

## 构建

1. 打开 `HomeBridgeOrganizer/HomeBridgeOrganizer.xcodeproj`。
2. 选择 target `HomeBridgeOrganizer`。
3. 在 `Signing & Capabilities` 中选择你的 Development Team。
4. 确认有 `HomeKit` capability。
5. 运行目标选择 `My Mac (Mac Catalyst)`。
6. Build and run。

无签名编译检查：

```bash
xcodebuild \
  -project HomeBridgeOrganizer/HomeBridgeOrganizer.xcodeproj \
  -scheme HomeBridgeOrganizer \
  -configuration Debug \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Room Map 格式

App 导入这样的 JSON：

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

每一项也可以使用 `homekit_name` 代替 `accessory_name`。`entity_id`、`area_id`、`domain`、`underlying_entity_id`、`confidence` 是 Home Assistant 导出器使用的可选元数据。

## Home Assistant 导出

如果 Home Assistant 配置在本地：

```bash
./scripts/export_homekit_room_map.rb \
  --ha-config /path/to/homeassistant/config \
  --output room_map.json \
  --bridge-name "HA Bridge"
```

如果 Home Assistant 主机可以通过 SSH 访问：

```bash
HA_SSH_HOST=homeassistant.local \
HA_SSH_PORT=22 \
HA_SSH_USER=root \
HA_BRIDGE_NAME="HA Bridge" \
./scripts/export_from_ha_ssh.sh room_map.json
```

如果物理墙壁开关所在区域和它控制的灯实际作用区域不同，可以使用覆盖规则：

```bash
ROOM_OVERRIDES=room_overrides.json ./scripts/export_from_ha_ssh.sh room_map.json
```

参考 `room_overrides.example.json`。

## 搜索关键词

Apple Home 房间同步、HomeKit 房间整理、HomeKit Bridge 房间归类、Home Assistant HomeKit Bridge rooms、Homebridge room sync、HOOBS Apple Home rooms、Node-RED HomeKit rooms、桥接配件、Siri 房间控制、智能家居房间映射。

## 路线图

- CSV 导入。
- 回滚界面。
- 持久化 HomeKit accessory UUID 映射。
- 更好的重名处理。
- 如果分发条件成熟，提供签名版本。

## 安全提示

- 应用前一定先预览。
- 低置信度或未匹配配件默认不会自动选中。
- 保持桥身份稳定。如果希望 Apple Home 房间归类持续有效，不要反复删除和重建桥。
- 提交公开 issue 时，请先脱敏家庭名、配件名、entity_id 和其他私人信息。

## Release

当前版本：`v0.1.0`。

第一个公开版本是 source-first。暂不分发签名二进制，因为 HomeKit App 需要开发者团队签名和用户授予 HomeKit 访问权限。

## 非官方声明

Home Bridge Organizer 与 Apple、Home Assistant、Homebridge、HOOBS、Node-RED 没有关联。它使用 Apple 公开 HomeKit API。

## License

MIT
