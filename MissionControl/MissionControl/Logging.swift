import Foundation
import os
import MCDomain

/// Unified logging (ADR-0010): one subsystem, one category per concern. `os.Logger` is used
/// everywhere, including inside the widget extension (see
/// `MissionControlWidgets/Logging.swift`) — this is the only observability path there.
enum AppLog {
    static let ui = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "ui")
    static let polling = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "polling")
    static let persistence = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "persistence")
    static let secrets = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "secrets")
    static let projectRegistry = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "project-registry")
}

/// Narrow structured-event surface (ADR-0010): "unhandled crashes, Integration credential
/// expired, deploy started/ended, Integration disconnected (circuit breaker). Not general
/// logging, not analytics." Credential material never flows through here.
///
/// **This spike stubs the real PostHog SDK wiring** (ADR-0010 explicitly allows this: "for
/// this walking-skeleton spike, PostHog wiring is acceptable to stub/defer if it threatens
/// the stop-loss — the mandatory piece is os.Logger"). `os.Logger` above is the mandatory,
/// fully-wired piece; this protocol exists so the polling pipeline is already shaped to call
/// out these events, and swapping in the real SDK later is a one-file change. See the
/// `infrastructure` BC backlog for the follow-up task that wires the real SDK.
protocol AnalyticsEventLogger: Sendable {
    func logCredentialExpired(providerKind: ProviderKind, integrationID: UUID)
    func logIntegrationDisconnected(providerKind: ProviderKind, integrationID: UUID)
}

/// No-op implementation used until the real PostHog SDK is wired (see backlog follow-up).
/// Logs to `os.Logger` so the event isn't silently lost even while PostHog itself is stubbed.
struct NoOpAnalyticsEventLogger: AnalyticsEventLogger {
    func logCredentialExpired(providerKind: ProviderKind, integrationID: UUID) {
        AppLog.polling.error("[analytics-stub] credential expired: \(providerKind.rawValue, privacy: .public) \(integrationID, privacy: .public)")
    }

    func logIntegrationDisconnected(providerKind: ProviderKind, integrationID: UUID) {
        AppLog.polling.error("[analytics-stub] integration disconnected: \(providerKind.rawValue, privacy: .public) \(integrationID, privacy: .public)")
    }
}
