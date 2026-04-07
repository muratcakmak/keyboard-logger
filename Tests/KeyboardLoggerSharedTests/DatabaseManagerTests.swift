import Foundation
import Testing
import GRDB
@testable import KeyboardLoggerShared

private func makeTestDB() throws -> DatabaseManager {
    let queue = try DatabaseQueue()
    return try DatabaseManager(queue: queue)
}

@Test func databaseCreatesTablesOnInit() throws {
    let db = try makeTestDB()

    try db.dbWriter.read { db in
        let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        #expect(tables.contains("shortcutEvents"))
        #expect(tables.contains("keyCounts"))
    }
}

@Test func insertAndQueryShortcutEvent() throws {
    let db = try makeTestDB()

    try db.dbWriter.write { db in
        var event = ShortcutEvent(
            combo: "cmd+c",
            timestamp: Date().timeIntervalSince1970,
            appBundleID: "com.apple.Safari",
            appName: "Safari"
        )
        try event.insert(db)
    }

    let service = StatsQueryService(db: db)
    let stats = try service.topShortcuts(from: .distantPast, to: .distantFuture, app: nil, limit: 10)
    #expect(stats.count == 1)
    #expect(stats.first?.combo == "cmd+c")
    #expect(stats.first?.count == 1)
}

@Test func keyCountUpsert() throws {
    let db = try makeTestDB()
    let day = "2026-04-05"

    try db.dbWriter.write { db in
        try db.execute(
            sql: """
                INSERT INTO keyCounts (key, day, appBundleID, count) VALUES (?, ?, ?, ?)
                ON CONFLICT (key, day, appBundleID) DO UPDATE SET count = count + excluded.count
                """,
            arguments: ["a", day, "com.test", 5]
        )
        try db.execute(
            sql: """
                INSERT INTO keyCounts (key, day, appBundleID, count) VALUES (?, ?, ?, ?)
                ON CONFLICT (key, day, appBundleID) DO UPDATE SET count = count + excluded.count
                """,
            arguments: ["a", day, "com.test", 3]
        )
    }

    try db.dbWriter.read { db in
        let row = try Row.fetchOne(db, sql: "SELECT count FROM keyCounts WHERE key = ? AND day = ?", arguments: ["a", day])
        #expect(row?["count"] as Int? == 8)
    }
}
