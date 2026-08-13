import Foundation

/// App-wide identifiers shared across the app target, the widget extension, and every
/// MissionControlKit module. Centralised here (MCDomain has no dependencies, so every other
/// module can see these) rather than duplicated per-target. Per ADR-0004/0007.
public enum AppGroupConfig {
    /// App Group container identifier. Resolved via
    /// `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`.
    public static let appGroupIdentifier = "group.com.lorenzoemanuele.missioncontrol"

    /// Fixed `kSecAttrService` value for every Keychain item MCSecrets writes (ADR-0007).
    /// The per-Integration UUID is the `kSecAttrAccount`, not part of this string.
    public static let keychainServiceName = "com.lorenzoemanuele.missioncontrol.credentials"

    /// Shared `keychain-access-groups` entitlement value, declared on both the app and the
    /// widget extension targets even though the extension does not read credentials in v1
    /// (ADR-0007). Xcode prefixes this with the resolved Team ID at build time.
    public static let keychainAccessGroup = "com.lorenzoemanuele.missioncontrol.shared"

    /// `os.Logger` subsystem shared by every category across app + extension (ADR-0010).
    public static let loggingSubsystem = "com.lorenzoemanuele.missioncontrol"
}
