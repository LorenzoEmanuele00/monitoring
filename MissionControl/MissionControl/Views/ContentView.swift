import SwiftUI
import AppKit
import MCDomain
import MCDesignTokens

/// Main window: Project list + per-Project Integration attachment. This spike registers
/// exactly one Project (mise_pwa) — a Project picker/multi-project UI is explicitly out of
/// scope (task Notes: "more than one Project").
struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var isShowingAddProject = false

    var body: some View {
        NavigationSplitView {
            List(environment.projects) { project in
                NavigationLink(project.name) {
                    ProjectDetailView(project: project)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem {
                    Button {
                        isShowingAddProject = true
                    } label: {
                        Label("Add Project", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let bootstrapError = environment.bootstrapError {
                ContentUnavailableView(
                    "Storage unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(bootstrapError)
                )
            } else {
                ContentUnavailableView("Select a Project", systemImage: "folder")
            }
        }
        .sheet(isPresented: $isShowingAddProject) {
            AddProjectSheet()
        }
        .onAppear {
            environment.startPolling()
        }
    }
}

struct MenuBarContentView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if environment.integrations.isEmpty {
                Text("No Integrations yet").foregroundStyle(.secondary)
            }
            ForEach(environment.integrations) { integration in
                HStack {
                    Text(integration.displayName)
                    Spacer()
                    Text(integration.providerKind.displayName)
                        .foregroundStyle(.secondary)
                    MCStatusPill(integration.status.pillLabel, tone: integration.status.pillTone)
                }
            }
            Divider()
            Button("Poll Now") {
                environment.pollingCoordinator?.pollAllNow()
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
        .frame(minWidth: 220)
    }
}

#Preview("Menu bar — light") {
    MenuBarPreviewContent()
        .preferredColorScheme(.light)
}

#Preview("Menu bar — dark") {
    MenuBarPreviewContent()
        .preferredColorScheme(.dark)
}

/// Renders the same status-pill row `MenuBarContentView` uses, without depending on
/// `AppEnvironment`'s full polling/persistence bootstrap — this task's previews validate the
/// design-system components, not the menu bar's live data plumbing.
private struct MenuBarPreviewContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(IntegrationStatus.allPreviewCases, id: \.self) { status in
                HStack {
                    Text("mise_pwa")
                    Spacer()
                    Text("GitHub")
                        .foregroundStyle(.secondary)
                    MCStatusPill(status.pillLabel, tone: status.pillTone)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 260)
    }
}

private extension IntegrationStatus {
    static let allPreviewCases: [IntegrationStatus] = [.connected, .degraded, .credentialExpired, .disconnected]
}
