import Foundation

/// A registered Project (Project Registry BC's aggregate, modelled here in MCDomain because
/// this walking skeleton has no dedicated Project Registry code yet — the discovery-mode open
/// question on `project-registry/README.md` stays open per the task's scope). One Project this
/// spike: mise_pwa.
public struct Project: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String

    /// Path of the Project's note inside the Obsidian vault, relative to the vault root
    /// (e.g. "Progetti/Gestione Mezzi.md"). The vault root itself is a security-scoped
    /// bookmark, not stored per-Project.
    public var vaultNoteRelativePath: String

    /// Security-scoped bookmark (ADR-0009) to the Project's local source folder on disk.
    /// `nil` until the user picks a folder via NSOpenPanel/.fileImporter.
    public var sourcePathBookmark: Data?

    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        vaultNoteRelativePath: String,
        sourcePathBookmark: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.vaultNoteRelativePath = vaultNoteRelativePath
        self.sourcePathBookmark = sourcePathBookmark
        self.createdAt = createdAt
    }
}

/// Security-scoped bookmark resolution outcome (ADR-0009: "bookmark-resolution failure is a
/// first-class, user-visible state, never presents as an empty project list").
public enum BookmarkResolutionState: Equatable, Sendable {
    case resolved(URL)
    case notYetSelected
    case resolutionFailed(reason: String)
}
