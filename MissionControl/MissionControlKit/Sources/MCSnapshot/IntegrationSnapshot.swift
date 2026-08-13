import Foundation
import MCDomain

/// Render-ready, widget-safe DTO — Tier B (ADR-0005). No images, no secrets, but DOES carry
/// `generatedAt` for staleness display (ADR-0008). One file per Integration under
/// `<group>/Snapshots/<integrationID>.json`.
public struct IntegrationSnapshot: Codable, Equatable, Sendable {
    public var integrationID: UUID
    public var projectName: String
    public var providerKind: ProviderKind
    public var displayName: String
    public var status: IntegrationStatus

    /// Last successfully-projected payload. Stays populated across failed polls
    /// (ADR-0008: "a failed refresh never overwrites/clears a good snapshot").
    public var payload: IntegrationPayload?

    /// When `payload` was generated. Drives every staleness indicator.
    public var generatedAt: Date

    public var lastAttemptAt: Date?
    public var lastError: String?

    public init(
        integrationID: UUID,
        projectName: String,
        providerKind: ProviderKind,
        displayName: String,
        status: IntegrationStatus,
        payload: IntegrationPayload?,
        generatedAt: Date,
        lastAttemptAt: Date?,
        lastError: String?
    ) {
        self.integrationID = integrationID
        self.projectName = projectName
        self.providerKind = providerKind
        self.displayName = displayName
        self.status = status
        self.payload = payload
        self.generatedAt = generatedAt
        self.lastAttemptAt = lastAttemptAt
        self.lastError = lastError
    }
}

/// `<group>/Snapshots/manifest.json` — the widget extension's entry point: which snapshots
/// exist, and when the last poll cycle ran at all (independent of any single Integration's
/// own `generatedAt`).
public struct SnapshotManifest: Codable, Equatable, Sendable {
    public var integrationIDs: [UUID]
    public var generatedAt: Date

    public init(integrationIDs: [UUID], generatedAt: Date) {
        self.integrationIDs = integrationIDs
        self.generatedAt = generatedAt
    }
}
