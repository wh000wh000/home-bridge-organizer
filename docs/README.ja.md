# Home Bridge Organizer

[English](../README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

[![CI](https://github.com/wh000wh000/home-bridge-organizer/actions/workflows/ci.yml/badge.svg)](https://github.com/wh000wh000/home-bridge-organizer/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/wh000wh000/home-bridge-organizer)](https://github.com/wh000wh000/home-bridge-organizer/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](../LICENSE)
[![Platform](https://img.shields.io/badge/platform-Mac%20Catalyst-blue.svg)](../README.md)

Apple Home にブリッジ経由のアクセサリが大量に入り、全部デフォルトの部屋に入ってしまう。

**Home Bridge Organizer** は、その地味でつらい部屋分け作業を、ローカルのルームマップから「インポート、プレビュー、選択、適用」に変える Mac ツールです。

## 怠け者のための開発理由

Siri にスマートホームをちゃんと理解してほしい。そこまでは自然です。

でも Apple Home が「では、この 47 個のブリッジアクセサリを手作業で部屋に分けてください」と言ってくる。

それは少しつらい。

このアプリは、よい意味での怠け心から生まれました。Home Assistant、Homebridge、HOOBS、Node-RED、または別のシステムがすでにデバイスの部屋を知っているなら、Apple Home にもう一度手作業で教える必要はないはずです。

## 解決する問題

Apple Home の部屋割り当ては Apple Home 側に保存されます。HomeKit ブリッジはアクセサリ、名前、サービス、状態を公開できますが、「このアクセサリはキッチンにある」という部屋情報を Apple Home に確実に渡すことはできません。

そのため、次のような場面でアクセサリがデフォルトの部屋に集まりがちです。

- 大量の Home Assistant エンティティを Apple Home に公開したとき。
- HomeKit ブリッジを再作成または再ペアリングしたとき。
- Homebridge / HOOBS を移行したとき。
- Node-RED やカスタムブリッジで多くのアクセサリを公開したとき。
- スマートホーム機器を少しずつ追加しているとき。

Home Bridge Organizer は、この退屈な部分を処理します。ローカルのルームマップを読み込み、移動予定を表示し、選択した変更だけを適用します。

## 向いている人

- Home Assistant HomeKit Bridge で多くのエンティティを公開している人。
- Homebridge / HOOBS のアクセサリが多い人。
- ブリッジ再設定で Apple Home の部屋割り当てを失った人。
- 実際の部屋情報を別システムで管理している人。
- Siri に部屋を理解させたいが、手作業の整理はしたくない人。

## 使い方

1. ローカルのルームマップを用意します：アクセサリ名 -> Apple Home の部屋。
2. Mac で Home Bridge Organizer を開きます。
3. JSON ルームマップをインポートします。
4. Apple Home のブリッジを選びます。
5. 現在の部屋 -> 目標の部屋を確認します。
6. 選択した変更だけを適用します。

クラウドなし。謎の同期なし。ライトを勝手にオンオフすることもありません。部屋メタデータだけをローカルで変更します。

## 対応する場面

- Apple Home / HomeKit
- Home Assistant HomeKit Bridge
- Homebridge
- HOOBS
- Node-RED HomeKit ブリッジ
- 手動 JSON ルームマップ

内蔵エクスポーターは現在、Home Assistant の YAML HomeKit Bridge 構成を対象にしています。他のブリッジでは手動 JSON 形式を使えます。

## 機能

- Apple の公開 HomeKit API で home、room、bridge、bridged accessory を読み取ります。
- ローカル JSON ルームマップをインポートします。
- アクセサリ名と alias でマッチングします。
- 現在の部屋 -> 目標の部屋をプレビューします。
- 選択した変更だけを適用します。
- 必要に応じて Apple Home に部屋を作成します。
- すべてローカルで処理します。

デバイスの電源や状態は操作しません。データをアップロードしません。サーバーも不要です。

## 必要なもの

- macOS と Xcode。
- HomeKit capability を有効にした署名済み Mac Catalyst build。
- 初回起動時の Apple Home アクセス許可。
- room map JSON ファイル。

通常の macOS コマンドラインツールでは HomeKit 管理 API は使えません。このプロジェクトは HomeKit 管理 API が利用できる Mac Catalyst を使っています。

## ビルド

1. `HomeBridgeOrganizer/HomeBridgeOrganizer.xcodeproj` を開きます。
2. target `HomeBridgeOrganizer` を選択します。
3. `Signing & Capabilities` で Development Team を選びます。
4. `HomeKit` capability があることを確認します。
5. 実行先に `My Mac (Mac Catalyst)` を選びます。
6. Build and run。

署名なしのコンパイル確認：

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

アプリは次のような JSON を読み込みます。

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

各 entry では `accessory_name` の代わりに `homekit_name` も使えます。`entity_id`、`area_id`、`domain`、`underlying_entity_id`、`confidence` は Home Assistant エクスポーター用の任意メタデータです。

## Home Assistant Export

Home Assistant 設定がローカルにある場合：

```bash
./scripts/export_homekit_room_map.rb \
  --ha-config /path/to/homeassistant/config \
  --output room_map.json \
  --bridge-name "HA Bridge"
```

Home Assistant ホストに SSH できる場合：

```bash
HA_SSH_HOST=homeassistant.local \
HA_SSH_PORT=22 \
HA_SSH_USER=root \
HA_BRIDGE_NAME="HA Bridge" \
./scripts/export_from_ha_ssh.sh room_map.json
```

物理スイッチの場所と、実際に操作するライトの部屋が違う場合は override を使えます。

```bash
ROOM_OVERRIDES=room_overrides.json ./scripts/export_from_ha_ssh.sh room_map.json
```

`room_overrides.example.json` を参照してください。

## 検索キーワード

Apple Home room sync、HomeKit room organizer、HomeKit Bridge room assignment、Home Assistant HomeKit Bridge rooms、Homebridge room sync、HOOBS Apple Home rooms、Node-RED HomeKit rooms、bridged accessories、Siri room control、smart home room mapping。

## Roadmap

- CSV import。
- Rollback UI。
- HomeKit accessory UUID mapping の保存。
- 重複名処理の改善。
- 配布条件が整えば署名済み build。

## 安全上の注意

- 適用前に必ずプレビューしてください。
- 低信頼度または未マッチのアクセサリは自動選択されません。
- ブリッジ identity を安定させてください。部屋割り当てを維持したい場合、ブリッジを削除して再作成しないでください。
- 公開 issue に room map を貼る場合は、home 名、accessory 名、entity_id などを必ずマスクしてください。

## Release

現在のバージョン：`v0.1.0`。

最初の公開版は source-first です。HomeKit App は開発者チーム署名とユーザーの HomeKit アクセス許可が必要なため、署名済みバイナリはまだ配布していません。

## 非公式

Home Bridge Organizer は Apple、Home Assistant、Homebridge、HOOBS、Node-RED とは関係ありません。Apple の公開 HomeKit API を使用しています。

## License

MIT
