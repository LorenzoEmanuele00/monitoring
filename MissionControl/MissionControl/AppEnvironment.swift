import Foundation
import SwiftUI
import MCDomain
import MCPersistence
import MCSnapshot
import MCSecrets
import MCProviders

/// App-wide dependency container (ADR-0004/0005/0006/0007). Composes Tier A, Tier B,
/// the Keychain-backed `SecretStore`, and the `PollingCoordinator`, then exposes
/// `@Published` state the SwiftUI views read.
@MainActor
final class AppEnvironment: ObservableObject {
    let secretStore: SecretStore
    let snapshotStore: SnapshotStore
    private let databaseManager: DatabaseManager?
    private let projectRepository: ProjectRepository?
    private let integrationRepository: ServiceIntegrationRepository?
    let pollingCoordinator: PollingCoordinator?

    @Published var projects: [Project] = []
    @Published var integrations: [ServiceIntegration] = []
    @Published var bootstrapError: String?

    init() {
        self.secretStore = KeychainSecretStore()
        self.snapshotStore = SnapshotStore()

        do {
            let manager = try DatabaseManager()
            self.databaseManager = manager
            let projectRepo = GRDBProjectRepository(dbQueue: manager.dbQueue)
            let integrationRepo = GRDBServiceIntegrationRepository(dbQueue: manager.dbQueue)
            self.projectRepository = projectRepo
            self.integrationRepository = integrationRepo
            self.pollingCoordinator = PollingCoordinator(
                projectRepository: projectRepo,
                integrationRepository: integrationRepo,
                secretStore: secretStore,
                snapshotStore: snapshotStore
            )
        } catch {
            // ADR-0009's "first-class, user-visible state" discipline applies here too:
            // a missing App Group container (e.g. running unsigned/unentitled) must surface
            // as a diagnosable state, never a silent empty list.
            AppLog.persistence.fault("Failed to open Tier A database: \(String(describing: error), privacy: .public)")
            self.databaseManager = nil
            self.projectRepository = nil
            self.integrationRepository = nil
            self.pollingCoordinator = nil
            self.bootstrapError = "\(error)"
        }

        reload()
    }

    func reload() {
        do {
            projects = try projectRepository?.fetchAll() ?? []
            integrations = try integrationRepository?.fetchAll() ?? []
        } catch {
            AppLog.persistence.error("Failed to reload from Tier A: \(String(describing: error), privacy: .public)")
        }
    }

    func addProject(_ project: Project) throws {
        try projectRepository?.insert(project)
        reload()
    }

    func addIntegration(_ integration: ServiceIntegration, credential: Data) throws {
        try secretStore.store(credential, for: integration.id)
        try integrationRepository?.insert(integration)
        reload()
        pollingCoordinator?.integrationsChanged()
    }

    func startPolling() {
        pollingCoordinator?.start()
    }
}
