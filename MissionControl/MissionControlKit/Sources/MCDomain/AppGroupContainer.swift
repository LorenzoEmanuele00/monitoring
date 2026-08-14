import Foundation

/// Resolves the shared App Group container both the app and the widget extension read/write
/// (ADR-0004/0005). Lives in MCSnapshot (not MCDomain) because it does filesystem I/O and is
/// needed by both Tier A (MCPersistence, app-only) and Tier B (MCSnapshot, app + extension).
public enum AppGroupContainer {
    public enum ContainerError: Error, CustomStringConvertible {
        case containerUnavailable(String)
        public var description: String {
            switch self {
            case .containerUnavailable(let id):
                return "App Group container unavailable for identifier '\(id)'. " +
                    "Check the App Group entitlement is present on this target."
            }
        }
    }

    /// Root of the App Group container. Throws rather than force-unwrapping: a missing
    /// entitlement (misconfigured target, or running outside a signed context) must surface
    /// as a diagnosable error, not a crash.
    public static func rootURL(appGroupIdentifier: String) throws -> URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw ContainerError.containerUnavailable(appGroupIdentifier)
        }
        return url
    }

    /// Tier A's SQLite database location (ADR-0005): `<group>/Library/Application Support/`.
    public static func applicationSupportURL(appGroupIdentifier: String) throws -> URL {
        let root = try rootURL(appGroupIdentifier: appGroupIdentifier)
        let dir = root.appendingPathComponent("Library/Application Support", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Tier B's snapshot directory (ADR-0005): `<group>/Snapshots/`. Deleting this directory
    /// must be safe and self-healing on next poll — callers should never assume it persists.
    public static func snapshotsURL(appGroupIdentifier: String) throws -> URL {
        let root = try rootURL(appGroupIdentifier: appGroupIdentifier)
        let dir = root.appendingPathComponent("Snapshots", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
