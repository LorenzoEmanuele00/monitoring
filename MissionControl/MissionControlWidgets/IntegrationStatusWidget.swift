import WidgetKit
import SwiftUI
import MCDomain
import MCSnapshot
import MCDesignTokens

/// The walking skeleton's one Widget Kind (task scope: "at least one Widget Kind"). Renders
/// the GitHub Integration's snapshot — the app is the only writer, this extension only reads
/// Tier B (ADR-0004/0005). No network, no DB, no credentials in this target.
struct IntegrationStatusEntry: TimelineEntry {
    let date: Date
    let snapshot: IntegrationSnapshot?
}

struct IntegrationStatusTimelineProvider: TimelineProvider {
    private let snapshotStore = SnapshotStore()

    func placeholder(in context: Context) -> IntegrationStatusEntry {
        IntegrationStatusEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (IntegrationStatusEntry) -> Void) {
        completion(IntegrationStatusEntry(date: Date(), snapshot: currentSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IntegrationStatusEntry>) -> Void) {
        let entry = IntegrationStatusEntry(date: Date(), snapshot: currentSnapshot())
        WidgetLog.timeline.debug("Timeline requested; snapshot present: \(entry.snapshot != nil)")
        // Conservative fallback policy only (ADR-0006): the app reloads timelines explicitly
        // via `WidgetCenter.reloadTimelines` on every poll that changes something. This
        // ~15 min entry is purely the "app isn't running to push an update" safety net.
        let nextRefresh = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentSnapshot() -> IntegrationSnapshot? {
        snapshotStore.readFirstSnapshot(matching: .githubRepository)
    }
}

struct IntegrationStatusWidgetView: View {
    let entry: IntegrationStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let snapshot = entry.snapshot {
                Text(snapshot.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(snapshot.payload?.headline ?? "No data yet")
                    .font(.headline)
                    .lineLimit(2)
                if let detail = snapshot.payload?.detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                stalenessLabel(generatedAt: snapshot.generatedAt)
            } else {
                Text("Mission Control")
                    .font(.headline)
                Text("No data yet — open the app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private func stalenessLabel(generatedAt: Date) -> some View {
        let level = MCStaleness.level(generatedAt: generatedAt)
        Text(generatedAt, style: .relative)
            .font(.caption2)
            .foregroundStyle(MCStaleness.color(for: level))
    }
}

struct IntegrationStatusWidget: Widget {
    let kind: String = WidgetKindIdentifiers.integrationStatus

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IntegrationStatusTimelineProvider()) { entry in
            IntegrationStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Integration Status")
        .description("Shows the latest status for one of mise_pwa's connected integrations.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Must match `PollingCoordinator`'s `WidgetKindIdentifiers` in the app target — the two
/// targets don't share a Swift module for this one string, so it's duplicated deliberately
/// rather than pulling UI-layer app code into the extension's dependency graph.
enum WidgetKindIdentifiers {
    static let integrationStatus = "com.lorenzoemanuele.missioncontrol.integrationStatus"
}
