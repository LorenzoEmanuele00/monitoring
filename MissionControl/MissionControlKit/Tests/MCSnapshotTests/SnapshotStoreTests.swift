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

    /// Regression for the verifier-caught bug on infrastructure-b92mn iteration 1: a snapshot
    /// file written before `IntegrationPayload.isWorkInFlight` existed must still decode via
    /// `readSnapshot`, per ADR-0008's last-good-wins rule. Writes the JSON directly (not via
    /// `store.writeSnapshot`) so the fixture is exactly what a pre-field-addition snapshot on
    /// disk looked like — no `isWorkInFlight` key anywhere in the payload object.
    @Test func readSnapshotToleratesPayloadWrittenBeforeIsWorkInFlightExisted() throws {
        let testGroupID = "group.mctest.\(UUID().uuidString).missioncontrol"
        defer {
            if let root = try? AppGroupContainer.rootURL(appGroupIdentifier: testGroupID) {
                try? FileManager.default.removeItem(at: root)
            }
        }

        let store = SnapshotStore(appGroupIdentifier: testGroupID)
        let integrationID = UUID()
        let dir = try AppGroupContainer.snapshotsURL(appGroupIdentifier: testGroupID)
        let url = dir.appendingPathComponent("\(integrationID.uuidString).json")

        let legacySnapshotJSON = """
        {
            "integrationID": "\(integrationID.uuidString)",
            "projectName": "mise_pwa",
            "providerKind": "githubRepository",
            "displayName": "LorenzoEmanuele00/mise_pwa",
            "status": "connected",
            "payload": {
                "headline": "CI passing",
                "detail": "abc1234",
                "isAttentionNeeded": false
            },
            "generatedAt": "2026-01-01T00:00:00Z",
            "lastAttemptAt": "2026-01-01T00:00:00Z"
        }
        """
        try Data(legacySnapshotJSON.utf8).write(to: url, options: .atomic)

        let readBack = store.readSnapshot(integrationID: integrationID)
        #expect(readBack?.payload?.headline == "CI passing")
        #expect(readBack?.payload?.isWorkInFlight == false)
    }
}
