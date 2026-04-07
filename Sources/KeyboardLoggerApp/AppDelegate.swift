import AppKit

// Kept minimal — all logic lives in AppState.bootstrap()
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("[KL] App terminating")
    }
}
