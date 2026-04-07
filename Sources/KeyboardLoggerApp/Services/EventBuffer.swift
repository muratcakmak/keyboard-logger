import Foundation
import KeyboardLoggerShared
import GRDB

actor EventBuffer {
    private var pendingShortcuts: [ShortcutEvent] = []
    private var pendingKeyCounts: [String: [String: Int]] = [:] // key -> bundleID -> delta
    private let db: DatabaseManager
    private var flushTask: Task<Void, Never>?

    /// Max events to hold before forcing a flush
    private let maxBufferSize = 50
    /// Max shortcut events to prevent unbounded growth from key repeat
    private let maxShortcutBuffer = 200

    init(db: DatabaseManager) {
        self.db = db
    }

    func append(_ event: ClassifiedEvent) {
        switch event {
        case .shortcut(let combo, let appBundleID, let appName):
            // Drop if buffer is full (key repeat spam protection)
            guard pendingShortcuts.count < maxShortcutBuffer else { return }
            pendingShortcuts.append(
                ShortcutEvent(
                    combo: combo,
                    timestamp: Date().timeIntervalSince1970,
                    appBundleID: appBundleID,
                    appName: appName
                )
            )
        case .plainKey(let key, let appBundleID):
            pendingKeyCounts[key, default: [:]][appBundleID, default: 0] += 1
        }

        if pendingShortcuts.count + totalKeyCountDelta >= maxBufferSize {
            Task { try? await flush() }
        }
    }

    func startPeriodicFlush() {
        flushTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                try? await self?.flush()
            }
        }
    }

    func stopPeriodicFlush() {
        flushTask?.cancel()
        flushTask = nil
    }

    func flush() async throws {
        let shortcuts = pendingShortcuts
        let keyCounts = pendingKeyCounts
        pendingShortcuts.removeAll(keepingCapacity: true)
        pendingKeyCounts.removeAll(keepingCapacity: true)

        guard !shortcuts.isEmpty || !keyCounts.isEmpty else { return }

        let day = AppConstants.currentDay

        try await db.dbWriter.write { db in
            for shortcut in shortcuts {
                try shortcut.insert(db)
            }

            for (key, appDeltas) in keyCounts {
                for (bundleID, delta) in appDeltas {
                    try db.execute(
                        sql: """
                            INSERT INTO keyCounts (key, day, appBundleID, count)
                            VALUES (?, ?, ?, ?)
                            ON CONFLICT (key, day, appBundleID)
                            DO UPDATE SET count = count + excluded.count
                            """,
                        arguments: [key, day, bundleID, delta]
                    )
                }
            }
        }
    }

    private var totalKeyCountDelta: Int {
        pendingKeyCounts.values.reduce(0) { $0 + $1.values.reduce(0, +) }
    }
}
