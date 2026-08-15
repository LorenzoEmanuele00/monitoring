import MCDomain
import MCDesignTokens

/// Maps the domain's `IntegrationStatus` to the design system's tone/label vocabulary for the
/// in-app dashboard. Mirrors (deliberately duplicated, not shared) the equivalent mapping in
/// `IntegrationStatusWidget.swift` — the design system stays dependency-free of `MCDomain`
/// (see the note in `MCDesignTokens/DesignTokens.swift`), and the mapping is small enough that
/// keeping one per target beats introducing a shared module for it.
extension IntegrationStatus {
    var pillTone: MCStatusTone {
        switch self {
        case .connected: return .positive
        case .degraded: return .warning
        case .credentialExpired, .disconnected: return .negative
        }
    }

    var pillLabel: String {
        switch self {
        case .connected: return "Connected"
        case .degraded: return "Degraded"
        case .credentialExpired: return "Credential expired"
        case .disconnected: return "Disconnected"
        }
    }
}
