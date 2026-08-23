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

/// Composition-root factory for the ADR-0010 analytics sink. Reads the bundled
/// `PostHogConfig.env` resource the `project.yml` `postBuildScripts` entry writes at build
/// time from the gitignored `MissionControl/.env` (see the ADR amending ADR-0010's storage
/// clause for why this is a build-time-injected value rather than an `MCSecrets`/Keychain
/// credential — and that ADR's Notes for why this reads a standalone bundled resource rather
/// than Info.plist keys: Xcode's script sandbox denies writing into the already-owned built
/// Info.plist). If both keys are present and non-blank, sets up the real PostHog SDK and
/// returns `PostHogAnalyticsEventLogger`; otherwise — the resource is missing (CI, or `.env`
/// not yet populated) or malformed — falls back to `NoOpAnalyticsEventLogger` with a logged
/// warning, exactly the stub behavior this replaces, so a missing `.env` degrades gracefully
/// instead of crashing the app.
enum AnalyticsEventLoggerFactory {
    static func make(bundle: Bundle = .main) -> AnalyticsEventLogger {
        let values = readConfigResource(bundle: bundle)

        guard let configuration = AnalyticsConfiguration.resolve(apiKey: values["POSTHOG_API_KEY"], host: values["POSTHOG_HOST"]) else {
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

    /// Parses the bundled `PostHogConfig.env` resource — plain `KEY=value` lines, matching
    /// `.env`'s own format — into a lookup dictionary. Missing resource or unparseable content
    /// both simply yield an empty dictionary, letting `AnalyticsConfiguration.resolve` apply
    /// its usual missing/blank-value fallback.
    private static func readConfigResource(bundle: Bundle) -> [String: String] {
        guard let url = bundle.url(forResource: "PostHogConfig", withExtension: "env"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var values: [String: String] = [:]
        for line in contents.split(separator: "\n") {
            guard let separatorIndex = line.firstIndex(of: "=") else { continue }
            let key = String(line[line.startIndex..<separatorIndex])
            let value = String(line[line.index(after: separatorIndex)...])
            values[key] = value
        }
        return values
    }
}
