import ArgumentParser
import Foundation
import KeyboardLoggerShared

@main
struct KeyboardLoggerCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "keyboard-logger",
        abstract: "Query your keyboard shortcut usage stats",
        subcommands: [Stats.self, Apps.self, Export.self, Seed.self]
    )
}

struct Stats: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show shortcut and keystroke statistics"
    )

    @Option(name: .long, help: "Time range: today, week, month, all")
    var range: String = "today"

    @Option(name: .long, help: "Filter by app name or bundle ID")
    var app: String?

    @Option(name: .long, help: "Number of results to show")
    var limit: Int = 20

    @Flag(name: .long, help: "Show plain key counts instead of shortcuts")
    var keys: Bool = false

    func run() throws {
        let db = try DatabaseManager()
        let service = StatsQueryService(db: db)
        let (from, to) = AppConstants.dateRange(for: range)

        if keys {
            let counts = try service.keyCounts(from: from, to: to, app: app, limit: limit)
            if counts.isEmpty {
                print("No keystroke data for range: \(range)")
                return
            }
            printHeader("Key Counts (\(range))")
            let maxCount = counts.first?.count ?? 1
            for item in counts {
                let bar = String(repeating: "█", count: max(1, item.count * 30 / maxCount))
                print(String(format: "  %-12s %6d  %@", (item.key as NSString).utf8String!, item.count, bar))
            }
        } else {
            let shortcuts = try service.topShortcuts(from: from, to: to, app: app, limit: limit)
            if shortcuts.isEmpty {
                print("No shortcut data for range: \(range)")
                return
            }
            printHeader("Top Shortcuts (\(range))")
            let maxCount = shortcuts.first?.count ?? 1
            for item in shortcuts {
                let bar = String(repeating: "█", count: max(1, item.count * 30 / maxCount))
                print(String(format: "  %-20s %6d  %@", (item.combo as NSString).utf8String!, item.count, bar))
            }
        }

        print("")
        let totalShortcuts = try service.totalShortcutsToday()
        let totalKeys = try service.totalKeystrokesToday()
        print("Today: \(totalShortcuts) shortcuts, \(totalKeys) keystrokes")
    }
}

struct Apps: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List tracked applications"
    )

    func run() throws {
        let db = try DatabaseManager()
        let service = StatsQueryService(db: db)
        let apps = try service.knownApps()

        if apps.isEmpty {
            print("No apps tracked yet. Start the KeyboardLogger app first.")
            return
        }

        printHeader("Tracked Applications")
        for app in apps {
            print("  \(app.appName) (\(app.bundleID))")
        }
    }
}

struct Export: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Export data as CSV or JSON"
    )

    @Option(name: .long, help: "Output format: csv, json")
    var format: String = "csv"

    @Option(name: .long, help: "Time range: today, week, month, all")
    var range: String = "all"

    @Option(name: .long, help: "Filter by app name or bundle ID")
    var app: String?

    func run() throws {
        let db = try DatabaseManager()
        let service = StatsQueryService(db: db)
        let (from, to) = AppConstants.dateRange(for: range)

        let shortcuts = try service.topShortcuts(from: from, to: to, app: app, limit: 10000)

        switch format {
        case "json":
            let entries = shortcuts.map { ["combo": $0.combo, "count": "\($0.count)"] }
            let data = try JSONSerialization.data(withJSONObject: entries, options: .prettyPrinted)
            print(String(data: data, encoding: .utf8)!)

        default: // csv
            print("combo,count")
            for item in shortcuts {
                print("\"\(item.combo)\",\(item.count)")
            }
        }
    }
}

private func printHeader(_ title: String) {
    print("\n  \(title)")
    print("  " + String(repeating: "─", count: 40))
}
