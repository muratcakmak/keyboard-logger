import Foundation
import AppKit
import os.log
import KeyboardLoggerShared

private let log = Logger(subsystem: "com.keyboardlogger.app", category: "AppState")

final class AppState: ObservableObject {
    @Published var isAccessibilityGranted: Bool = false
    @Published var isCapturing: Bool = false
    @Published var databaseManager: DatabaseManager?

    private var eventTapManager: EventTapManager?
    private var eventBuffer: EventBuffer?
    private var appResolver: FrontmostAppResolver?
    private var notificationService: NotificationService?
    private var permissionTimer: Timer?

    func bootstrap() {
        log.warning("bootstrap started")
        do {
            let db = try DatabaseManager()
            databaseManager = db
            log.warning("Database initialized")

            let buffer = EventBuffer(db: db)
            eventBuffer = buffer

            let resolver = FrontmostAppResolver()
            appResolver = resolver
            resolver.start()

            eventTapManager = EventTapManager(buffer: buffer, appResolver: resolver)

            let notifications = NotificationService(db: db)
            notificationService = notifications
            notifications.start()

            let trusted = PermissionChecker.isTrusted
            log.warning("AXIsProcessTrusted = \(trusted)")
            isAccessibilityGranted = trusted

            if trusted {
                startCapture()
            } else {
                startPermissionPolling()
            }
        } catch {
            log.error("Failed to initialize: \(error.localizedDescription)")
        }
    }

    func startCapture() {
        guard !isCapturing else { return }
        do {
            try eventTapManager?.start()
            Task { await eventBuffer?.startPeriodicFlush() }
            isCapturing = true
            log.warning("Keyboard logging started")
        } catch {
            log.error("Failed to start event tap: \(error)")
        }
    }

    func shutdown() {
        permissionTimer?.invalidate()
        eventTapManager?.stop()
        appResolver?.stop()
        notificationService?.stop()
        if let buffer = eventBuffer {
            Task { try? await buffer.flush() }
        }
    }

    private func startPermissionPolling() {
        log.warning("Starting permission polling")
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let trusted = PermissionChecker.isTrusted
            DispatchQueue.main.async {
                self.isAccessibilityGranted = trusted
                if trusted {
                    log.warning("Permission granted, starting capture")
                    timer.invalidate()
                    self.permissionTimer = nil
                    self.startCapture()
                }
            }
        }
    }
}
