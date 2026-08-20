import Foundation

/// A registered Project (Project Registry BC's aggregate, modelled here in MCDomain because
/// this walking skeleton has no dedicated Project Registry code yet — the discovery-mode open
/// question on `project-registry/README.md` stays open per the task's scope). One Project this
/// spike: mise_pwa.
public struct Project: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String

    /// A Project's optional, unparsed pointer to its Obsidian note (ADR-0014): a vault-relative
    /// note path, a full `obsidian://` URI, or a plain filesystem path — never validated beyond
    /// "non-empty if present", never read or parsed. Drives exactly one behavior, the
    /// "Open in Obsidian" action (see `obsidianOpenURL`). Needs no security-scoped bookmark and
    /// no vault filesystem access of any kind.
    public var obsidianNoteLink: String?

    /// Security-scoped bookmark (ADR-0009) to the Project's local source folder on disk.
    /// `nil` until the user picks a folder via NSOpenPanel/.fileImporter.
    public var sourcePathBookmark: Data?

    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        obsidianNoteLink: String? = nil,
        sourcePathBookmark: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.obsidianNoteLink = obsidianNoteLink
        self.sourcePathBookmark = sourcePathBookmark
        self.createdAt = createdAt
    }
}

public extension Project {
    /// The `obsidian://` URL the "Open in Obsidian" action hands to
    /// `NSWorkspace.shared.open(_:)` (ADR-0014), built from `obsidianNoteLink` with no parsing
    /// or interpretation of its contents beyond URL-encoding it into the `path` query item.
    /// `nil` when there's no link set (or it's empty), which is exactly when the UI should show
    /// no "Open in Obsidian" button at all.
    var obsidianOpenURL: URL? {
        guard let link = obsidianNoteLink, !link.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "obsidian"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "path", value: link)]
        return components.url
    }
}

/// Security-scoped bookmark resolution outcome (ADR-0009: "bookmark-resolution failure is a
/// first-class, user-visible state, never presents as an empty project list").
public enum BookmarkResolutionState: Equatable, Sendable {
    case resolved(URL)
    case notYetSelected
    case resolutionFailed(reason: String)
}
