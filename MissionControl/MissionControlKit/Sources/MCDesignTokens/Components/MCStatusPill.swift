import SwiftUI

/// The design system's own status vocabulary — deliberately not `IntegrationStatus` or any
/// other BC's domain enum (see the dependency note in `DesignTokens.swift`). Call sites map
/// their domain state to a tone + label, e.g. `IntegrationStatus.connected -> (.positive,
/// "Connected")`.
public enum MCStatusTone: Sendable, Equatable {
    case positive
    case warning
    case negative
    case running
    case neutral

    public var color: Color {
        switch self {
        case .positive: return MCColor.connected
        case .warning: return MCColor.degraded
        case .negative: return MCColor.error
        case .running: return MCColor.running
        case .neutral: return MCColor.idle
        }
    }
}

/// A compact status pill: colored dot + word, matching the draft's stated principle that state
/// is always communicated as color *and* word together, never color alone. Sized to survive a
/// 170pt-wide `systemSmall` widget.
public struct MCStatusPill: View {
    private let label: String
    private let tone: MCStatusTone

    public init(_ label: String, tone: MCStatusTone) {
        self.label = label
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: MCSpacing.s2) {
            Circle()
                .fill(tone.color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(MCFont.subheadline)
                .foregroundStyle(tone.color)
                .lineLimit(1)
        }
        .padding(.horizontal, MCSpacing.s3)
        .padding(.vertical, MCSpacing.s1)
        .background(tone.color.opacity(0.15), in: Capsule())
    }
}

#Preview("Status pill — light") {
    MCStatusPillPreviewGrid()
        .preferredColorScheme(.light)
}

#Preview("Status pill — dark") {
    MCStatusPillPreviewGrid()
        .preferredColorScheme(.dark)
}

private struct MCStatusPillPreviewGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.s3) {
            MCStatusPill("Connected", tone: .positive)
            MCStatusPill("Degraded", tone: .warning)
            MCStatusPill("Disconnected", tone: .negative)
            MCStatusPill("Deploy in progress", tone: .running)
            MCStatusPill("Not configured", tone: .neutral)
        }
        .padding()
    }
}
