import Testing
@testable import MCDomain
import Foundation

@Suite struct ProjectTests {
    @Test func obsidianOpenURLIsNilWhenLinkIsNotSet() {
        let project = Project(name: "mise_pwa")
        #expect(project.obsidianNoteLink == nil)
        #expect(project.obsidianOpenURL == nil)
    }

    @Test func obsidianOpenURLIsNilWhenLinkIsEmptyString() {
        let project = Project(name: "mise_pwa", obsidianNoteLink: "")
        #expect(project.obsidianOpenURL == nil)
    }

    @Test func obsidianOpenURLBuildsWellFormedObsidianSchemeURL() {
        let project = Project(name: "mise_pwa", obsidianNoteLink: "Progetti/Gestione Mezzi.md")
        let url = project.obsidianOpenURL
        #expect(url?.scheme == "obsidian")
        #expect(url?.host == "open")
        #expect(url?.absoluteString == "obsidian://open?path=Progetti/Gestione%20Mezzi.md")
    }

    @Test func obsidianNoteLinkRoundTripsUnchanged() throws {
        let link = "obsidian://open?vault=Notes&file=Progetti%2FGestione%20Mezzi"
        let project = Project(name: "mise_pwa", obsidianNoteLink: link)
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        #expect(decoded.obsidianNoteLink == link)
    }
}
