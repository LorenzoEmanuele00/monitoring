import Testing
@testable import MCDesignTokens

/// Covers `MCUsageMetricTile`'s bar-color rule (`design-system-q9vhm`): the usage bar switches
/// from `positive` to the `warning` (degraded) tone once consumption exceeds 80% of the limit —
/// matches the draft spec's "bar color switches to degraded past 80%" and its sample data
/// (`Bandwidth 84% -> "soglia 80% superata"`, degraded bar).
@Suite struct MCUsageMetricTileTests {
    @Test func wellBelowThresholdIsPositive() {
        #expect(MCUsageMetricTile.barTone(forFraction: 0.26) == .positive)
    }

    @Test func justBelowThresholdIsStillPositive() {
        #expect(MCUsageMetricTile.barTone(forFraction: 0.8) == .positive)
    }

    @Test func justAboveThresholdIsWarning() {
        #expect(MCUsageMetricTile.barTone(forFraction: 0.81) == .warning)
    }

    @Test func wellAboveThresholdIsWarning() {
        #expect(MCUsageMetricTile.barTone(forFraction: 1.0) == .warning)
    }

    @Test func resolvedThresholdValue() {
        #expect(MCUsageMetricTile.degradedThreshold == 0.8)
    }
}
