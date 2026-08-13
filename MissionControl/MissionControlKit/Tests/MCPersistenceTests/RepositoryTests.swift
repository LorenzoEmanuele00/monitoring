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

        let project = Project(name: "mise_pwa", vaultNoteRelativePath: "Progetti/Gestione Mezzi.md")
        try projectRepo.insert(project)

        let fetched = try projectRepo.fetch(id: project.id)
        #expect(fetched?.name == "mise_pwa")

        let all = try projectRepo.fetchAll()
        #expect(all.count == 1)
    }

    @Test func integrationLifecycleAndLastGoodWins() throws {
        let manager = try DatabaseManager(inMemory: true)
        let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)
        let integrationRepo = GRDBServiceIntegrationRepository(dbQueue: manager.dbQueue)

        let project = Project(name: "mise_pwa", vaultNoteRelativePath: "Progetti/Gestione Mezzi.md")
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
