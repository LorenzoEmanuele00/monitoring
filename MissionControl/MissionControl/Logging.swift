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
/// The real PostHog-backed implementation is `PostHogAnalyticsEventLogger`
/// (`PostHogAnalyticsEventLogger.swift`), wired in by `AnalyticsEventLoggerFactory.make()` and
/// composed into `AppEnvironment`. `NoOpAnalyticsEventLogger` below remains the graceful
/// fallback the factory returns when `MissionControl/.env` hasn't been populated at build time
/// (e.g. CI) — not a stub of the whole feature anymore, just this one degraded path.
protocol AnalyticsEventLogger: Sendable {
    func logCredentialExpired(providerKind: ProviderKind, integrationID: UUID)
    func logIntegrationDisconnected(providerKind: ProviderKind, integrationID: UUID)
}

/// Graceful fallback when PostHog configuration is unavailable (see `AnalyticsEventLoggerFactory`
/// in `PostHogAnalyticsEventLogger.swift`). Logs to `os.Logger` so the event isn't silently
/// lost even while PostHog itself is unconfigured.
struct NoOpAnalyticsEventLogger: AnalyticsEventLogger {
    func logCredentialExpired(providerKind: ProviderKind, integrationID: UUID) {
        AppLog.polling.error("[analytics-stub] credential expired: \(providerKind.rawValue, privacy: .public) \(integrationID, privacy: .public)")
    }

    func logIntegrationDisconnected(providerKind: ProviderKind, integrationID: UUID) {
        AppLog.polling.error("[analytics-stub] integration disconnected: \(providerKind.rawValue, privacy: .public) \(integrationID, privacy: .public)")
    }
}
