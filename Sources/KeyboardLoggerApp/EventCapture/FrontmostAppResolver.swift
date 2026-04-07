import AppKit

struct FrontmostAppInfo: Sendable {
    let bundleID: String
    let name: String

    static let unknown = FrontmostAppInfo(bundleID: "unknown", name: "Unknown")
}

/// Caches the frontmost app and updates via NSWorkspace notification
/// instead of querying on every keypress.
final class FrontmostAppResolver: @unchecked Sendable {
    private var _current: FrontmostAppInfo = .unknown
    private let lock = NSLock()

    var current: FrontmostAppInfo {
        lock.lock()
        defer { lock.unlock() }
        return _current
    }

    func start() {
        // Set initial value
        updateFromWorkspace()

        // Observe app activation changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func appDidActivate(_ notification: Notification) {
        updateFromWorkspace()
    }

    private func updateFromWorkspace() {
        let app = NSWorkspace.shared.frontmostApplication
        let info = FrontmostAppInfo(
            bundleID: app?.bundleIdentifier ?? "unknown",
            name: app?.localizedName ?? "Unknown"
        )
        lock.lock()
        _current = info
        lock.unlock()
    }
}
