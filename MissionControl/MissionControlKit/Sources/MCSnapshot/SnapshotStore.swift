import Foundation
import MCDomain

/// Reads and writes Tier B (ADR-0005). The app writes; the app AND the widget extension read.
/// Every write is atomic (`Data.write(options: .atomic)`) so a concurrent reader in the
/// extension never observes a half-written file. Deleting the whole `Snapshots/` directory
/// must be safe — every read here tolerates a missing file/directory as "no data yet", not
/// an error.
public struct SnapshotStore: Sendable {
    private let appGroupIdentifier: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(appGroupIdentifier: String = AppGroupConfig.appGroupIdentifier) {
        self.appGroupIdentifier = appGroupIdentifier
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    private func snapshotFileURL(integrationID: UUID) throws -> URL {
        let dir = try AppGroupContainer.snapshotsURL(appGroupIdentifier: appGroupIdentifier)
        return dir.appendingPathComponent("\(integrationID.uuidString).json")
    }

    private func manifestFileURL() throws -> URL {
        let dir = try AppGroupContainer.snapshotsURL(appGroupIdentifier: appGroupIdentifier)
        return dir.appendingPathComponent("manifest.json")
    }

    /// Writes one Integration's snapshot atomically. Called by the app on every poll cycle
    /// that changed something (ADR-0005).
    public func writeSnapshot(_ snapshot: IntegrationSnapshot) throws {
        let data = try encoder.encode(snapshot)
        let url = try snapshotFileURL(integrationID: snapshot.integrationID)
        try data.write(to: url, options: .atomic)
    }

    public func readSnapshot(integrationID: UUID) -> IntegrationSnapshot? {
        guard let url = try? snapshotFileURL(integrationID: integrationID),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode(IntegrationSnapshot.self, from: data)
    }

    public func writeManifest(_ manifest: SnapshotManifest) throws {
        let data = try encoder.encode(manifest)
        let url = try manifestFileURL()
        try data.write(to: url, options: .atomic)
    }

    public func readManifest() -> SnapshotManifest? {
        guard let url = try? manifestFileURL(),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? decoder.decode(SnapshotManifest.self, from: data)
    }

    /// Convenience for the widget's TimelineProvider: manifest + first snapshot matching a
    /// provider kind. This spike renders exactly one Widget Kind for one Integration
    /// (GitHub), so "first match" is enough — a real Widget Kind picker is out of scope.
    public func readFirstSnapshot(matching providerKind: ProviderKind) -> IntegrationSnapshot? {
        guard let manifest = readManifest() else { return nil }
        for id in manifest.integrationIDs {
            if let snapshot = readSnapshot(integrationID: id), snapshot.providerKind == providerKind {
                return snapshot
            }
        }
        return nil
    }
}
