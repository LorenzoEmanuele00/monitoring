import Testing
@testable import MCPersistence
import MCDomain
import Foundation

@Suite struct RepositoryTests {
    @Test func migratorCreatesQueryableSchema() throws {
        let manager = try DatabaseManager(inMemory: true)
        let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)
        #expect(try projectRepo.fetchAll().isEmpty)
    }

    @Test func projectInsertAndFetch() throws {
        let manager = try DatabaseManager(inMemory: true)
        let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)

        let project = Project(name: "mise_pwa", obsidianNoteLink: "Progetti/Gestione Mezzi.md")
        try projectRepo.insert(project)

        let fetched = try projectRepo.fetch(id: project.id)
        #expect(fetched?.name == "mise_pwa")

        let all = try projectRepo.fetchAll()
        #expect(all.count == 1)
    }

    /// Covers acceptance criterion 1 of project-registry-vnk4t: registering a Project with only
    /// a name (no Obsidian link, no Source Path) must succeed all the way through the schema —
    /// this is the test that would have caught a missed `.notNull()` removal on the
    /// `obsidianNoteLink` column (`DatabaseManager`'s `v1_initial` migration), which the earlier
    /// in-memory-only `ProjectTests` coverage could not catch.
    @Test func projectWithNoObsidianLinkInsertsAndFetchesAsNil() throws {
        let manager = try DatabaseManager(inMemory: true)
        let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)

        let project = Project(name: "name-only")
        try projectRepo.insert(project)

        let fetched = try projectRepo.fetch(id: project.id)
        #expect(fetched?.name == "name-only")
        #expect(fetched?.obsidianNoteLink == nil)
    }

    /// Covers acceptance criterion 2 of project-registry-vnk4t: a Project's Obsidian link, when
    /// set, is stored and read back unchanged. This exercises the actual GRDB Codable column
    /// mapping (`GRDBRecordConformances.swift`), unlike the earlier `JSONEncoder`/`JSONDecoder`
    /// round-trip test, which never touched storage.
    @Test func projectWithObsidianLinkRoundTripsThroughStorageUnchanged() throws {
        let manager = try DatabaseManager(inMemory: true)
        let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)

        let link = "Progetti/Gestione Mezzi.md"
        let project = Project(name: "mise_pwa", obsidianNoteLink: link)
        try projectRepo.insert(project)

        let fetched = try projectRepo.fetch(id: project.id)
        #expect(fetched?.obsidianNoteLink == link)
    }

    @Test func integrationLifecycleAndLastGoodWins() throws {
        let manager = try DatabaseManager(inMemory: true)
        let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)
        let integrationRepo = GRDBServiceIntegrationRepository(dbQueue: manager.dbQueue)

        let project = Project(name: "mise_pwa", obsidianNoteLink: "Progetti/Gestione Mezzi.md")
        try projectRepo.insert(project)

        var integration = ServiceIntegration(
            projectID: project.id,
            providerKind: .githubRepository,
            credentialKind: .staticToken,
            displayName: "mise_pwa",
            externalRef: "LorenzoEmanuele00/mise_pwa"
        )
        try integrationRepo.insert(integration)

        // A successful poll: advances lastSuccessAt, clears error.
        integration.status = .connected
        integration.lastSuccessAt = Date()
        integration.lastAttemptAt = integration.lastSuccessAt
        integration.etag = "\"etag-1\""
        try integrationRepo.update(integration)

        let afterSuccess = try integrationRepo.fetch(id: integration.id)
        #expect(afterSuccess?.status == .connected)
        #expect(afterSuccess?.etag == "\"etag-1\"")

        // A subsequent failed poll (ADR-0008): lastAttemptAt/lastError update, but
        // lastSuccessAt and etag — the "last-good" markers — must not regress to nil.
        integration.lastAttemptAt = Date()
        integration.lastError = "network error"
        integration.consecutiveFailureCount += 1
        try integrationRepo.update(integration)

        let afterFailure = try integrationRepo.fetch(id: integration.id)
        #expect(afterFailure?.lastError == "network error")
        #expect(afterFailure?.lastSuccessAt != nil)
        #expect(afterFailure?.etag == "\"etag-1\"")

        let forProject = try integrationRepo.fetch(projectID: project.id)
        #expect(forProject.count == 1)
    }
}
