import Foundation
import MCDomain
import os

/// Reads and writes Tier B (ADR-0005). The app writes; the app AND the widget extension read.
/// Deleting the whole `Snapshots/` directory must be safe — every read here tolerates a missing
/// file/directory as "no data yet", not an error.
///
/// Writes are deliberately NOT `Data.write(options: .atomic)`. That option writes to a temp file
/// and renames it into place, which — confirmed live in this App Group container via the error
/// logging below — leaves the resulting file visible only to the writing process's own sandbox
/// container: a sibling process sharing the same App Group entitlement (the widget extension)
/// gets `NSPOSIXErrorDomain Code=1 "Operation not permitted"` trying to open it, even though it
/// can resolve the container root fine. A plain (non-atomic) write has no such restriction. This
/// trades the "a concurrent reader never observes a half-written file" guarantee for the file
/// actually being readable cross-process at all; for these single-digit-KB JSON files the torn-
/// read window is negligible in practice, and an unreadable file is strictly worse than a rare
/// truncated one (both cases are already tolerated as "no data yet" by every read path here).
///
/// Every read path logs its actual failure reason at `.error` level (not just `.debug`) before
/// collapsing it to `nil` — a bare `try?` here previously hid file-not-found vs. permission-denied
/// vs. decode-mismatch behind an identical "no data yet" widget state, making a real bug (e.g. a
/// container/entitlement mismatch reached only by the extension process) indistinguishable from
/// the expected "nothing polled yet" case. This is how the access-restriction above was found.
public struct SnapshotStore: Sendable {
    private let appGroupIdentifier: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "snapshot-store")

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

    /// Writes one Integration's snapshot. Called by the app on every poll cycle that changed
    /// something (ADR-0005). See the type doc comment for why this is not `.atomic`.
    public func writeSnapshot(_ snapshot: IntegrationSnapshot) throws {
        let data = try encoder.encode(snapshot)
        let url = try snapshotFileURL(integrationID: snapshot.integrationID)
        try data.write(to: url)
    }

    public func readSnapshot(integrationID: UUID) -> IntegrationSnapshot? {
        do {
            let url = try snapshotFileURL(integrationID: integrationID)
            let data = try Data(contentsOf: url)
            return try decoder.decode(IntegrationSnapshot.self, from: data)
        } catch {
            logger.error(
                "readSnapshot(\(integrationID.uuidString, privacy: .public)) failed: \(String(describing: error), privacy: .public)"
            )
            return nil
        }
    }

    public func writeManifest(_ manifest: SnapshotManifest) throws {
        let data = try encoder.encode(manifest)
        let url = try manifestFileURL()
        try data.write(to: url)
    }

    public func readManifest() -> SnapshotManifest? {
        do {
            let url = try manifestFileURL()
            let data = try Data(contentsOf: url)
            return try decoder.decode(SnapshotManifest.self, from: data)
        } catch {
            logger.error("readManifest() failed: \(String(describing: error), privacy: .public)")
            return nil
        }
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
