import Foundation
import MCDomain

/// One per `ProviderKind` (ADR-0012). Every adapter treats its provider as rate-limited and
/// flaky (ADR-0008): issues conditional requests, honours `Retry-After`, and classifies
/// failures into transient vs. terminal so the caller (the polling pipeline) can apply the
/// uniform failure policy without knowing provider-specific HTTP semantics.
public protocol ProviderAdapter: Sendable {
    var providerKind: ProviderKind { get }

    /// Run on connect and on each poll cycle (ADR-0012): "401/403 or known-expiry raises
    /// 'Integration credential expired'". Returns normally if the credential is currently
    /// usable; throws a `ProviderAdapterError.credentialExpired`/`.invalidCredential`
    /// otherwise.
    func validateCredential(_ credential: Data) async throws

    /// One poll attempt. `credential` is the raw blob from `SecretStore`; `etag` is the last
    /// conditional-request validator persisted on the Integration (ADR-0008), or nil on a
    /// cold first poll.
    func poll(externalRef: String, credential: Data, etag: String?) async -> PollOutcome
}

public enum ProviderAdapterError: Error, CustomStringConvertible {
    case invalidCredential(reason: String)
    case credentialExpired
    case malformedResponse(reason: String)

    public var description: String {
        switch self {
        case .invalidCredential(let reason): return "Invalid credential: \(reason)"
        case .credentialExpired: return "Credential expired"
        case .malformedResponse(let reason): return "Malformed provider response: \(reason)"
        }
    }
}
