import SwiftUI

@main
struct MissionControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(environment)
        }

        // Status-bar presence (ADR-0006): the app stays resident and reachable even after
        // the main window closes.
        MenuBarExtra("Mission Control", systemImage: "circle.grid.2x2.fill") {
            MenuBarContentView()
                .environmentObject(environment)
        }
        .menuBarExtraStyle(.window)
    }
}
