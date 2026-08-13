import Foundation
import MCDomain

/// Security-scoped bookmark helpers (ADR-0009). The vault is read-only in practice; a
/// Project's optional Source Path is read-write. Bookmark-resolution failure is a first-class,
/// user-visible state — callers must render `BookmarkResolutionState`, never silently show an
/// empty list.
enum BookmarkHelper {
    static func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    static func resolve(_ bookmark: Data?) -> BookmarkResolutionState {
        guard let bookmark else { return .notYetSelected }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return .resolved(url)
        } catch {
            return .resolutionFailed(reason: "\(error)")
        }
    }

    /// Runs `body` with the security-scoped resource accessible, balancing
    /// start/stopAccessingSecurityScopedResource around the call (ADR-0009).
    static func withAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
        let started = url.startAccessingSecurityScopedResource()
        defer { if started { url.stopAccessingSecurityScopedResource() } }
        return try body()
    }
}
