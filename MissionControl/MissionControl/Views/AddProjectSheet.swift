import SwiftUI
import MCDomain

/// Manual "add project" flow (task's What item 5: "manual 'add project' flow is enough for
/// this spike — Project Registry's discovery-mode open question stays open"). Source path is
/// picked via `.fileImporter` (backed by `NSOpenPanel`), persisted as a security-scoped
/// bookmark (ADR-0009).
struct AddProjectSheet: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var vaultNoteRelativePath = ""
    @State private var isPickingSourceFolder = false
    @State private var pickedSourceURL: URL?
    @State private var pickedSourceBookmark: Data?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            TextField("Project name", text: $name)
            TextField("Vault note path (relative)", text: $vaultNoteRelativePath, prompt: Text("Progetti/Gestione Mezzi.md"))

            HStack {
                Text(pickedSourceURL?.path ?? "No source folder selected")
                    .foregroundStyle(pickedSourceURL == nil ? .secondary : .primary)
                Spacer()
                Button("Choose Folder…") {
                    isPickingSourceFolder = true
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Add") { addProject() }
                    .disabled(name.isEmpty || vaultNoteRelativePath.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 420)
        .fileImporter(
            isPresented: $isPickingSourceFolder,
            allowedContentTypes: [.folder],
            onCompletion: handleFolderPick
        )
    }

    private func handleFolderPick(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // The .fileImporter access grant is only guaranteed open for the duration of this
            // completion handler — the bookmark MUST be created here, wrapped in
            // start/stopAccessingSecurityScopedResource, not deferred to a later Add tap.
            // Deferring it produces NSCocoaErrorDomain Code=256 "Could not open() the item".
            do {
                pickedSourceBookmark = try BookmarkHelper.withAccess(to: url) {
                    try BookmarkHelper.makeBookmark(for: url)
                }
                pickedSourceURL = url
                errorMessage = nil
            } catch {
                errorMessage = "Could not create a security-scoped bookmark: \(error)"
                pickedSourceURL = nil
                pickedSourceBookmark = nil
            }
        case .failure(let error):
            errorMessage = "\(error)"
        }
    }

    private func addProject() {
        let project = Project(
            name: name,
            vaultNoteRelativePath: vaultNoteRelativePath,
            sourcePathBookmark: pickedSourceBookmark
        )
        do {
            try environment.addProject(project)
            dismiss()
        } catch {
            errorMessage = "\(error)"
        }
    }
}
