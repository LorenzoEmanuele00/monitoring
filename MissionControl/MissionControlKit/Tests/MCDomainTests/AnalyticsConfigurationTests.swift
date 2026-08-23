import Testing
@testable import MCDomain

/// Covers the "fail gracefully when `MissionControl/.env` was absent at build time" behavior
/// (infrastructure-pht7k Notes) without needing the PostHog SDK or a real build: the app-target
/// factory (`AnalyticsEventLoggerFactory` in `MissionControl/MissionControl/`) reads two
/// `Bundle.main` Info.plist keys the `project.yml` buildScript injects from `.env`, and this
/// pure resolver decides whether that's enough to stand up the real logger or fall back to
/// `NoOpAnalyticsEventLogger`.
@Suite struct AnalyticsConfigurationTests {
    @Test func resolvesWhenBothValuesPresentAndNonBlank() {
        let configuration = AnalyticsConfiguration.resolve(apiKey: "phc_abc123", host: "https://us.i.posthog.com")

        #expect(configuration == AnalyticsConfiguration(apiKey: "phc_abc123", host: "https://us.i.posthog.com"))
    }

    @Test func returnsNilWhenApiKeyMissing() {
        #expect(AnalyticsConfiguration.resolve(apiKey: nil, host: "https://us.i.posthog.com") == nil)
    }

    @Test func returnsNilWhenHostMissing() {
        #expect(AnalyticsConfiguration.resolve(apiKey: "phc_abc123", host: nil) == nil)
    }

    @Test func returnsNilWhenBothMissing() {
        #expect(AnalyticsConfiguration.resolve(apiKey: nil, host: nil) == nil)
    }

    @Test func returnsNilWhenApiKeyIsBlank() {
        // `PlistBuddy` having run against an empty/malformed `.env` (values present but blank)
        // must fall back exactly like the key being absent entirely.
        #expect(AnalyticsConfiguration.resolve(apiKey: "   ", host: "https://us.i.posthog.com") == nil)
    }

    @Test func returnsNilWhenHostIsBlank() {
        #expect(AnalyticsConfiguration.resolve(apiKey: "phc_abc123", host: "") == nil)
    }
}
