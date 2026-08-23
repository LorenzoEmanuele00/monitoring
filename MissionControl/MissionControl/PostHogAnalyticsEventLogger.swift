import Foundation
@preconcurrency import PostHog
import MCDomain

/// Real ADR-0010 structured-event sink, replacing `NoOpAnalyticsEventLogger` (infrastructure-
/// pht7k). Sends exactly the narrow event set ADR-0010 allows — `AnalyticsEvent` (MCDomain)
/// already carries the `system: "monitoring"` project-setup property and enforces the
/// redaction contract (only `providerKind`/`integrationID` ever travel, never an error string
/// or credential material) by construction; this type's only job is handing that shape to the
/// PostHog SDK.
struct PostHogAnalyticsEventLogger: AnalyticsEventLogger {
    func logCredentialExpired(providerKind: ProviderKind, integrationID: UUID) {
        send(.credentialExpired(providerKind: providerKind, integrationID: integrationID))
    }

    func logIntegrationDisconnected(providerKind: ProviderKind, integrationID: UUID) {
        send(.integrationDisconnected(providerKind: providerKind, integrationID: integrationID))
    }

    private func send(_ event: AnalyticsEvent) {
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }
}

/// Composition-root factory for the ADR-0010 analytics sink. Reads the two Info.plist keys the
/// `project.yml` `postBuildScripts` entry injects into the *built* Info.plist from the
/// gitignored `MissionControl/.env` (see the ADR amending ADR-0010's storage clause for why this
/// is a build-time-injected value rather than an `MCSecrets`/Keychain credential): if both are
/// present and non-blank, sets up the real PostHog SDK and returns `PostHogAnalyticsEventLogger`;
/// otherwise — `.env` absent at build time (CI, or before the builder has populated it) — falls
/// back to `NoOpAnalyticsEventLogger` with a logged warning, exactly the stub behavior this
/// replaces, so a missing `.env` degrades gracefully instead of crashing the app.
enum AnalyticsEventLoggerFactory {
    static func make(bundle: Bundle = .main) -> AnalyticsEventLogger {
        let apiKey = bundle.object(forInfoDictionaryKey: "PostHogAPIKey") as? String
        let host = bundle.object(forInfoDictionaryKey: "PostHogHost") as? String

        guard let configuration = AnalyticsConfiguration.resolve(apiKey: apiKey, host: host) else {
            AppLog.polling.info("PostHog configuration absent (MissionControl/.env not populated at build time) — structured domain events fall back to os.Logger only, see infrastructure BC README")
            return NoOpAnalyticsEventLogger()
        }

        let config = PostHogConfig(projectToken: configuration.apiKey, host: configuration.host)
        // ADR-0010's "unhandled crashes" event: PostHog's own crash capture, not a
        // self-managed handler — persists a fatal `$exception` event on next launch.
        config.errorTrackingConfig.autoCapture = true
        PostHogSDK.shared.setup(config)
        return PostHogAnalyticsEventLogger()
    }
}
