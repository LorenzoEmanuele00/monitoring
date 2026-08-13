import Foundation

/// Which provider a ServiceIntegration talks to. v1 supports exactly these three
/// (ADR-0012); the walking skeleton wires all three for a single Project.
public enum ProviderKind: String, Codable, CaseIterable, Sendable {
    case githubRepository
    case firebaseHosting
    case supabaseProject

    public var displayName: String {
        switch self {
        case .githubRepository: return "GitHub"
        case .firebaseHosting: return "Firebase Hosting"
        case .supabaseProject: return "Supabase"
        }
    }
}

/// Shape of the credential a provider needs, per ADR-0012. Modelled as an enum (not a bare
/// string) so a future OAuth path doesn't reshape this aggregate.
public enum CredentialKind: String, Codable, Sendable {
    case staticToken
    case serviceAccountKey
    case oauthRefreshToken
}

/// Visible connection state (ADR-0008: "providers treated as rate-limited and flaky").
public enum IntegrationStatus: String, Codable, Sendable {
    case connected
    case degraded
    case credentialExpired
    case disconnected
}

/// A Project's attachment to one external provider account/resource. One row in Tier A
/// (`integrations` table). Credential material itself never lives here — only a reference
/// (the Integration's own `id`, used as the Keychain `kSecAttrAccount`) per ADR-0007.
public struct ServiceIntegration: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var projectID: UUID
    public var providerKind: ProviderKind
    public var credentialKind: CredentialKind

    /// Human-readable label, e.g. "LorenzoEmanuele00/mise_pwa".
    public var displayName: String

    /// Provider-specific reference the adapter needs to address the right resource,
    /// e.g. "LorenzoEmanuele00/mise_pwa" for GitHub, a Firebase site ID, a Supabase project ref.
    public var externalRef: String

    public var status: IntegrationStatus
    public var lastAttemptAt: Date?
    public var lastSuccessAt: Date?
    public var lastError: String?

    /// Conditional-request validator persisted per ADR-0008 ("issues conditional requests,
    /// persisted in Tier A, treats 304 as unchanged-still-fresh").
    public var etag: String?

    /// Consecutive hard-failure count driving the per-credential circuit breaker (ADR-0008).
    public var consecutiveFailureCount: Int

    public init(
        id: UUID = UUID(),
        projectID: UUID,
        providerKind: ProviderKind,
        credentialKind: CredentialKind,
        displayName: String,
        externalRef: String,
        status: IntegrationStatus = .disconnected,
        lastAttemptAt: Date? = nil,
        lastSuccessAt: Date? = nil,
        lastError: String? = nil,
        etag: String? = nil,
        consecutiveFailureCount: Int = 0
    ) {
        self.id = id
        self.projectID = projectID
        self.providerKind = providerKind
        self.credentialKind = credentialKind
        self.displayName = displayName
        self.externalRef = externalRef
        self.status = status
        self.lastAttemptAt = lastAttemptAt
        self.lastSuccessAt = lastSuccessAt
        self.lastError = lastError
        self.etag = etag
        self.consecutiveFailureCount = consecutiveFailureCount
    }

    /// Circuit-breaker threshold (ADR-0008: "trips ... after repeated consecutive hard
    /// failures"). Fixed for this spike rather than configurable.
    public static let circuitBreakerThreshold = 5

    public var isCircuitOpen: Bool {
        consecutiveFailureCount >= Self.circuitBreakerThreshold
    }
}
