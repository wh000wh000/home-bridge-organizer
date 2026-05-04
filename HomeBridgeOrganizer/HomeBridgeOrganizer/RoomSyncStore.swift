import Foundation
import HomeKit

final class RoomSyncStore: NSObject, ObservableObject, HMHomeManagerDelegate {
    @Published var authorizationText = "等待 HomeKit 授权"
    @Published var homes: [HMHome] = []
    @Published var selectedHomeID: UUID?
    @Published var bridges: [BridgeCandidate] = []
    @Published var selectedBridgeID: UUID?
    @Published var plans: [RoomPlan] = []
    @Published var mapping: RoomMapPayload?
    @Published var mappingName = "未载入映射"
    @Published var lastMessage = ""
    @Published var showOnlyActionable = false
    @Published var isApplying = false

    private var manager: HMHomeManager?

    override init() {
        super.init()
        loadBundledExampleIfPresent()
        reloadHomeKit()
    }

    func reloadHomeKit() {
        plans = []
        bridges = []
        selectedBridgeID = nil
        lastMessage = "正在读取 Apple Home"
        let manager = HMHomeManager()
        manager.delegate = self
        self.manager = manager
        updateAuthorizationText(manager.authorizationStatus)
    }

    func loadBundledExampleIfPresent() {
        guard let url = Bundle.main.url(forResource: "example_room_map", withExtension: "json") else {
            lastMessage = "请先导入房间映射 JSON"
            return
        }

        loadMapping(from: url, displayName: "示例映射")
    }

    func loadMapping(from url: URL, displayName: String? = nil) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            mapping = try JSONDecoder().decode(RoomMapPayload.self, from: data)
            mappingName = displayName ?? url.lastPathComponent
            lastMessage = "已载入映射：\(mappingName)"
            rebuildBridgeList()
        } catch {
            lastMessage = "映射文件读取失败：\(error.localizedDescription)"
        }
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async {
            self.homes = manager.homes.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            if self.selectedHomeID == nil {
                self.selectedHomeID = manager.homes.first?.uniqueIdentifier
            }
            self.updateAuthorizationText(manager.authorizationStatus)
            self.rebuildBridgeList()
        }
    }

    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        DispatchQueue.main.async {
            self.updateAuthorizationText(status)
        }
    }

    func selectHome(_ homeID: UUID?) {
        selectedHomeID = homeID
        rebuildBridgeList()
    }

    func selectBridge(_ bridgeID: UUID?) {
        selectedBridgeID = bridgeID
        rebuildPlan()
    }

    func togglePlan(_ id: UUID, selected: Bool) {
        guard let index = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[index].selected = selected
    }

    func selectAllActionable(_ selected: Bool) {
        for index in plans.indices {
            if plans[index].status == .ready {
                plans[index].selected = selected
            }
        }
    }

    func applySelectedPlans() {
        guard !isApplying else { return }
        guard let home = selectedHome else {
            lastMessage = "没有选中的家庭"
            return
        }

        let selectedIDs = plans
            .filter { $0.selected && $0.status == .ready && $0.targetRoom != nil }
            .map(\.id)

        guard !selectedIDs.isEmpty else {
            lastMessage = "没有可应用的选中项"
            return
        }

        isApplying = true
        lastMessage = "准备应用 \(selectedIDs.count) 个房间变更"
        let neededRooms = Array(Set(selectedIDs.compactMap { id in
            plans.first(where: { $0.id == id })?.targetRoom
        })).sorted()

        createMissingRooms(neededRooms, in: home) { [weak self] roomCache in
            self?.assignPlans(selectedIDs, index: 0, roomCache: roomCache, home: home)
        }
    }

    var selectedHome: HMHome? {
        homes.first { $0.uniqueIdentifier == selectedHomeID }
    }

    var selectedBridge: BridgeCandidate? {
        bridges.first { $0.id == selectedBridgeID }
    }

    var visiblePlans: [RoomPlan] {
        if showOnlyActionable {
            return plans.filter {
                switch $0.status {
                case .ready, .applying, .failed:
                    return true
                case .already, .missingTarget, .unmatched, .success:
                    return false
                }
            }
        }
        return plans
    }

    var summaryText: String {
        let matched = plans.filter { $0.entityID != nil }.count
        let ready = plans.filter { $0.status == .ready }.count
        let already = plans.filter { $0.status == .already }.count
        let unmatched = plans.filter { $0.status == .unmatched }.count
        guard let mapping else {
            return "未载入映射"
        }
        return "\(mappingName) · 映射 \(mapping.entries.count) 项 · 匹配 \(matched) 项 · 待移动 \(ready) 项 · 已正确 \(already) 项 · 未匹配 \(unmatched) 项"
    }

    private func rebuildBridgeList() {
        guard let home = selectedHome else {
            bridges = []
            plans = []
            return
        }

        let candidates = home.accessories
            .filter { !($0.uniqueIdentifiersForBridgedAccessories ?? []).isEmpty || !$0.bridgedAccessories.isEmpty }
            .map { accessory in
                BridgeCandidate(
                    id: accessory.uniqueIdentifier,
                    name: accessory.name,
                    accessory: accessory,
                    bridgedCount: max(accessory.bridgedAccessories.count, accessory.uniqueIdentifiersForBridgedAccessories?.count ?? 0)
                )
            }
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

        bridges = candidates

        if let expectedName = mapping?.source.bridgeName,
           let expected = candidates.first(where: { $0.name == expectedName }) {
            selectedBridgeID = expected.id
        } else if selectedBridgeID == nil || !candidates.contains(where: { $0.id == selectedBridgeID }) {
            selectedBridgeID = candidates.first?.id
        }

        rebuildPlan()
    }

    private func rebuildPlan() {
        guard let bridge = selectedBridge else {
            plans = []
            lastMessage = "没有找到 HomeKit 桥"
            return
        }

        let accessories = bridgedAccessories(for: bridge.accessory)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        var nextPlans: [RoomPlan] = []
        for accessory in accessories {
            let match = matchEntry(for: accessory.name)
            let targetRoom = match.entry?.room
            let currentRoom = accessory.room?.name ?? "未分配"
            let status: PlanStatus
            let selected: Bool

            if match.entry == nil {
                status = .unmatched
                selected = false
            } else if targetRoom == nil || targetRoom?.isEmpty == true {
                status = .missingTarget
                selected = false
            } else if currentRoom == targetRoom {
                status = .already
                selected = false
            } else {
                status = .ready
                selected = true
            }

            nextPlans.append(RoomPlan(
                id: accessory.uniqueIdentifier,
                accessory: accessory,
                accessoryName: accessory.name,
                entityID: match.entry?.entityID ?? match.entry?.homeKitName,
                currentRoom: currentRoom,
                targetRoom: targetRoom,
                matchKind: match.kind,
                selected: selected,
                status: status
            ))
        }

        plans = nextPlans
        lastMessage = "已生成预览：\(summaryText)"
    }

    private func bridgedAccessories(for bridge: HMAccessory) -> [HMAccessory] {
        if !bridge.bridgedAccessories.isEmpty {
            return bridge.bridgedAccessories
        }

        guard let home = selectedHome else { return [] }
        let bridgedIDs = Set(bridge.uniqueIdentifiersForBridgedAccessories ?? [])
        return home.accessories.filter { bridgedIDs.contains($0.uniqueIdentifier) || $0.isBridged }
    }

    private func matchEntry(for accessoryName: String) -> (entry: RoomMapEntry?, kind: String) {
        guard let entries = mapping?.entries else { return (nil, "无映射") }
        let normalizedName = normalize(accessoryName)

        let exact = entries.filter { normalize($0.homeKitName) == normalizedName }
        if exact.count == 1 {
            return (exact[0], "名称")
        }

        let alias = entries.filter { entry in
            entry.aliases.contains { normalize($0) == normalizedName }
        }
        if alias.count == 1 {
            return (alias[0], "别名")
        }

        return (nil, exact.count > 1 || alias.count > 1 ? "重名" : "未匹配")
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func updateAuthorizationText(_ status: HMHomeManagerAuthorizationStatus) {
        if status.contains(.authorized) {
            authorizationText = "HomeKit 已授权"
        } else if status.contains(.restricted) {
            authorizationText = "HomeKit 受限"
        } else {
            authorizationText = "等待 HomeKit 授权"
        }
    }

    private func createMissingRooms(_ roomNames: [String], in home: HMHome, completion: @escaping ([String: HMRoom]) -> Void) {
        var roomCache = Dictionary(uniqueKeysWithValues: home.rooms.map { ($0.name, $0) })
        let missing = roomNames.filter { roomCache[$0] == nil }

        func createNext(_ index: Int) {
            guard index < missing.count else {
                completion(roomCache)
                return
            }

            let roomName = missing[index]
            home.addRoom(withName: roomName) { room, error in
                DispatchQueue.main.async {
                    if let room {
                        roomCache[roomName] = room
                    } else if let error {
                        self.lastMessage = "创建房间 \(roomName) 失败：\(error.localizedDescription)"
                    }
                    createNext(index + 1)
                }
            }
        }

        createNext(0)
    }

    private func assignPlans(_ ids: [UUID], index: Int, roomCache: [String: HMRoom], home: HMHome) {
        guard index < ids.count else {
            isApplying = false
            lastMessage = "房间同步完成"
            return
        }

        let id = ids[index]
        guard let planIndex = plans.firstIndex(where: { $0.id == id }),
              let targetName = plans[planIndex].targetRoom,
              let room = roomCache[targetName] else {
            assignPlans(ids, index: index + 1, roomCache: roomCache, home: home)
            return
        }

        plans[planIndex].status = .applying
        home.assignAccessory(plans[planIndex].accessory, to: room) { error in
            DispatchQueue.main.async {
                if let error {
                    self.plans[planIndex].status = .failed(error.localizedDescription)
                } else {
                    self.plans[planIndex].selected = false
                    self.plans[planIndex].status = .success
                }
                self.assignPlans(ids, index: index + 1, roomCache: roomCache, home: home)
            }
        }
    }
}
