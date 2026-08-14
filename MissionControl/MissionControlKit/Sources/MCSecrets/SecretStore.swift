import Foundation

/// Narrow, provider-agnostic credential store (ADR-0007). Interpreting the opaque `Data`
/// blob (a raw token vs. a JSON service-account key) is the provider adapter's job, not
/// this protocol's.
public protocol SecretStore: Sendable {
    func store(_ data: Data, for id: UUID) throws
    func read(for id: UUID) throws -> Data?
    func delete(for id: UUID) throws
}

public enum SecretStoreError: Error, CustomStringConvertible {
    case unhandledStatus(OSStatus)

    public var description: String {
        switch self {
        case .unhandledStatus(let status):
            // Deliberately no credential material in this description (ADR-0007: "never
            // enter os_log", the same discipline applies to any error text).
            return "Keychain operation failed with status \(status)."
        }
    }
}
