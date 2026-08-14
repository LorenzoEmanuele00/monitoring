import Testing
@testable import MCSnapshot
import MCDomain
import Foundation

/// `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` synthesizes a path
/// under `~/Library/Group Containers/<id>/` without validating App Group entitlement
/// membership when the calling process isn't itself sandboxed (true for a bare `swift test`
/// binary) — so `AppGroupContainer.rootURL` does NOT throw here even for a made-up
/// identifier. The real "does this App Group actually exist" check only happens once the
/// signed app/extension resolve it inside the sandbox at runtime. What IS verifiable outside
/// Xcode is the self-healing directory creation and the snapshot/manifest round trip against
/// whatever local path is resolved, which is what these tests cover.
@Suite struct SnapshotStoreTests {
    @Test func rootURLIsScopedByAppGroupIdentifier() throws {
        let a = try AppGroupContainer.rootURL(appGroupIdentifier: "group.a.missioncontrol")
        let b = try AppGroupContainer.rootURL(appGroupIdentifier: "group.b.missioncontrol")
        #expect(a != b)
        #expect(a.path.contains("group.a.missioncontrol"))
    }

    @Test func snapshotsURLIsSelfHealingCreatesDirectoryIfMissing() throws {
        let testGroupID = "group.mctest.\(UUID().uuidString).missioncontrol"
        let dir = try AppGroupContainer.snapshotsURL(appGroupIdentifier: testGroupID)
        defer {
            if let root = try? AppGroupContainer.rootURL(appGroupIdentifier: testGroupID) {
                try? FileManager.default.removeItem(at: root)
            }
        }
        #expect(FileManager.default.fileExists(atPath: dir.path))
    }

    @Test func manifestAndSnapshotRoundTrip() throws {
        let testGroupID = "group.mctest.\(UUID().uuidString).missioncontrol"
        defer {
            if let root = try? AppGroupContainer.rootURL(appGroupIdentifier: testGroupID) {
                try? FileManager.default.removeItem(at: root)
            }
        }

        let store = SnapshotStore(appGroupIdentifier: testGroupID)
        let integrationID = UUID()
        let snapshot = IntegrationSnapshot(
            integrationID: integrationID,
            projectName: "mise_pwa",
            providerKind: .githubRepository,
            displayName: "LorenzoEmanuele00/mise_pwa",
            status: .connected,
            payload: IntegrationPayload(headline: "CI passing", detail: "abc1234"),
            generatedAt: Date(),
            lastAttemptAt: Date(),
            lastError: nil
        )
        try store.writeSnapshot(snapshot)
        try store.writeManifest(SnapshotManifest(integrationIDs: [integrationID], generatedAt: Date()))

        let readBack = store.readSnapshot(integrationID: integrationID)
        #expect(readBack?.payload?.headline == "CI passing")

        let manifest = store.readManifest()
        #expect(manifest?.integrationIDs.contains(integrationID) == true)
    }
}
