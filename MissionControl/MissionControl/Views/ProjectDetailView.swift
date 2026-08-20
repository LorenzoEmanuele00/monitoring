import SwiftUI
import AppKit
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
                sourcePathRow
                openInObsidianRow
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

    /// "Open in Obsidian" is the only behavior a Project's Obsidian link drives (ADR-0014): a
    /// URL-scheme handoff via `NSWorkspace`, never a filesystem read. Shown only when a link is
    /// set — no disabled/greyed-out placeholder when it's absent, since the field is optional,
    /// not incomplete.
    @ViewBuilder
    private var openInObsidianRow: some View {
        if let url = project.obsidianOpenURL {
            Button("Open in Obsidian") {
                NSWorkspace.shared.open(url)
            }
            .font(MCFont.body)
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
            if let lastSuccessAt = integration.lastSuccessAt {
                MCStalenessIndicator(generatedAt: lastSuccessAt)
            }
            MCStatusPill(integration.status.pillLabel, tone: integration.status.pillTone)
            if let lastError = integration.lastError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MCColor.error)
                    .help(lastError)
            }
        }
    }
}

#Preview("Integration row — light") {
    IntegrationRowPreviewList()
        .preferredColorScheme(.light)
}

#Preview("Integration row — dark") {
    IntegrationRowPreviewList()
        .preferredColorScheme(.dark)
}

private struct IntegrationRowPreviewList: View {
    var body: some View {
        Form {
            Section("Integrations") {
                IntegrationRow(integration: .preview(status: .connected, minutesSinceSuccess: 2))
                IntegrationRow(integration: .preview(status: .degraded, minutesSinceSuccess: 25))
                IntegrationRow(
                    integration: .preview(status: .disconnected, minutesSinceSuccess: 90, lastError: "401 Unauthorized")
                )
            }
        }
        .padding()
        .frame(width: 420)
    }
}

private extension ServiceIntegration {
    static func preview(
        status: IntegrationStatus,
        minutesSinceSuccess: Double,
        lastError: String? = nil
    ) -> ServiceIntegration {
        ServiceIntegration(
            projectID: UUID(),
            providerKind: .githubRepository,
            credentialKind: .staticToken,
            displayName: "mise_pwa",
            externalRef: "LorenzoEmanuele00/mise_pwa",
            status: status,
            lastSuccessAt: Date().addingTimeInterval(-minutesSinceSuccess * 60),
            lastError: lastError
        )
    }
}
