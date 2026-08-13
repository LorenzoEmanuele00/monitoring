import SwiftUI
import MCDomain
import MCDesignTokens

struct ProjectDetailView: View {
    let project: Project
    @EnvironmentObject private var environment: AppEnvironment
    @State private var isShowingConnectSheet = false
    @State private var providerToConnect: ProviderKind = .githubRepository

    private var integrations: [ServiceIntegration] {
        environment.integrations.filter { $0.projectID == project.id }
    }

    var body: some View {
        Form {
            Section("Project") {
                LabeledContent("Name", value: project.name)
                LabeledContent("Vault note", value: project.vaultNoteRelativePath)
                sourcePathRow
            }

            Section("Integrations") {
                ForEach(ProviderKind.allCases, id: \.self) { kind in
                    if let integration = integrations.first(where: { $0.providerKind == kind }) {
                        IntegrationRow(integration: integration)
                    } else {
                        Button("Connect \(kind.displayName)…") {
                            providerToConnect = kind
                            isShowingConnectSheet = true
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(project.name)
        .sheet(isPresented: $isShowingConnectSheet) {
            ConnectIntegrationSheet(project: project, providerKind: providerToConnect)
        }
    }

    @ViewBuilder
    private var sourcePathRow: some View {
        switch BookmarkHelper.resolve(project.sourcePathBookmark) {
        case .resolved(let url):
            LabeledContent("Source path", value: url.path)
        case .notYetSelected:
            LabeledContent("Source path", value: "Not set")
        case .resolutionFailed(let reason):
            Label("Source path needs re-selection: \(reason)", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }
}

private struct IntegrationRow: View {
    let integration: ServiceIntegration

    var body: some View {
        HStack {
            Text(integration.providerKind.displayName)
            Spacer()
            Text(integration.status.rawValue)
                .foregroundStyle(.secondary)
            if let lastError = integration.lastError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MCColor.disconnected)
                    .help(lastError)
            }
        }
    }
}
