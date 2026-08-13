import Foundation

/// Test/preview double for `SecretStore`. `KeychainSecretStore` needs a signed, entitled
/// process (a real keychain access group) to function — that only exists once the app is
/// built and code-signed by Xcode, not under a bare `swift test` invocation. This actor
/// gives `MCProviders`/app-layer logic something real to run its own unit tests against
/// without touching the Keychain. `SecretStore`'s requirements are synchronous (matching
/// `KeychainSecretStore`'s synchronous Security-framework calls), so this uses a lock rather
/// than an actor.
public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [UUID: Data] = [:]

    public init() {}

    public func store(_ data: Data, for id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        storage[id] = data
    }

    public func read(for id: UUID) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage[id]
    }

    public func delete(for id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: id)
    }
}
