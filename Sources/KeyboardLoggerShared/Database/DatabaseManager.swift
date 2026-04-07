import Foundation
import GRDB

public final class DatabaseManager: Sendable {
    public let dbWriter: any DatabaseWriter

    public init() throws {
        let dirURL = AppConstants.databaseDirectoryURL
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

        let dbPath = AppConstants.databaseURL.path
        let pool = try DatabasePool(path: dbPath)
        dbWriter = pool
        try AppMigrations.migrator.migrate(pool)
    }

    /// For testing with in-memory database
    public init(queue: DatabaseQueue) throws {
        dbWriter = queue
        try AppMigrations.migrator.migrate(queue)
    }
}
