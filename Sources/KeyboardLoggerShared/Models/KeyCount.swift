import Foundation
import GRDB

public struct KeyCount: Codable, Identifiable, FetchableRecord, PersistableRecord, Sendable {
    public var id: Int64?
    public var key: String
    public var day: String
    public var appBundleID: String
    public var count: Int

    public static let databaseTableName = "keyCounts"

    public init(key: String, day: String, appBundleID: String, count: Int) {
        self.key = key
        self.day = day
        self.appBundleID = appBundleID
        self.count = count
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
