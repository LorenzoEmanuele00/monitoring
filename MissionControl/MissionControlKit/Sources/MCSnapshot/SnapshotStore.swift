import Foundation
import MCDomain
import os

/// Reads and writes Tier B (ADR-0005). The app writes; the app AND the widget extension read.
/// Deleting the whole `Snapshots/` directory must be safe — every read here tolerates a missing
/// file/directory as "no data yet", not an error.
///
/// **History — the real cross-process read bug turned out NOT to be in this file.** Every file
/// written here came back readable by the app but refused by the widget extension with
/// `NSPOSIXErrorDomain Code=1 "Operation not permitted"`. Two hypotheses were tried and ruled
/// out by direct testing (fully quitting the app so nothing could rewrite files, stripping
/// `com.apple.quarantine` via `xattr -d`, and confirming the widget STILL failed to read a
/// verified-clean, freshly-written file): neither `Data.write(options: .atomic)` vs. plain
/// writes, nor the `com.apple.quarantine` extended attribute macOS puts on files this app
/// writes, was the actual blocker. `clearQuarantine(at:)` below is kept as harmless hygiene —
/// declaring "I created this file myself" to Gatekeeper is reasonable regardless — but it is
/// NOT what fixed the symptom.
///
/// The actual root cause: xcodegen writes `com.apple.security.application-groups` directly into
/// the `.entitlements` files (`project.yml` → `CODE_SIGN_ENTITLEMENTS`), which never goes
/// through Xcode's Signing & Capabilities UI — the thing that actually registers an App Group
/// with the Apple Developer Portal and provisions a profile that grants it. Until that
/// registration happens, Automatic Signing silently falls back to a generic wildcard "Mac Team
/// Provisioning Profile: *" (`application-identifier: TEAMID.*`), which by Apple's own rules
/// can never carry the App Groups capability — confirmed by decoding the actual
/// `.provisionprofile` file via `security cms -D -i`. The compiled entitlements blob still
/// claims the capability (so container *resolution* — `FileManager
/// .containerURL(forSecurityApplicationGroupIdentifier:)` — succeeds, and the writing app can
/// read its own output fine), but genuine cross-process sandbox enforcement checks the real
/// provisioning grant, not just the binary's local entitlements XML, and refuses the sibling
/// process. Once Xcode (re)provisioned two proper, app-ID-specific profiles — confirmed via the
/// same `security cms -D -i` inspection showing `com.apple.security.application-groups` present
/// for both `com.lorenzoemanuele.missioncontrol` and `.widgets` — reads started succeeding
/// immediately, with the quarantine attribute still present and untouched. See the infrastructure
/// BC README's "Provisioning caveat" section for the general pattern this confirms: a hand-authored
/// entitlement is necessary but not sufficient for a capability that requires portal registration.
///
/// Every read path logs its actual failure reason at `.error` level (not just `.debug`) before
/// collapsing it to `nil` — a bare `try?` here previously hid file-not-found vs. permission-denied
/// vs. decode-mismatch behind an identical "no data yet" widget state. This is how the
/// provisioning-profile root cause above was actually found and confirmed, not guessed.
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
    /// something (ADR-0005).
    public func writeSnapshot(_ snapshot: IntegrationSnapshot) throws {
        let data = try encoder.encode(snapshot)
        let url = try snapshotFileURL(integrationID: snapshot.integrationID)
        try data.write(to: url, options: .atomic)
        clearQuarantine(at: url)
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
        try data.write(to: url, options: .atomic)
        clearQuarantine(at: url)
    }

    /// Declares "I created this file myself, it is not downloaded content" to Gatekeeper — see
    /// the type doc comment. Best-effort: a failure here is logged, not thrown, since the actual
    /// data write already succeeded and the app itself can still read what it just wrote either
    /// way; only cross-process (widget) reads depend on this succeeding.
    private func clearQuarantine(at url: URL) {
        var url = url
        var resourceValues = URLResourceValues()
        resourceValues.quarantineProperties = nil
        do {
            try url.setResourceValues(resourceValues)
        } catch {
            logger.error(
                "clearQuarantine(\(url.lastPathComponent, privacy: .public)) failed: \(String(describing: error), privacy: .public)"
            )
        }
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
