import SwiftUI

/// The design system's own event vocabulary — like `MCStatusTone`, deliberately not tied to any
/// BC's domain type (see the dependency note in `DesignTokens.swift`). The draft names these
/// four event kinds explicitly (`references/mc-design-system-v1-draft.md` §07) but leaves the
/// exact SF Symbols "to be confirmed"; the symbol names below are this task's resolved v1 choice.
public enum MCEventKind: Sendable, Equatable {
    case deployOK
    case prMerged
    case prOpened
    case buildFailed

    public var color: Color {
        switch self {
        case .deployOK: return MCColor.connected
        case .prMerged: return MCColor.merged
        case .prOpened: return MCColor.running
        case .buildFailed: return MCColor.error
        }
    }

    public var systemImage: String {
        switch self {
        case .deployOK: return "arrow.up.circle.fill"
        case .prMerged: return "arrow.triangle.merge"
        case .prOpened: return "plus.circle.fill"
        case .buildFailed: return "exclamationmark.triangle.fill"
        }
    }
}

/// A single event: glyph + text + relative time, one row, glyph color/icon keyed to
/// `MCEventKind`. Sized to survive a 170pt-wide `systemSmall` widget (draft: "una riga, 22 punti
/// di altezza").
public struct MCEventRow: View {
    private let kind: MCEventKind
    private let text: String
    private let time: Date
    private let now: Date

    public init(kind: MCEventKind, text: String, time: Date, now: Date = Date()) {
        self.kind = kind
        self.text = text
        self.time = time
        self.now = now
    }

    public var body: some View {
        HStack(spacing: MCSpacing.s3) {
            RoundedRectangle(cornerRadius: MCRadius.control)
                .fill(kind.color.opacity(0.2))
                .frame(width: 16, height: 16)
                .overlay {
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(kind.color)
                }
            Text(text)
                .font(MCFont.subheadline)
                .foregroundStyle(MCColor.label)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: MCSpacing.s2)
            Text(time, style: .relative)
                .font(MCFont.monoData)
                .foregroundStyle(MCColor.tertiaryLabel)
        }
        .padding(.vertical, MCSpacing.s2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(MCColor.separator)
                .frame(height: 0.5)
        }
    }
}

#Preview("Event row — light") {
    MCEventRowPreviewStack()
        .preferredColorScheme(.light)
}

#Preview("Event row — dark") {
    MCEventRowPreviewStack()
        .preferredColorScheme(.dark)
}

private struct MCEventRowPreviewStack: View {
    private let now = Date()

    var body: some View {
        VStack(spacing: 0) {
            MCEventRow(
                kind: .deployOK,
                text: "Deploy su produzione completato",
                time: now.addingTimeInterval(-14 * 60),
                now: now
            )
            MCEventRow(
                kind: .prMerged,
                text: "PR #41 unita in master",
                time: now.addingTimeInterval(-26 * 60),
                now: now
            )
            MCEventRow(
                kind: .prOpened,
                text: "PR #42 aperta da lorenzo",
                time: now.addingTimeInterval(-3 * 3600),
                now: now
            )
            MCEventRow(
                kind: .buildFailed,
                text: "Build fallita: test suite mezzi",
                time: now.addingTimeInterval(-5 * 3600),
                now: now
            )
        }
        .padding()
        .frame(width: 320)
        .background(MCColor.raisedBackground)
    }
}
