import Foundation

/// Resolved PostHog configuration values (ADR-0010, amended by the ADR recording the
/// gitignored-`.env`-plus-build-time-injection storage convention for this specific credential —
/// see `.agentheim/knowledge/decisions/` for the amendment). Pure parsing/validation logic
/// factored out of the app-target `AnalyticsEventLoggerFactory` so the "gracefully fall back to
/// a no-op logger when `MissionControl/.env` was absent at build time" behavior is
/// unit-testable with `swift test`, independent of the PostHog SDK (which only the app target
/// links, per ADR-0004/ADR-0010).
public struct AnalyticsConfiguration: Equatable, Sendable {
    public let apiKey: String
    public let host: String

    public init(apiKey: String, host: String) {
        self.apiKey = apiKey
        self.host = host
    }

    /// Returns `nil` — the caller's signal to fall back to a no-op logger — when either value
    /// is missing or blank. Covers both "CI, or before the builder has created `.env`" (the
    /// `project.yml` buildScript never ran `PlistBuddy`, so the Info.plist keys are simply
    /// absent) and "`.env` exists but is empty/malformed" (the buildScript ran but sourced
    /// blank values).
    public static func resolve(apiKey: String?, host: String?) -> AnalyticsConfiguration? {
        guard let apiKey, let host else { return nil }
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !trimmedHost.isEmpty else { return nil }
        return AnalyticsConfiguration(apiKey: trimmedKey, host: trimmedHost)
    }
}
