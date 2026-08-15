import SwiftUI

/// Small sparkline-style area chart: normalized samples rendered as a filled area + line, an
/// optional dashed threshold line, and an hour-tick axis underneath — the draft's "one shape for
/// time" chart (`references/mc-design-system-v1-draft.md` §06, area-chart variant only; the
/// column/stacked-bar variants in that section aren't part of this task's spec).
public struct MCUsageGraph: View {
    private let label: String
    private let value: String
    private let unit: String
    /// Chronological samples normalized to `0...1` (fraction of the chart's vertical range).
    private let samples: [Double]
    /// Normalized `0...1` position of the threshold line, or `nil` to omit it.
    private let thresholdFraction: Double?
    private let hourTicks: [String]

    public init(
        label: String,
        value: String,
        unit: String,
        samples: [Double],
        thresholdFraction: Double? = nil,
        hourTicks: [String] = []
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.samples = samples
        self.thresholdFraction = thresholdFraction
        self.hourTicks = hourTicks
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.s3) {
            VStack(alignment: .leading, spacing: MCSpacing.s1) {
                Text(label)
                    .font(MCFont.subheadline)
                    .foregroundStyle(MCColor.secondaryLabel)
                HStack(alignment: .lastTextBaseline, spacing: MCSpacing.s2) {
                    Text(value)
                        .font(MCFont.monoNumeric)
                        .foregroundStyle(MCColor.label)
                    Text(unit)
                        .font(MCFont.monoData)
                        .foregroundStyle(MCColor.tertiaryLabel)
                }
            }
            chart
            if !hourTicks.isEmpty {
                HStack {
                    ForEach(Array(hourTicks.enumerated()), id: \.offset) { _, tick in
                        Text(tick)
                            .font(MCFont.monoLabel)
                            .foregroundStyle(MCColor.tertiaryLabel)
                        if tick != hourTicks.last { Spacer() }
                    }
                }
            }
        }
        .padding(MCSpacing.s4)
        .background(MCColor.raisedBackground, in: RoundedRectangle(cornerRadius: MCRadius.tile))
    }

    private var chart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            areaPath(width: width, height: height)
                .fill(MCColor.accent.opacity(0.2))
            linePath(width: width, height: height)
                .stroke(MCColor.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            if let thresholdFraction {
                thresholdPath(width: width, height: height, fraction: thresholdFraction)
                    .stroke(MCColor.degraded, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .frame(height: 56)
    }

    private func points(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard samples.count > 1 else { return [] }
        let stepX = width / CGFloat(samples.count - 1)
        return samples.enumerated().map { index, sample in
            CGPoint(x: CGFloat(index) * stepX, y: height * (1 - CGFloat(min(max(sample, 0), 1))))
        }
    }

    private func linePath(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            let pts = points(width: width, height: height)
            guard let first = pts.first else { return }
            path.move(to: first)
            for point in pts.dropFirst() { path.addLine(to: point) }
        }
    }

    private func areaPath(width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            let pts = points(width: width, height: height)
            guard let first = pts.first, let last = pts.last else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            for point in pts { path.addLine(to: point) }
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }

    private func thresholdPath(width: CGFloat, height: CGFloat, fraction: Double) -> Path {
        Path { path in
            let y = height * (1 - CGFloat(min(max(fraction, 0), 1)))
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
    }
}

#Preview("Usage graph — light") {
    MCUsageGraphPreviewStack()
        .preferredColorScheme(.light)
}

#Preview("Usage graph — dark") {
    MCUsageGraphPreviewStack()
        .preferredColorScheme(.dark)
}

private struct MCUsageGraphPreviewStack: View {
    private let sampleTraffic: [Double] = [
        0.2, 0.25, 0.22, 0.3, 0.42, 0.55, 0.68, 0.9, 0.75, 0.6, 0.5, 0.45,
        0.4, 0.38, 0.42, 0.5, 0.6, 0.72, 0.65, 0.5, 0.4, 0.32, 0.28, 0.24,
    ]

    var body: some View {
        VStack(spacing: MCSpacing.s4) {
            MCUsageGraph(
                label: "Traffico in uscita",
                value: "8,4",
                unit: "GB / 24h",
                samples: sampleTraffic,
                thresholdFraction: 0.85,
                hourTicks: ["00", "06", "12", "18", "24"]
            )
        }
        .padding()
        .frame(width: 320)
        .background(MCColor.windowBackground)
    }
}
