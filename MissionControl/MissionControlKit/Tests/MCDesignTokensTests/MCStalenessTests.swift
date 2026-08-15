import Testing
@testable import MCDesignTokens
import Foundation

/// Covers the styleguide task's resolved conflict between `infrastructure-mam0r`'s placeholder
/// 30min/2h staleness thresholds and the design draft's tighter 15min/60min guess — the design
/// system BC owns the final visual-treatment figures (ADR-0008 explicitly delegates this), and
/// resolved on 15min/60min. See ADR-0015 and the design-system README.
@Suite struct MCStalenessTests {
    private let reference = Date(timeIntervalSince1970: 1_000_000)

    @Test func freshJustBelowSubduedThreshold() {
        let generatedAt = reference.addingTimeInterval(-(MCStaleness.subduedThreshold - 1))
        #expect(MCStaleness.level(generatedAt: generatedAt, now: reference) == .fresh)
    }

    @Test func subduedAtFifteenMinutes() {
        // The old infrastructure-mam0r placeholder (30 min) would still call this "fresh" —
        // this is the concrete behavioral difference the threshold resolution decided.
        let generatedAt = reference.addingTimeInterval(-20 * 60)
        #expect(MCStaleness.level(generatedAt: generatedAt, now: reference) == .subdued)
    }

    @Test func stillSubduedJustBelowFlaggedThreshold() {
        let generatedAt = reference.addingTimeInterval(-(MCStaleness.flaggedThreshold - 1))
        #expect(MCStaleness.level(generatedAt: generatedAt, now: reference) == .subdued)
    }

    @Test func flaggedAtOneHour() {
        // The old placeholder (2h) would still call this "subdued" — again the concrete
        // behavioral difference the threshold resolution decided.
        let generatedAt = reference.addingTimeInterval(-65 * 60)
        #expect(MCStaleness.level(generatedAt: generatedAt, now: reference) == .flagged)
    }

    @Test func resolvedThresholdValues() {
        #expect(MCStaleness.subduedThreshold == 15 * 60)
        #expect(MCStaleness.flaggedThreshold == 60 * 60)
    }

    @Test func customThresholdsOverrideDefaults() {
        let generatedAt = reference.addingTimeInterval(-5 * 60)
        #expect(
            MCStaleness.level(
                generatedAt: generatedAt,
                now: reference,
                subduedThreshold: 60,
                flaggedThreshold: 120
            ) == .flagged
        )
    }
}
