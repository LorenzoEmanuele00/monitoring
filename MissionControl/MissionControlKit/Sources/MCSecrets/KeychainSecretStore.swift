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

    /// `AppGroupConfig.keychainAccessGroup` is the bare group name from `project.yml`; the
    /// entitlements files prefix it with `$(AppIdentifierPrefix)` (the real Team ID) at build
    /// time, a substitution Swift code has no access to. Passing the bare name as
    /// `kSecAttrAccessGroup` therefore never matches what's actually entitled, and every
    /// keychain call fails with `errSecMissingEntitlement` (-34018). Resolve the real prefix
    /// once at runtime via the standard trick: write a throwaway item with no access group
    /// specified, read back the default access group the OS assigned it (`"<TEAMID>.<bundle
    /// id>"`), and take the `<TEAMID>.` prefix from that.
    private static let resolvedAccessGroupPrefix: String? = {
        let probeQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.lorenzoemanuele.missioncontrol.accessGroupProbe",
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnAttributes as String: true,
        ]
        var result: AnyObject?
        var status = SecItemCopyMatching(probeQuery as CFDictionary, &result)
        if status == errSecItemNotFound {
            var addQuery = probeQuery
            addQuery[kSecValueData as String] = Data()
            addQuery[kSecReturnAttributes as String] = true
            status = SecItemAdd(addQuery as CFDictionary, &result)
        }
        guard status == errSecSuccess,
              let attributes = result as? [String: Any],
              let defaultGroup = attributes[kSecAttrAccessGroup as String] as? String,
              let dotIndex = defaultGroup.firstIndex(of: ".")
        else { return nil }
        return String(defaultGroup[..<dotIndex]) + "."
    }()

    public init(
        service: String = AppGroupConfig.keychainServiceName,
        accessGroup: String = AppGroupConfig.keychainAccessGroup
    ) {
        self.service = service
        self.accessGroup = (Self.resolvedAccessGroupPrefix ?? "") + accessGroup
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
