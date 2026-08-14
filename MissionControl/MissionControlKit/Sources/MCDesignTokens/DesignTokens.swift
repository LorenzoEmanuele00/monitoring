import SwiftUI

/// Minimal shared visual tokens for the app + widget extension (ADR-0004: the extension links
/// only MCSnapshot + MCDesignTokens). Intentionally thin for this walking skeleton — the
/// design-system BC's fuller token/component reference is a separate, later concern.
public enum MCColor {
    public static let connected = Color.green
    public static let degraded = Color.orange
    public static let disconnected = Color.red
    public static let staleSubdued = Color.secondary
    public static let staleFlagged = Color.orange
}

public enum MCStaleness {
    /// ADR-0008: "degrades visibly past a threshold (subdued ~30min, flagged ~2h)".
    public static let subduedThreshold: TimeInterval = 30 * 60
    public static let flaggedThreshold: TimeInterval = 2 * 60 * 60

    public enum Level {
        case fresh
        case subdued
        case flagged
    }

    public static func level(generatedAt: Date, now: Date = Date()) -> Level {
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
