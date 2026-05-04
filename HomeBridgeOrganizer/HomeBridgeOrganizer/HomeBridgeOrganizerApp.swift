import SwiftUI

@main
struct HomeBridgeOrganizerApp: App {
    @StateObject private var store = RoomSyncStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 960, minHeight: 620)
        }
    }
}
