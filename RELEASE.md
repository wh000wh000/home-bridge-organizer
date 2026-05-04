# Release Notes

## v0.1.0

Home Bridge Organizer / 家桥整理器 starts as a source-first release for advanced Apple Home bridge users.

Full product pages:

- [English](README.md)
- [简体中文](docs/README.zh-CN.md)
- [日本語](docs/README.ja.md)

## Product Intro

### 中文

Apple 家庭里桥接进来一堆灯、空调、窗帘，结果全挤在默认房间？  
我很懒，懒到不想给几十个配件逐个点开、逐个分房间。于是有了 **家桥整理器**：把 Home Assistant / Homebridge / HOOBS / Node-RED 已经知道的房间信息，变成 Apple Home 里可预览、可勾选、可一键应用的房间整理流程。

适合这些场景：

- 第一次把大量桥接设备接入 Apple Home。
- 重配 HomeKit Bridge 后，Apple Home 房间归类全没了。
- 设备真实房间已经在 Home Assistant 或别的系统里维护好了。
- 你只想让 Siri 正常理解“关掉客厅灯”，不想再做 47 次重复劳动。

三步走：

1. 导出或手写一个本地 room map。
2. 在 Mac 上打开 Home Bridge Organizer。
3. 导入、预览、应用。

### English

Apple Home is great until your bridge drops 47 accessories into the default room and quietly hands you a sorting chore.

**Home Bridge Organizer** is for people who are productively lazy: if Home Assistant, Homebridge, HOOBS, or Node-RED already knows where your devices live, Apple Home should not make you re-teach it by hand.

Use it when:

- You expose many bridged accessories to Apple Home.
- You rebuild or re-pair a bridge and lose room assignments.
- Your source system already has room metadata.
- You want Siri to understand rooms without a tiny admin marathon.

Workflow:

1. Create or export a local room map.
2. Import it in Home Bridge Organizer.
3. Preview current room -> target room, then apply selected changes.

### 日本語

Apple Home にブリッジ経由のアクセサリが大量に入り、全部デフォルトの部屋に入ってしまう。  
その手作業、できればやりたくないですよね。

**Home Bridge Organizer** は、ローカルのルームマップを使って、ブリッジ配下のアクセサリを Apple Home の部屋へプレビュー付きで整理する Mac ツールです。

Highlights:

- Import a local room-map JSON.
- Preview bridged Apple Home accessory room changes.
- Apply only selected changes.
- Generate room maps from Home Assistant HomeKit Bridge YAML and registries.

Known limitations:

- No signed binary release yet.
- Users must build with Xcode and a Development Team that can enable HomeKit capability.
- Matching is name/alias based in v0.1.0.
- Rollback UI is not implemented yet.

Recommended GitHub release title:

`Home Bridge Organizer v0.1.0`
