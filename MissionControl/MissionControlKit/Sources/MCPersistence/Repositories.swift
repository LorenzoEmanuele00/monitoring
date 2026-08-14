import Foundation
import GRDB
import MCDomain

/// Per-BC repository protocol (ADR-0005: "accessed only via per-BC repository protocols in
/// MCDomain/MCPersistence"). Declared here rather than in MCDomain since the concrete type
/// depends on GRDB; the protocol itself has no GRDB in its signature, so call sites elsewhere
/// in the app only need to depend on the protocol shape, not GRDB.
public protocol ProjectRepository: Sendable {
    func insert(_ project: Project) throws
    func fetchAll() throws -> [Project]
    func fetch(id: UUID) throws -> Project?
}

public protocol ServiceIntegrationRepository: Sendable {
    func insert(_ integration: ServiceIntegration) throws
    func update(_ integration: ServiceIntegration) throws
    func fetchAll() throws -> [ServiceIntegration]
    func fetch(projectID: UUID) throws -> [ServiceIntegration]
    func fetch(id: UUID) throws -> ServiceIntegration?
}

public final class GRDBProjectRepository: ProjectRepository {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func insert(_ project: Project) throws {
        try dbQueue.write { db in
            try project.insert(db)
        }
    }

    public func fetchAll() throws -> [Project] {
        try dbQueue.read { db in
            try Project.fetchAll(db)
        }
    }

    public func fetch(id: UUID) throws -> Project? {
        try dbQueue.read { db in
            try Project.fetchOne(db, key: id)
        }
    }
}

public final class GRDBServiceIntegrationRepository: ServiceIntegrationRepository {
    private let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    public func insert(_ integration: ServiceIntegration) throws {
        try dbQueue.write { db in
            try integration.insert(db)
        }
    }

    public func update(_ integration: ServiceIntegration) throws {
        try dbQueue.write { db in
            try integration.update(db)
        }
    }

    public func fetchAll() throws -> [ServiceIntegration] {
        try dbQueue.read { db in
            try ServiceIntegration.fetchAll(db)
        }
    }

    public func fetch(projectID: UUID) throws -> [ServiceIntegration] {
        try dbQueue.read { db in
            try ServiceIntegration
                .filter(Column("projectID") == projectID)
                .fetchAll(db)
        }
    }

    public func fetch(id: UUID) throws -> ServiceIntegration? {
        try dbQueue.read { db in
            try ServiceIntegration.fetchOne(db, key: id)
        }
    }
}
