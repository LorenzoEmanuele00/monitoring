import Testing
@testable import MCDesignTokens

/// `MCStatusTone` is the design system's own vocabulary (not tied to any BC's domain enum —
/// see the dependency note in `DesignTokens.swift`). Covers the color each tone resolves to,
/// which `MCStatusPill` renders as both a dot and the label color (draft principle: "state is
/// communicated as color + word together, never color alone").
@Suite struct MCStatusToneTests {
    @Test func positiveUsesConnectedColor() {
        #expect(MCStatusTone.positive.color == MCColor.connected)
    }

    @Test func warningUsesDegradedColor() {
        #expect(MCStatusTone.warning.color == MCColor.degraded)
    }

    @Test func negativeUsesErrorColor() {
        #expect(MCStatusTone.negative.color == MCColor.error)
    }

    @Test func runningUsesRunningColor() {
        #expect(MCStatusTone.running.color == MCColor.running)
    }

    @Test func neutralUsesIdleColor() {
        #expect(MCStatusTone.neutral.color == MCColor.idle)
    }
}
