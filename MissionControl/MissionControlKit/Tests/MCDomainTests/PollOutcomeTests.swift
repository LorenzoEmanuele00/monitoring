import Testing
@testable import MCDomain
import Foundation

/// Regression coverage for the `isWorkInFlight` field added to `IntegrationPayload` for
/// ADR-0006 burst polling. Verifier note (iteration 1) on infrastructure-b92mn: adding
/// `isWorkInFlight` as a plain non-optional stored property made Swift's synthesized
/// `Decodable` require the key, so every Tier B snapshot written before this field existed
/// failed to decode — `SnapshotStore.readSnapshot` swallowed that and returned `nil`, which
/// broke ADR-0008's last-good-wins rule. `IntegrationPayload` now has a custom
/// `init(from:)` that treats a missing `isWorkInFlight` key as `false`; this test exercises
/// `Decodable` directly (not the memberwise `init(...)` convenience initializer) against a
/// literal JSON fixture shaped exactly like a pre-field-addition snapshot payload.
@Suite struct PollOutcomeTests {
    @Test func decodesPayloadMissingIsWorkInFlightKeyAsFalse() throws {
        let legacyJSON = """
        {
            "headline": "CI passing",
            "detail": "abc1234",
            "isAttentionNeeded": false
        }
        """
        let data = Data(legacyJSON.utf8)

        let payload = try JSONDecoder().decode(IntegrationPayload.self, from: data)

        #expect(payload.headline == "CI passing")
        #expect(payload.detail == "abc1234")
        #expect(payload.isAttentionNeeded == false)
        #expect(payload.isWorkInFlight == false)
    }

    @Test func decodesPayloadWithIsWorkInFlightKeyPresent() throws {
        let currentJSON = """
        {
            "headline": "Build running",
            "detail": "queued",
            "isAttentionNeeded": false,
            "isWorkInFlight": true
        }
        """
        let data = Data(currentJSON.utf8)

        let payload = try JSONDecoder().decode(IntegrationPayload.self, from: data)

        #expect(payload.isWorkInFlight == true)
    }
}
