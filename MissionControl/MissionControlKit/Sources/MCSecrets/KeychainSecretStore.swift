import Foundation
import Security
import MCDomain

/// Data-protection-keychain-backed `SecretStore` (ADR-0007). Every item:
/// - `kSecClass` = `kSecClassGenericPassword`
/// - `kSecAttrService` = fixed app-wide service string
/// - `kSecAttrAccount` = the Integration's UUID
/// - `kSecAttrAccessible` = `kSecAttrAccessibleAfterFirstUnlock`
/// - `kSecAttrAccessGroup` = shared access group (declared on app + extension entitlements,
///   provisioned from day one even though the extension doesn't read credentials in v1)
/// - `kSecUseDataProtectionKeychain` = true
public struct KeychainSecretStore: SecretStore {
    private let service: String
    private let accessGroup: String

    public init(
        service: String = AppGroupConfig.keychainServiceName,
        accessGroup: String = AppGroupConfig.keychainAccessGroup
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    public func store(_ data: Data, for id: UUID) throws {
        let account = id.uuidString
        var query = baseQuery(account: account)

        // Try update first; if nothing exists yet, add.
        let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if updateStatus == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SecretStoreError.unhandledStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw SecretStoreError.unhandledStatus(updateStatus)
        }
    }

    public func read(for id: UUID) throws -> Data? {
        var query = baseQuery(account: id.uuidString)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SecretStoreError.unhandledStatus(status)
        }
        return result as? Data
    }

    public func delete(for id: UUID) throws {
        let query = baseQuery(account: id.uuidString)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.unhandledStatus(status)
        }
    }
}
