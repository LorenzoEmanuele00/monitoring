import Foundation

/// `system` event property (project-setup note, 2026-08-23, ADR-0010) stamped on every event
/// this app sends: this PostHog project is shared with the builder's other personal systems
/// (mise_pwa, mise_web), so every event needs a way to say which one produced it.
public enum AnalyticsSystem {
    public static let value = "monitoring"
}

/// Pure, PostHog-SDK-independent shape of ADR-0010's structured domain events. Lives in
/// `MCDomain` (no PostHog SDK dependency — only the `MissionControl` app target links that SDK,
/// per ADR-0004/ADR-0010) purely so the redaction contract is unit-testable with `swift test`:
/// each factory below accepts only `providerKind`/`integrationID`, never an error string or any
/// credential-adjacent value, so there is nothing in the type's shape that *could* leak
/// credential material into a PostHog payload.
public struct AnalyticsEvent: Equatable, Sendable {
    public let name: String
    public let properties: [String: String]

    public init(name: String, properties: [String: String]) {
        self.name = name
        self.properties = properties
    }

    /// ADR-0010's "Integration credential expired" event — fired by `PollingCoordinator.pollOne`
    /// on a terminal poll failure.
    public static func credentialExpired(providerKind: ProviderKind, integrationID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "Integration credential expired",
            properties: [
                "system": AnalyticsSystem.value,
                "provider_kind": providerKind.rawValue,
                "integration_id": integrationID.uuidString,
            ]
        )
    }

    /// ADR-0010's "Integration disconnected" event — fired by `PollingCoordinator.pollOne` when
    /// the ADR-0008 circuit breaker trips.
    public static func integrationDisconnected(providerKind: ProviderKind, integrationID: UUID) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "Integration disconnected",
            properties: [
                "system": AnalyticsSystem.value,
                "provider_kind": providerKind.rawValue,
                "integration_id": integrationID.uuidString,
            ]
        )
    }
}
