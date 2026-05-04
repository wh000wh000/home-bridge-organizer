import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: RoomSyncStore
    @State private var isImportingMap = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            controls
            Divider()
            planList
            Divider()
            footer
        }
        .padding(16)
        .fileImporter(
            isPresented: $isImportingMap,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    store.loadMapping(from: url)
                }
            case .failure(let error):
                store.lastMessage = "导入失败：\(error.localizedDescription)"
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Home Bridge Organizer")
                    .font(.title2.weight(.semibold))
                Text(store.authorizationText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isImportingMap = true
            } label: {
                Label("导入映射", systemImage: "square.and.arrow.down")
            }

            Button {
                store.reloadHomeKit()
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
        }
        .padding(.bottom, 12)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Picker("家庭", selection: Binding(
                    get: { store.selectedHomeID },
                    set: { store.selectHome($0) }
                )) {
                    ForEach(store.homes, id: \.uniqueIdentifier) { home in
                        Text(home.name).tag(Optional(home.uniqueIdentifier))
                    }
                }
                .frame(maxWidth: 260)

                Picker("桥", selection: Binding(
                    get: { store.selectedBridgeID },
                    set: { store.selectBridge($0) }
                )) {
                    ForEach(store.bridges) { bridge in
                        Text("\(bridge.name) (\(bridge.bridgedCount))").tag(Optional(bridge.id))
                    }
                }
                .frame(maxWidth: 340)

                Spacer()

                Toggle("只看待处理", isOn: $store.showOnlyActionable)
                    .toggleStyle(.switch)

                Button {
                    store.selectAllActionable(true)
                } label: {
                    Label("全选", systemImage: "checklist.checked")
                }

                Button(role: .destructive) {
                    store.applySelectedPlans()
                } label: {
                    Label("应用选中", systemImage: "arrow.right.circle")
                }
                .disabled(store.isApplying || store.plans.allSatisfy { !$0.selected })
            }

            HStack {
                Text(store.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 12)
    }

    private var planList: some View {
        List {
            ForEach(store.visiblePlans) { plan in
                RoomPlanRow(plan: plan)
            }
        }
        .listStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text(store.lastMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.top, 10)
    }
}

private struct RoomPlanRow: View {
    @EnvironmentObject private var store: RoomSyncStore
    let plan: RoomPlan

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { plan.selected },
                set: { store.togglePlan(plan.id, selected: $0) }
            ))
            .labelsHidden()
            .disabled(plan.status != .ready)

            VStack(alignment: .leading, spacing: 3) {
                Text(plan.accessoryName)
                    .font(.body.weight(.medium))
                HStack(spacing: 8) {
                    if let entityID = plan.entityID {
                        Text(entityID)
                    } else {
                        Text(plan.matchKind)
                    }
                    Text(plan.matchKind)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(minWidth: 260, alignment: .leading)

            Text(plan.currentRoom)
                .frame(width: 130, alignment: .leading)

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            Text(plan.targetRoom ?? "未匹配")
                .frame(width: 130, alignment: .leading)

            Spacer()

            statusView
        }
        .padding(.vertical, 7)
    }

    private var statusView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(plan.status.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
            if let detail = plan.status.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 150, alignment: .trailing)
    }

    private var statusColor: Color {
        switch plan.status {
        case .already, .success:
            return .green
        case .ready:
            return .orange
        case .failed:
            return .red
        case .applying:
            return .blue
        case .missingTarget, .unmatched:
            return .secondary
        }
    }
}
