import SwiftUI
import MCDomain
import MCProviders
import MCDesignTokens

/// "Connect integration" sheet (ADR-0012: manually-provisioned long-lived credentials, no
/// OAuth in v1). The three real credentials for mise_pwa are provisioned and held in the
/// user's login-keychain Keychain Access.app per
/// `service-integrations/references/mise_pwa-credential-setup.md` — this sheet is where the
/// user copies each one in by hand; MissionControl never reads the login keychain itself.
struct ConnectIntegrationSheet: View {
    let project: Project
    let providerKind: ProviderKind

    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var externalRef = ""
    @State private var staticToken = ""
    @State private var serviceAccountJSON = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

    private var credentialKind: CredentialKind {
        switch providerKind {
        case .githubRepository, .supabaseProject: return .staticToken
        case .firebaseHosting: return .serviceAccountKey
        }
    }

    var body: some View {
        ConnectIntegrationSheetContent(
            providerKind: providerKind,
            externalRef: $externalRef,
            staticToken: $staticToken,
            serviceAccountJSON: $serviceAccountJSON,
            isValidating: isValidating,
            errorMessage: errorMessage,
            canConnect: !isValidating && !externalRef.isEmpty && credentialData != nil,
            onCancel: { dismiss() },
            onConnect: { Task { await connect() } }
        )
    }

    private var credentialData: Data? {
        switch providerKind {
        case .githubRepository, .supabaseProject:
            return staticToken.isEmpty ? nil : Data(staticToken.utf8)
        case .firebaseHosting:
            return serviceAccountJSON.isEmpty ? nil : Data(serviceAccountJSON.utf8)
        }
    }

    private func adapter() -> any ProviderAdapter {
        switch providerKind {
        case .githubRepository: return GitHubActionsAdapter()
        case .firebaseHosting: return FirebaseHostingAdapter()
        case .supabaseProject: return SupabaseAdapter()
        }
    }

    private func connect() async {
        guard let credentialData else { return }
        isValidating = true
        errorMessage = nil
        defer { isValidating = false }

        do {
            try await adapter().validateCredential(credentialData)
        } catch {
            errorMessage = "Credential validation failed: \(error)"
            return
        }

        let integration = ServiceIntegration(
            projectID: project.id,
            providerKind: providerKind,
            credentialKind: credentialKind,
            displayName: displayName(for: externalRef),
            externalRef: externalRef,
            status: .connected,
            lastAttemptAt: Date(),
            lastSuccessAt: Date()
        )

        do {
            try environment.addIntegration(integration, credential: credentialData)
            environment.pollingCoordinator?.pollAllNow()
            dismiss()
        } catch {
            errorMessage = "\(error)"
        }
    }

    private func displayName(for ref: String) -> String { ref }
}

/// The sheet's visual content, split out from `ConnectIntegrationSheet` so it can be previewed
/// without bootstrapping `AppEnvironment`'s real Tier A database/Keychain — mirrors the
/// `MenuBarPreviewContent` split in `ContentView.swift` and `AddProjectSheetContent` in
/// `AddProjectSheet.swift`.
///
/// A macOS `Form` lays out standalone (unlabeled) rows — like the instructions paragraph
/// below — using its automatic label/control column split, which compresses anything that
/// isn't a real "Label: Control" pair into a narrow trailing column. That's what produced
/// the squeezed/overflowing text. A plain leading-aligned VStack sizes every row to the
/// sheet's full width instead, and wraps naturally as the sheet is resized.
private struct ConnectIntegrationSheetContent: View {
    let providerKind: ProviderKind
    @Binding var externalRef: String
    @Binding var staticToken: String
    @Binding var serviceAccountJSON: String
    let isValidating: Bool
    let errorMessage: String?
    let canConnect: Bool
    let onCancel: () -> Void
    let onConnect: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCSpacing.s5) {
                Text(instructions)
                    .font(MCFont.body)
                    .foregroundStyle(MCColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: MCSpacing.s3) {
                    Text(externalRefLabel)
                        .font(MCFont.headline)
                        .foregroundStyle(MCColor.label)
                    TextField(externalRefLabel, text: $externalRef, prompt: Text(externalRefPlaceholder))
                        .textFieldStyle(.roundedBorder)
                        .font(MCFont.body)
                }

                VStack(alignment: .leading, spacing: MCSpacing.s3) {
                    Text("Credential")
                        .font(MCFont.headline)
                        .foregroundStyle(MCColor.label)
                    switch providerKind {
                    case .githubRepository, .supabaseProject:
                        SecureField("Paste from Keychain Access → \(keychainItemName)", text: $staticToken)
                            .textFieldStyle(.roundedBorder)
                            .font(MCFont.body)
                    case .firebaseHosting:
                        Text("Paste from Keychain Access → \(keychainItemName) (Secure Note contents)")
                            .font(MCFont.caption)
                            .foregroundStyle(MCColor.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextEditor(text: $serviceAccountJSON)
                            .font(MCFont.monoData)
                            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 240)
                            .overlay(
                                RoundedRectangle(cornerRadius: MCRadius.control)
                                    .stroke(MCColor.separator, lineWidth: 1)
                            )
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(MCFont.subheadline)
                        .foregroundStyle(MCColor.error)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: MCSpacing.s4) {
                    Spacer()
                    Button("Cancel", role: .cancel, action: onCancel)
                    Button(isValidating ? "Validating…" : "Connect", action: onConnect)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!canConnect)
                }
            }
            .padding(MCSpacing.s5)
        }
        .frame(width: 520, height: 420)
    }

    private var keychainItemName: String {
        switch providerKind {
        case .githubRepository: return "mission-control-github-pat"
        case .firebaseHosting: return "mission-control-firebase-key"
        case .supabaseProject: return "mission-control-supabase-pat"
        }
    }

    private var externalRefLabel: String {
        switch providerKind {
        case .githubRepository: return "owner/repo"
        case .firebaseHosting: return "Firebase Hosting site ID"
        case .supabaseProject: return "Supabase project ref"
        }
    }

    private var externalRefPlaceholder: String {
        switch providerKind {
        case .githubRepository: return "LorenzoEmanuele00/mise_pwa"
        case .firebaseHosting: return "mise-pwa"
        case .supabaseProject: return "abcdefghijklmnopqrst"
        }
    }

    private var instructions: String {
        "Open Keychain Access.app (login keychain) and copy the value stored as " +
            "\"\(keychainItemName)\" into the field below, then delete that Keychain Access " +
            "item — MissionControl's own Keychain storage becomes the source of truth."
    }
}

#Preview("Connect Integration — light") {
    ConnectIntegrationSheetPreviewContent()
        .preferredColorScheme(.light)
}

#Preview("Connect Integration — dark") {
    ConnectIntegrationSheetPreviewContent()
        .preferredColorScheme(.dark)
}

private struct ConnectIntegrationSheetPreviewContent: View {
    @State private var externalRef = "LorenzoEmanuele00/mise_pwa"
    @State private var staticToken = ""
    @State private var serviceAccountJSON = ""

    var body: some View {
        ConnectIntegrationSheetContent(
            providerKind: .githubRepository,
            externalRef: $externalRef,
            staticToken: $staticToken,
            serviceAccountJSON: $serviceAccountJSON,
            isValidating: false,
            errorMessage: nil,
            canConnect: true,
            onCancel: {},
            onConnect: {}
        )
    }
}
