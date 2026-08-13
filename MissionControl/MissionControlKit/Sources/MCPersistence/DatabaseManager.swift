import Foundation
import GRDB
import MCDomain

/// Owns Tier A's `DatabaseQueue` (ADR-0005: GRDB/SQLite, WAL mode,
/// `<group>/Library/Application Support/missioncontrol.sqlite`). Written only by the main
/// app; the widget extension never links this module (structurally enforced by target
/// dependencies in `project.yml`, not just convention).
public final class DatabaseManager: Sendable {
    public let dbQueue: DatabaseQueue

    public init(appGroupIdentifier: String = AppGroupConfig.appGroupIdentifier) throws {
        let dir = try AppGroupContainer.applicationSupportURL(appGroupIdentifier: appGroupIdentifier)
        let path = dir.appendingPathComponent("missioncontrol.sqlite").path
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        self.dbQueue = try DatabaseQueue(path: path, configuration: config)
        try Self.migrator.migrate(dbQueue)
    }

    /// In-memory database for unit tests / previews — same schema, no App Group dependency.
    public init(inMemory: Bool) throws {
        precondition(inMemory, "Use the throwing App-Group initializer for real persistence.")
        self.dbQueue = try DatabaseQueue()
        try Self.migrator.migrate(dbQueue)
    }

    /// Schema changes go through GRDB's `DatabaseMigrator` (ADR-0005) — never ad-hoc ALTERs.
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            // `id`/`projectID` are `.blob`, not `.text`: GRDB's built-in `UUID`
            // `DatabaseValueConvertible` conformance stores UUIDs as their 16-byte raw
            // representation, not a string — the column type must match that encoding for
            // `fetchOne(db, key:)`/`filter(Column(...) == uuid)` lookups to hit.
            try db.create(table: "project") { t in
                t.column("id", .blob).primaryKey()
                t.column("name", .text).notNull()
                t.column("vaultNoteRelativePath", .text).notNull()
                t.column("sourcePathBookmark", .blob)
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "serviceIntegration") { t in
                t.column("id", .blob).primaryKey()
                t.column("projectID", .blob).notNull()
                    .references("project", onDelete: .cascade)
                t.column("providerKind", .text).notNull()
                t.column("credentialKind", .text).notNull()
                t.column("displayName", .text).notNull()
                t.column("externalRef", .text).notNull()
                t.column("status", .text).notNull()
                t.column("lastAttemptAt", .datetime)
                t.column("lastSuccessAt", .datetime)
                t.column("lastError", .text)
                t.column("etag", .text)
                t.column("consecutiveFailureCount", .integer).notNull().defaults(to: 0)
            }
        }

        return migrator
    }
}
