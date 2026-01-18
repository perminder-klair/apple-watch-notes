import SwiftUI

@main
struct WatchNotesIOSApp: App {
    @StateObject private var connectivityService = WatchConnectivityService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityService)
        }
    }
}
