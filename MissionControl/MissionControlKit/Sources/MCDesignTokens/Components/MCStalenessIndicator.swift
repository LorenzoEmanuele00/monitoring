import SwiftUI

/// Renders `generatedAt` as relative time plus a dot whose shape/color encodes
/// `MCStaleness.Level` (ADR-0008 rule 2 + the resolved thresholds — see `DesignTokens.swift`).
/// The last known value is always shown alongside this indicator, never an empty placeholder
/// (draft direction) — this view only renders the freshness signal, callers keep showing their
/// last-good payload regardless of level.
public struct MCStalenessIndicator: View {
    private let generatedAt: Date
    private let now: Date
    private let subduedThreshold: TimeInterval
    private let flaggedThreshold: TimeInterval

    public init(
        generatedAt: Date,
        now: Date = Date(),
        subduedThreshold: TimeInterval = MCStaleness.subduedThreshold,
        flaggedThreshold: TimeInterval = MCStaleness.flaggedThreshold
    ) {
        self.generatedAt = generatedAt
        self.now = now
        self.subduedThreshold = subduedThreshold
        self.flaggedThreshold = flaggedThreshold
    }

    private var level: MCStaleness.Level {
        MCStaleness.level(
            generatedAt: generatedAt,
            now: now,
            subduedThreshold: subduedThreshold,
            flaggedThreshold: flaggedThreshold
        )
    }

    public var body: some View {
        HStack(spacing: MCSpacing.s2) {
            dot
            Text(generatedAt, style: .relative)
                .font(MCFont.subheadline)
                .foregroundStyle(MCStaleness.color(for: level))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var dot: some View {
        switch level {
        case .fresh:
            Circle()
                .fill(MCColor.connected)
                .frame(width: 6, height: 6)
        case .subdued:
            Circle()
                .fill(MCColor.degraded)
                .frame(width: 6, height: 6)
        case .flagged:
            Circle()
                .strokeBorder(MCColor.tertiaryLabel, lineWidth: 1)
                .frame(width: 6, height: 6)
        }
    }
}

#Preview("Staleness indicator — light") {
    MCStalenessIndicatorPreviewGrid()
        .preferredColorScheme(.light)
}

#Preview("Staleness indicator — dark") {
    MCStalenessIndicatorPreviewGrid()
        .preferredColorScheme(.dark)
}

private struct MCStalenessIndicatorPreviewGrid: View {
    private let now = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.s3) {
            MCStalenessIndicator(generatedAt: now.addingTimeInterval(-5 * 60), now: now) // fresh
            MCStalenessIndicator(generatedAt: now.addingTimeInterval(-20 * 60), now: now) // subdued
            MCStalenessIndicator(generatedAt: now.addingTimeInterval(-90 * 60), now: now) // flagged
        }
        .padding()
    }
}
