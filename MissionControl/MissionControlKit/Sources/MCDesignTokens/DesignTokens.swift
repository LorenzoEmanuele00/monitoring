import SwiftUI
import AppKit

/// Shared visual tokens for the app + widget extension (ADR-0004: the extension links only
/// MCSnapshot + MCDesignTokens). This is the design-system BC's token set
/// (`design-system-001-styleguide`) — color, spacing, radius, and type scale, validated against
/// both the in-app dashboard and the Desktop Widget's small/medium families in light and dark.
///
/// Deliberately dependency-free (no `MCDomain` import): the design system knows nothing about
/// domain types like `IntegrationStatus`. Call sites map their own domain state to `MCStatusTone`
/// / labels — see `MenuBarContentView` and `IntegrationRow` in the app target, and
/// `IntegrationStatusWidgetView` in the widget extension.

// MARK: - Color

/// Semantic color tokens. Every token maps to a real AppKit semantic/system color (never a
/// hand-maintained hex pair) so light/dark — and the user's own accent-color choice — come for
/// free from macOS, per the design draft's stated principle (see BC README).
public enum MCColor {
    // MARK: State tones
    public static let connected = Color(nsColor: .systemGreen)
    public static let degraded = Color(nsColor: .systemOrange)
    public static let error = Color(nsColor: .systemRed)
    public static let running = Color(nsColor: .systemBlue)
    public static let idle = Color(nsColor: .systemGray)
    public static let accent = Color(nsColor: .controlAccentColor)

    /// Added for `MCEventRow`'s "PR merged" event glyph (`design-system-q9vhm`) — none of the
    /// existing state tones fit a merge event, and the draft's sample data uses a purple swatch
    /// for it, so this extends the token set with one more real AppKit semantic color rather
    /// than hand-maintaining a hex pair.
    public static let merged = Color(nsColor: .systemPurple)

    /// Pre-styleguide aliases, kept so the walking skeleton's existing call sites
    /// (`MenuBarContentView`, `IntegrationStatusWidgetView`) keep compiling unchanged where they
    /// haven't yet been migrated to `MCStatusPill`/`MCStalenessIndicator`.
    public static let disconnected = error
    public static let staleSubdued = Color(nsColor: .secondaryLabelColor)
    public static let staleFlagged = degraded

    // MARK: Surfaces / labels
    public static let windowBackground = Color(nsColor: .windowBackgroundColor)
    public static let contentBackground = Color(nsColor: .controlBackgroundColor)
    public static let raisedBackground = Color(nsColor: .underPageBackgroundColor)
    public static let separator = Color(nsColor: .separatorColor)
    public static let label = Color(nsColor: .labelColor)
    public static let secondaryLabel = Color(nsColor: .secondaryLabelColor)
    public static let tertiaryLabel = Color(nsColor: .tertiaryLabelColor)
}

// MARK: - Spacing

/// 2/4/8/12/16/24/32 spacing scale (draft direction, unchanged during validation).
public enum MCSpacing {
    public static let s1: CGFloat = 2
    public static let s2: CGFloat = 4
    public static let s3: CGFloat = 8
    public static let s4: CGFloat = 12
    public static let s5: CGFloat = 16
    public static let s6: CGFloat = 24
    public static let s7: CGFloat = 32
}

// MARK: - Corner radii

/// Draft's corner-radius table. `pill` is kept for reference/parity with the source spec, but
/// pill-shaped components (`MCStatusPill`) use `Capsule()` directly rather than this fixed
/// radius, so they stay a true pill at any height.
public enum MCRadius {
    public static let pill: CGFloat = 4
    public static let control: CGFloat = 6
    public static let tile: CGFloat = 8
    public static let card: CGFloat = 10
    public static let widget: CGFloat = 18
}

// MARK: - Typography

/// SF Pro / SF Mono system stack only — no custom typeface (draft direction). Sizes/weights
/// match the draft's exported type scale, trimmed to the entries this task's component set
/// actually uses; add more as later components need them.
public enum MCFont {
    public static let title1 = Font.system(size: 22, weight: .bold)
    public static let title3 = Font.system(size: 15, weight: .semibold)
    public static let headline = Font.system(size: 13, weight: .semibold)
    public static let body = Font.system(size: 13, weight: .regular)
    public static let subheadline = Font.system(size: 11, weight: .regular)
    public static let caption = Font.system(size: 10, weight: .regular)
    public static let monoNumeric = Font.system(size: 20, weight: .regular, design: .monospaced)
    public static let monoData = Font.system(size: 11, weight: .regular, design: .monospaced)
    public static let monoLabel = Font.system(size: 10, weight: .medium, design: .monospaced)

    /// `0.08em` tracking on `monoLabel`, per the draft spec (10pt * 0.08 = 0.8pt).
    public static let monoLabelTracking: CGFloat = 0.8
}

// MARK: - Staleness

/// Freshness thresholds and level classification (ADR-0008 rule 2: "staleness is always
/// visible"). ADR-0008 explicitly left the concrete figures to Widgets/Design System
/// ("suggested: subdued past ~30 min, flagged past ~2 h" — a placeholder, not a fixed decision).
///
/// **Resolved during `design-system-001-styleguide`:** the design draft's tighter guess
/// (subdued past 15 min, flagged past 60 min) was adopted over the ADR-0008 placeholder — see
/// ADR-0015 and the design-system README for the full rationale. Thresholds stay overridable per
/// call site (`level(generatedAt:now:subduedThreshold:flaggedThreshold:)`) since the draft
/// exposed them as configurable props (`warnMinutes`/`staleMinutes`) rather than fixed constants.
public enum MCStaleness {
    public static let subduedThreshold: TimeInterval = 15 * 60
    public static let flaggedThreshold: TimeInterval = 60 * 60

    public enum Level: Sendable, Equatable {
        case fresh
        case subdued
        case flagged
    }

    public static func level(
        generatedAt: Date,
        now: Date = Date(),
        subduedThreshold: TimeInterval = subduedThreshold,
        flaggedThreshold: TimeInterval = flaggedThreshold
    ) -> Level {
        let age = now.timeIntervalSince(generatedAt)
        if age >= flaggedThreshold { return .flagged }
        if age >= subduedThreshold { return .subdued }
        return .fresh
    }

    public static func color(for level: Level) -> Color {
        switch level {
        case .fresh: return .primary
        case .subdued: return MCColor.staleSubdued
        case .flagged: return MCColor.staleFlagged
        }
    }
}
