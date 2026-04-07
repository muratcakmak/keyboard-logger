import ArgumentParser
import Foundation
import KeyboardLoggerShared
import GRDB

struct Seed: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Insert sample data for testing (7 days of realistic usage)"
    )

    @Flag(name: .long, help: "Clear existing data before seeding")
    var clear: Bool = false

    func run() throws {
        let db = try DatabaseManager()

        if clear {
            try db.dbWriter.write { db in
                try db.execute(sql: "DELETE FROM shortcutEvents")
                try db.execute(sql: "DELETE FROM keyCounts")
            }
            print("Cleared existing data.")
        }

        let apps: [(id: String, name: String)] = [
            ("com.apple.Safari", "Safari"),
            ("com.microsoft.VSCode", "Visual Studio Code"),
            ("com.apple.Terminal", "Terminal"),
            ("com.tinyspeck.slackmacgap", "Slack"),
            ("com.apple.finder", "Finder"),
        ]

        let shortcuts: [(combo: String, weight: Int)] = [
            ("cmd+c", 40), ("cmd+v", 35), ("cmd+z", 25), ("cmd+s", 30),
            ("cmd+t", 20), ("cmd+w", 18), ("cmd+a", 15), ("cmd+f", 12),
            ("cmd+shift+4", 8), ("cmd+space", 22), ("cmd+tab", 28),
            ("cmd+shift+z", 10), ("cmd+l", 9), ("cmd+n", 7),
            ("cmd+q", 6), ("ctrl+c", 14), ("cmd+shift+3", 5),
            ("cmd+b", 4), ("cmd+i", 3), ("cmd+k", 6),
            ("cmd+shift+t", 5), ("cmd+p", 8), ("cmd+r", 11),
            ("alt+tab", 15), ("cmd+backspace", 7),
        ]

        let keys: [(key: String, weight: Int)] = [
            ("space", 200), ("e", 130), ("t", 120), ("a", 110),
            ("o", 100), ("return", 90), ("n", 85), ("s", 80),
            ("i", 75), ("r", 70), ("h", 65), ("l", 55),
            ("d", 50), ("backspace", 45), ("c", 40), ("u", 35),
            ("m", 30), ("f", 28), ("p", 25), ("g", 20),
        ]

        let calendar = Calendar.current
        let now = Date()

        try db.dbWriter.write { db in
            // Insert shortcuts across 7 days
            for dayOffset in 0..<7 {
                let day = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let isWeekend = calendar.isDateInWeekend(day)
                let dayMultiplier = isWeekend ? 0.4 : 1.0

                for (combo, weight) in shortcuts {
                    let count = max(1, Int(Double(weight) * dayMultiplier * Double.random(in: 0.5...1.5)))
                    let app = apps.randomElement()!

                    for _ in 0..<count {
                        let hourOffset = Int.random(in: 8...22)
                        let minuteOffset = Int.random(in: 0...59)
                        let ts = calendar.date(bySettingHour: hourOffset, minute: minuteOffset, second: Int.random(in: 0...59), of: day)!

                        var event = ShortcutEvent(
                            combo: combo,
                            timestamp: ts.timeIntervalSince1970,
                            appBundleID: app.id,
                            appName: app.name
                        )
                        try event.insert(db)
                    }
                }
            }

            // Insert key counts across 7 days
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")

            for dayOffset in 0..<7 {
                let day = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let dayStr = formatter.string(from: day)
                let isWeekend = calendar.isDateInWeekend(day)
                let dayMultiplier = isWeekend ? 0.4 : 1.0

                for (key, weight) in keys {
                    for app in apps {
                        let count = max(1, Int(Double(weight) * dayMultiplier * Double.random(in: 0.3...1.2) / Double(apps.count)))
                        try db.execute(
                            sql: """
                                INSERT INTO keyCounts (key, day, appBundleID, count)
                                VALUES (?, ?, ?, ?)
                                ON CONFLICT (key, day, appBundleID)
                                DO UPDATE SET count = count + excluded.count
                                """,
                            arguments: [key, dayStr, app.id, count]
                        )
                    }
                }
            }
        }

        // Print summary
        let shortcutCount = try db.dbWriter.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM shortcutEvents") ?? 0
        }
        let keyCountRows = try db.dbWriter.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM keyCounts") ?? 0
        }
        print("Seeded \(shortcutCount) shortcut events and \(keyCountRows) key count rows across 7 days.")
    }
}
