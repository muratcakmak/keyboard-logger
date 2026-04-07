import Foundation
import UserNotifications
import KeyboardLoggerShared

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let db: DatabaseManager
    private var timer: Timer?
    private let intervalHours: Double

    init(db: DatabaseManager, intervalHours: Double = 3.0) {
        self.db = db
        self.intervalHours = intervalHours
        super.init()
    }

    func start() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }

        let interval = intervalHours * 3600
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendStatsSummary()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sendStatsSummary() {
        let service = StatsQueryService(db: db)

        guard let shortcuts = try? service.totalShortcutsToday(),
              let keystrokes = try? service.totalKeystrokesToday() else { return }

        let (from, to) = AppConstants.dateRange(for: "today")
        let topShortcuts = (try? service.topShortcuts(from: from, to: to, app: nil, limit: 3)) ?? []

        let topList = topShortcuts.map { "\($0.combo) (\($0.count))" }.joined(separator: ", ")

        let content = UNMutableNotificationContent()
        content.title = "Keyboard Stats"
        content.body = "Today: \(shortcuts) shortcuts, \(keystrokes) keystrokes"
        if !topList.isEmpty {
            content.body += "\nTop: \(topList)"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "stats-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
