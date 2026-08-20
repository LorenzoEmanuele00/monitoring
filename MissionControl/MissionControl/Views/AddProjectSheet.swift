import SwiftUI
import MCDomain
import MCDesignTokens

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
        AddProjectSheetContent(
            name: $name,
            vaultNoteRelativePath: $vaultNoteRelativePath,
            pickedSourceURL: pickedSourceURL,
            errorMessage: errorMessage,
            onChooseFolder: { isPickingSourceFolder = true },
            onCancel: { dismiss() },
            onAdd: addProject
        )
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

/// The sheet's visual content, split out from `AddProjectSheet` so it can be previewed without
/// bootstrapping `AppEnvironment`'s real Tier A database/Keychain — mirrors the
/// `MenuBarPreviewContent` split in `ContentView.swift`.
private struct AddProjectSheetContent: View {
    @Binding var name: String
    @Binding var vaultNoteRelativePath: String
    let pickedSourceURL: URL?
    let errorMessage: String?
    let onChooseFolder: () -> Void
    let onCancel: () -> Void
    let onAdd: () -> Void

    var body: some View {
        Form {
            Section("New Project") {
                TextField("Project name", text: $name)
                    .font(MCFont.body)
                TextField(
                    "Vault note path (relative)",
                    text: $vaultNoteRelativePath,
                    prompt: Text("Progetti/Gestione Mezzi.md")
                )
                .font(MCFont.body)

                HStack(spacing: MCSpacing.s3) {
                    Text(pickedSourceURL?.path ?? "No source folder selected")
                        .font(MCFont.body)
                        .foregroundStyle(pickedSourceURL == nil ? MCColor.secondaryLabel : MCColor.label)
                    Spacer()
                    Button("Choose Folder…", action: onChooseFolder)
                        .font(MCFont.body)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(MCFont.subheadline)
                    .foregroundStyle(MCColor.error)
            }

            HStack(spacing: MCSpacing.s4) {
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                Button("Add", action: onAdd)
                    .disabled(name.isEmpty || vaultNoteRelativePath.isEmpty)
            }
        }
        .padding(MCSpacing.s5)
        .frame(minWidth: 420)
    }
}

#Preview("Add Project — light") {
    AddProjectSheetPreviewContent()
        .preferredColorScheme(.light)
}

#Preview("Add Project — dark") {
    AddProjectSheetPreviewContent()
        .preferredColorScheme(.dark)
}

private struct AddProjectSheetPreviewContent: View {
    @State private var name = "mise_pwa"
    @State private var vaultNoteRelativePath = "Progetti/Gestione Mezzi.md"

    var body: some View {
        AddProjectSheetContent(
            name: $name,
            vaultNoteRelativePath: $vaultNoteRelativePath,
            pickedSourceURL: URL(fileURLWithPath: "/Users/lorenzo/Developer/mise_pwa"),
            errorMessage: nil,
            onChooseFolder: {},
            onCancel: {},
            onAdd: {}
        )
    }
}
