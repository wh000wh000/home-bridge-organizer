import Foundation
import HomeKit

struct RoomMapPayload: Decodable {
    struct Source: Decodable {
        let bridgeName: String?
        let bridgePort: Int?
        let generator: String?

        enum CodingKeys: String, CodingKey {
            case bridgeName = "bridge_name"
            case bridgePort = "bridge_port"
            case generator
            case homeAssistantBridgeName = "homeassistant_bridge_name"
            case homeAssistantBridgePort = "homeassistant_bridge_port"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            bridgeName = try container.decodeIfPresent(String.self, forKey: .bridgeName)
                ?? container.decodeIfPresent(String.self, forKey: .homeAssistantBridgeName)
            bridgePort = try container.decodeIfPresent(Int.self, forKey: .bridgePort)
                ?? container.decodeIfPresent(Int.self, forKey: .homeAssistantBridgePort)
            generator = try container.decodeIfPresent(String.self, forKey: .generator)
        }
    }

    let schemaVersion: Int
    let generatedAt: String
    let source: Source
    let entries: [RoomMapEntry]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case generatedAt = "generated_at"
        case source
        case entries
    }
}

struct RoomMapEntry: Decodable, Identifiable {
    let entityID: String?
    let homeKitName: String
    let room: String?
    let areaID: String?
    let domain: String
    let underlyingEntityID: String?
    let aliases: [String]
    let confidence: String

    var id: String { entityID ?? homeKitName }

    enum CodingKeys: String, CodingKey {
        case entityID = "entity_id"
        case homeKitName = "homekit_name"
        case accessoryName = "accessory_name"
        case room
        case areaID = "area_id"
        case domain
        case underlyingEntityID = "underlying_entity_id"
        case aliases
        case confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entityID = try container.decodeIfPresent(String.self, forKey: .entityID)
        homeKitName = try container.decodeIfPresent(String.self, forKey: .homeKitName)
            ?? container.decode(String.self, forKey: .accessoryName)
        room = try container.decodeIfPresent(String.self, forKey: .room)
        areaID = try container.decodeIfPresent(String.self, forKey: .areaID)
        domain = try container.decodeIfPresent(String.self, forKey: .domain) ?? "manual"
        underlyingEntityID = try container.decodeIfPresent(String.self, forKey: .underlyingEntityID)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        confidence = try container.decodeIfPresent(String.self, forKey: .confidence) ?? "manual"
    }
}

struct BridgeCandidate: Identifiable, Hashable {
    let id: UUID
    let name: String
    let accessory: HMAccessory
    let bridgedCount: Int

    static func == (lhs: BridgeCandidate, rhs: BridgeCandidate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum PlanStatus: Equatable {
    case already
    case ready
    case missingTarget
    case unmatched
    case applying
    case success
    case failed(String)

    var title: String {
        switch self {
        case .already: return "已在目标房间"
        case .ready: return "待移动"
        case .missingTarget: return "缺目标房间"
        case .unmatched: return "未匹配"
        case .applying: return "处理中"
        case .success: return "已完成"
        case .failed: return "失败"
        }
    }

    var detail: String? {
        if case let .failed(message) = self {
            return message
        }
        return nil
    }
}

struct RoomPlan: Identifiable {
    let id: UUID
    let accessory: HMAccessory
    let accessoryName: String
    let entityID: String?
    let currentRoom: String
    let targetRoom: String?
    let matchKind: String
    var selected: Bool
    var status: PlanStatus
}
