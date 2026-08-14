import AppKit
import ServiceManagement
import UserNotifications

/// Handles the app-lifecycle concerns that don't fit SwiftUI's `App`/`Scene` model
/// (ADR-0006): registering as a login item so the resident process survives across restarts,
/// and requesting notification authorization for terminal-failure alerts (ADR-0008).
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        registerAsLoginItemIfNeeded()
        requestNotificationAuthorization()
    }

    /// Keeps the resident app polling even with its window closed (ADR-0006).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func registerAsLoginItemIfNeeded() {
        do {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } catch {
            AppLog.ui.error("Failed to register login item: \(String(describing: error), privacy: .public)")
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLog.ui.error("Notification authorization failed: \(String(describing: error), privacy: .public)")
            } else {
                AppLog.ui.info("Notification authorization granted: \(granted)")
            }
        }
    }
}
