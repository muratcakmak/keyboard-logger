import GRDB

public struct AppMigrations {
    public static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "shortcutEvents") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("combo", .text).notNull()
                t.column("timestamp", .double).notNull()
                t.column("appBundleID", .text).notNull()
                t.column("appName", .text).notNull()
            }
            try db.create(
                index: "idx_shortcutEvents_combo_ts",
                on: "shortcutEvents",
                columns: ["combo", "timestamp"]
            )
            try db.create(
                index: "idx_shortcutEvents_app_ts",
                on: "shortcutEvents",
                columns: ["appBundleID", "timestamp"]
            )
            try db.create(
                index: "idx_shortcutEvents_ts",
                on: "shortcutEvents",
                columns: ["timestamp"]
            )

            try db.create(table: "keyCounts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("key", .text).notNull()
                t.column("day", .text).notNull()
                t.column("appBundleID", .text).notNull()
                t.column("count", .integer).notNull().defaults(to: 0)
                t.uniqueKey(["key", "day", "appBundleID"])
            }
        }

        return migrator
    }
}
