import SwiftUI

/// Consumption-against-limit tile: label, value, limit, percentage, and a contextual note (e.g.
/// "reset fra 12 giorni", "soglia 80% superata") — the draft's stated purpose is that the bar
/// alone should communicate remaining headroom at a glance. Matches the draft's 2-up grid tile
/// shape (`references/mc-design-system-v1-draft.md` §05).
public struct MCUsageMetricTile: View {
    /// Consumption exceeds this fraction of the limit -> the bar switches to the `warning`
    /// (degraded) tone, per the draft spec ("bar color switches to degraded past 80%") and its
    /// sample data (Bandwidth at 84% -> degraded bar + "soglia 80% superata" note).
    public static let degradedThreshold: Double = 0.8

    /// Pure, view-independent so `MCUsageMetricTileTests` can cover the threshold rule without
    /// rendering SwiftUI (mirrors `MCStaleness.level` / `MCStatusTone`'s testable-logic pattern).
    public static func barTone(forFraction fraction: Double) -> MCStatusTone {
        fraction > degradedThreshold ? .warning : .positive
    }

    private let label: String
    private let value: String
    private let limit: String
    private let percentText: String
    private let fraction: Double
    private let note: String

    public init(
        label: String,
        value: String,
        limit: String,
        percentText: String,
        fraction: Double,
        note: String
    ) {
        self.label = label
        self.value = value
        self.limit = limit
        self.percentText = percentText
        self.fraction = fraction
        self.note = note
    }

    private var barTone: MCStatusTone { Self.barTone(forFraction: fraction) }

    public var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(MCFont.subheadline)
                    .foregroundStyle(MCColor.secondaryLabel)
                Spacer()
                Text(percentText)
                    .font(MCFont.monoData)
                    .foregroundStyle(MCColor.tertiaryLabel)
            }
            HStack(alignment: .lastTextBaseline, spacing: MCSpacing.s2) {
                Text(value)
                    .font(MCFont.monoNumeric)
                    .foregroundStyle(MCColor.label)
                Text(limit)
                    .font(MCFont.monoData)
                    .foregroundStyle(MCColor.tertiaryLabel)
            }
            bar
            Text(note)
                .font(MCFont.caption)
                .foregroundStyle(MCColor.secondaryLabel)
                .lineLimit(1)
        }
        .padding(MCSpacing.s4)
        .background(MCColor.raisedBackground, in: RoundedRectangle(cornerRadius: MCRadius.tile))
    }

    private var bar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(MCColor.separator.opacity(0.6))
                Capsule()
                    .fill(barTone.color)
                    .frame(width: geometry.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 5)
    }
}

#Preview("Usage metric tile — light") {
    MCUsageMetricTilePreviewGrid()
        .preferredColorScheme(.light)
}

#Preview("Usage metric tile — dark") {
    MCUsageMetricTilePreviewGrid()
        .preferredColorScheme(.dark)
}

private struct MCUsageMetricTilePreviewGrid: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MCSpacing.s4) {
            MCUsageMetricTile(
                label: "Hosting",
                value: "6,2",
                limit: "/ 10 GB",
                percentText: "62%",
                fraction: 0.62,
                note: "reset fra 12 giorni"
            )
            MCUsageMetricTile(
                label: "DB rows",
                value: "1.284",
                limit: "/ 5.000",
                percentText: "26%",
                fraction: 0.26,
                note: "+42 nelle 24h"
            )
            MCUsageMetricTile(
                label: "Bandwidth",
                value: "8,4",
                limit: "/ 10 GB",
                percentText: "84%",
                fraction: 0.84,
                note: "soglia 80% superata"
            )
            MCUsageMetricTile(
                label: "Auth MAU",
                value: "37",
                limit: "/ 50.000",
                percentText: "4%",
                fraction: 0.04,
                note: "piano free"
            )
        }
        .padding()
        .frame(width: 320)
        .background(MCColor.windowBackground)
    }
}
