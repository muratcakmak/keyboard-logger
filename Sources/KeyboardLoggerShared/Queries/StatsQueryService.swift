import Foundation
import GRDB

public struct ShortcutStat: Sendable {
    public let combo: String
    public let count: Int
}

public struct KeyStat: Sendable {
    public let key: String
    public let count: Int
}

public struct DailyTrend: Sendable {
    public let day: String
    public let count: Int
}

public struct AppSummary: Sendable {
    public let appName: String
    public let bundleID: String
    public let shortcuts: Int
    public let keystrokes: Int
}

public struct StatsQueryService: Sendable {
    private let db: DatabaseManager

    public init(db: DatabaseManager) {
        self.db = db
    }

    public func topShortcuts(from: Date, to: Date, app: String?, limit: Int = 20) throws -> [ShortcutStat] {
        try db.dbWriter.read { db in
            var sql = """
                SELECT combo, COUNT(*) as cnt
                FROM shortcutEvents
                WHERE timestamp >= ? AND timestamp <= ?
                """
            var args: [DatabaseValueConvertible] = [from.timeIntervalSince1970, to.timeIntervalSince1970]

            if let app = app {
                sql += " AND (appBundleID = ? OR appName = ?)"
                args.append(app)
                args.append(app)
            }

            sql += " GROUP BY combo ORDER BY cnt DESC LIMIT ?"
            args.append(limit)

            return try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args)).map {
                ShortcutStat(combo: $0["combo"], count: $0["cnt"])
            }
        }
    }

    public func keyCounts(from: Date, to: Date, app: String?, limit: Int = 20) throws -> [KeyStat] {
        try db.dbWriter.read { db in
            let (startDay, endDay) = dayStrings(from: from, to: to)

            var sql = """
                SELECT key, SUM(count) as total
                FROM keyCounts
                WHERE day >= ? AND day <= ?
                """
            var args: [DatabaseValueConvertible] = [startDay, endDay]

            if let app = app {
                sql += " AND appBundleID = ?"
                args.append(app)
            }

            sql += " GROUP BY key ORDER BY total DESC LIMIT ?"
            args.append(limit)

            return try Row.fetchAll(db, sql: sql, arguments: StatementArguments(args)).map {
                KeyStat(key: $0["key"], count: $0["total"])
            }
        }
    }

    public func dailyShortcutTrend(days: Int = 7) throws -> [DailyTrend] {
        try db.dbWriter.read { db in
            let since = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

            let rows = try Row.fetchAll(db, sql: """
                SELECT date(timestamp, 'unixepoch', 'localtime') as day, COUNT(*) as cnt
                FROM shortcutEvents
                WHERE timestamp >= ?
                GROUP BY day
                ORDER BY day ASC
                """, arguments: [since.timeIntervalSince1970])

            return rows.map {
                DailyTrend(day: $0["day"], count: $0["cnt"])
            }
        }
    }

    public func perAppSummary(from: Date, to: Date) throws -> [AppSummary] {
        try db.dbWriter.read { db in
            let (startDay, endDay) = dayStrings(from: from, to: to)
            let fromTS = from.timeIntervalSince1970
            let toTS = to.timeIntervalSince1970

            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    s.appName,
                    s.appBundleID as bundleID,
                    s.shortcutCount as shortcuts,
                    COALESCE(k.keystrokeCount, 0) as keystrokes
                FROM (
                    SELECT appName, appBundleID, COUNT(*) as shortcutCount
                    FROM shortcutEvents
                    WHERE timestamp >= ? AND timestamp <= ?
                    GROUP BY appBundleID
                ) s
                LEFT JOIN (
                    SELECT appBundleID, SUM(count) as keystrokeCount
                    FROM keyCounts
                    WHERE day >= ? AND day <= ?
                    GROUP BY appBundleID
                ) k ON s.appBundleID = k.appBundleID
                ORDER BY shortcuts DESC
                """, arguments: [fromTS, toTS, startDay, endDay])

            return rows.map {
                AppSummary(
                    appName: $0["appName"],
                    bundleID: $0["bundleID"],
                    shortcuts: $0["shortcuts"],
                    keystrokes: $0["keystrokes"]
                )
            }
        }
    }

    public func knownApps() throws -> [(bundleID: String, appName: String)] {
        try db.dbWriter.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT DISTINCT appBundleID, appName
                FROM shortcutEvents
                ORDER BY appName ASC
                """)
            return rows.map { ($0["appBundleID"], $0["appName"]) }
        }
    }

    public func totalShortcutsToday() throws -> Int {
        try db.dbWriter.read { db in
            let startOfDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
            let row = try Row.fetchOne(db, sql: """
                SELECT COUNT(*) as cnt FROM shortcutEvents WHERE timestamp >= ?
                """, arguments: [startOfDay])
            return row?["cnt"] ?? 0
        }
    }

    public func totalKeystrokesToday() throws -> Int {
        try db.dbWriter.read { db in
            let day = AppConstants.currentDay
            let row = try Row.fetchOne(db, sql: """
                SELECT COALESCE(SUM(count), 0) as total FROM keyCounts WHERE day = ?
                """, arguments: [day])
            return row?["total"] ?? 0
        }
    }

    private func dayStrings(from: Date, to: Date) -> (String, String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return (formatter.string(from: from), formatter.string(from: to))
    }
}
