import SwiftUI
import MCDomain
import MCProviders

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
        Form {
            Section {
                Text(instructions)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Reference") {
                TextField(externalRefLabel, text: $externalRef, prompt: Text(externalRefPlaceholder))
            }

            Section("Credential") {
                switch providerKind {
                case .githubRepository, .supabaseProject:
                    SecureField("Paste from Keychain Access → \(keychainItemName)", text: $staticToken)
                case .firebaseHosting:
                    Text("Paste from Keychain Access → \(keychainItemName) (Secure Note contents)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $serviceAccountJSON)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .monospaced))
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button(isValidating ? "Validating…" : "Connect") {
                    Task { await connect() }
                }
                .disabled(isValidating || externalRef.isEmpty || credentialData == nil)
            }
        }
        .padding()
        .frame(minWidth: 480)
    }

    private var credentialData: Data? {
        switch providerKind {
        case .githubRepository, .supabaseProject:
            return staticToken.isEmpty ? nil : Data(staticToken.utf8)
        case .firebaseHosting:
            return serviceAccountJSON.isEmpty ? nil : Data(serviceAccountJSON.utf8)
        }
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
