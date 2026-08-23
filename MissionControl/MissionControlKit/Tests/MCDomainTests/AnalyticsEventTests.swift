import Testing
@testable import MCDomain
import Foundation

/// ADR-0010's structured-event set, wired for real in infrastructure-pht7k. `AnalyticsEvent`
/// is the PostHog-SDK-independent shape (only the app target links the PostHog SDK itself, per
/// ADR-0004/ADR-0010) so the redaction contract — exactly `providerKind`/`integrationID` travel,
/// never error strings or credential material — stays unit-testable at package level.
@Suite struct AnalyticsEventTests {
    @Test func credentialExpiredCarriesOnlyProviderKindIntegrationIDAndSystemProperty() {
        let integrationID = UUID()

        let event = AnalyticsEvent.credentialExpired(providerKind: .githubRepository, integrationID: integrationID)

        #expect(event.name == "Integration credential expired")
        #expect(event.properties == [
            "system": "monitoring",
            "provider_kind": "githubRepository",
            "integration_id": integrationID.uuidString,
        ])
    }

    @Test func integrationDisconnectedCarriesOnlyProviderKindIntegrationIDAndSystemProperty() {
        let integrationID = UUID()

        let event = AnalyticsEvent.integrationDisconnected(providerKind: .supabaseProject, integrationID: integrationID)

        #expect(event.name == "Integration disconnected")
        #expect(event.properties == [
            "system": "monitoring",
            "provider_kind": "supabaseProject",
            "integration_id": integrationID.uuidString,
        ])
    }

    @Test func everyEventStampsTheSharedProjectSystemProperty() {
        let events: [AnalyticsEvent] = [
            .credentialExpired(providerKind: .firebaseHosting, integrationID: UUID()),
            .integrationDisconnected(providerKind: .firebaseHosting, integrationID: UUID()),
        ]

        for event in events {
            #expect(event.properties["system"] == AnalyticsSystem.value)
        }
    }
}
