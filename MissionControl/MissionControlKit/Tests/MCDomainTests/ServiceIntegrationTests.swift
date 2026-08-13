import Testing
@testable import MCDomain
import Foundation

@Suite struct ServiceIntegrationTests {
    @Test func circuitOpensAtThreshold() {
        var integration = ServiceIntegration(
            projectID: UUID(),
            providerKind: .githubRepository,
            credentialKind: .staticToken,
            displayName: "mise_pwa",
            externalRef: "LorenzoEmanuele00/mise_pwa"
        )
        #expect(!integration.isCircuitOpen)
        integration.consecutiveFailureCount = ServiceIntegration.circuitBreakerThreshold - 1
        #expect(!integration.isCircuitOpen)
        integration.consecutiveFailureCount = ServiceIntegration.circuitBreakerThreshold
        #expect(integration.isCircuitOpen)
    }

    @Test func codableRoundTrip() throws {
        let integration = ServiceIntegration(
            projectID: UUID(),
            providerKind: .firebaseHosting,
            credentialKind: .serviceAccountKey,
            displayName: "mise_pwa hosting",
            externalRef: "mise-pwa-site",
            status: .connected,
            etag: "\"abc123\""
        )
        let data = try JSONEncoder().encode(integration)
        let decoded = try JSONDecoder().decode(ServiceIntegration.self, from: data)
        #expect(decoded == integration)
    }
}
