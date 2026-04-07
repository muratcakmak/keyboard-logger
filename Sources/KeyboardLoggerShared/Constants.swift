import Foundation

public enum AppConstants {
    public static var databaseDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("KeyboardLogger", isDirectory: true)
    }

    public static var databaseURL: URL {
        databaseDirectoryURL.appendingPathComponent("keyboard-logger.sqlite")
    }

    public static var currentDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    public static func dateRange(for range: String) -> (from: Date, to: Date) {
        let now = Date()
        let calendar = Calendar.current
        let to = now

        let from: Date
        switch range {
        case "today":
            from = calendar.startOfDay(for: now)
        case "week":
            from = calendar.date(byAdding: .day, value: -7, to: now)!
        case "month":
            from = calendar.date(byAdding: .month, value: -1, to: now)!
        case "all":
            from = Date.distantPast
        default:
            from = calendar.startOfDay(for: now)
        }

        return (from: from, to: to)
    }
}
