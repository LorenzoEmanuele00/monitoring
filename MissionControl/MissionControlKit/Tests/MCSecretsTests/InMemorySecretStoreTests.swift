import Testing
@testable import MCSecrets
import Foundation

/// `KeychainSecretStore` needs a signed, entitled process (real keychain access group) to
/// exercise meaningfully — that only exists once Xcode builds and signs the app. These tests
/// cover the `SecretStore` contract via `InMemorySecretStore`, which every app-layer caller
/// (Connect Integration flow, polling pipeline) is written against through the protocol, so
/// the contract itself is what matters for unit coverage here.
@Suite struct InMemorySecretStoreTests {
    @Test func storeThenReadReturnsSameBytes() throws {
        let store = InMemorySecretStore()
        let id = UUID()
        let secret = Data("ghp_faketoken".utf8)
        try store.store(secret, for: id)
        #expect(try store.read(for: id) == secret)
    }

    @Test func readMissingReturnsNil() throws {
        let store = InMemorySecretStore()
        #expect(try store.read(for: UUID()) == nil)
    }

    @Test func deleteRemovesSecret() throws {
        let store = InMemorySecretStore()
        let id = UUID()
        try store.store(Data("secret".utf8), for: id)
        try store.delete(for: id)
        #expect(try store.read(for: id) == nil)
    }

    @Test func storeOverwritesExistingValue() throws {
        let store = InMemorySecretStore()
        let id = UUID()
        try store.store(Data("first".utf8), for: id)
        try store.store(Data("second".utf8), for: id)
        #expect(try store.read(for: id) == Data("second".utf8))
    }
}
