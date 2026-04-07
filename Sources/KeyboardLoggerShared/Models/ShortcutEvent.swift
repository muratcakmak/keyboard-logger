import Foundation
import GRDB

public struct ShortcutEvent: Codable, Identifiable, FetchableRecord, PersistableRecord, Sendable {
    public var id: Int64?
    public var combo: String
    public var timestamp: Double
    public var appBundleID: String
    public var appName: String

    public static let databaseTableName = "shortcutEvents"

    public init(combo: String, timestamp: Double, appBundleID: String, appName: String) {
        self.combo = combo
        self.timestamp = timestamp
        self.appBundleID = appBundleID
        self.appName = appName
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
