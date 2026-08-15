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
        VStack(alignment: .leading, spacing: MCSpacing.s2) {
            if let snapshot = entry.snapshot {
                Text(snapshot.displayName)
                    .font(MCFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(snapshot.payload?.headline ?? "No data yet")
                    .font(MCFont.headline)
                    .lineLimit(2)
                if let detail = snapshot.payload?.detail {
                    Text(detail)
                        .font(MCFont.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                MCStatusPill(snapshot.status.pillLabel, tone: snapshot.status.pillTone)
                MCStalenessIndicator(generatedAt: snapshot.generatedAt)
            } else {
                Text("Mission Control")
                    .font(MCFont.headline)
                Text("No data yet — open the app")
                    .font(MCFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

/// Maps the domain's `IntegrationStatus` to the design system's tone vocabulary. Duplicated
/// (rather than shared via a new MCDesignTokens dependency on MCDomain) for the same reason
/// `WidgetKindIdentifiers` below is duplicated: the design system stays dependency-free, and
/// this mapping is small enough that keeping it local to each target beats coupling them.
private extension IntegrationStatus {
    var pillTone: MCStatusTone {
        switch self {
        case .connected: return .positive
        case .degraded: return .warning
        case .credentialExpired, .disconnected: return .negative
        }
    }

    var pillLabel: String {
        switch self {
        case .connected: return "Connected"
        case .degraded: return "Degraded"
        case .credentialExpired: return "Credential expired"
        case .disconnected: return "Disconnected"
        }
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

// MARK: - Previews (design-system-001-styleguide validation)

/// Previews `IntegrationStatusWidgetView` directly (rather than via `#Preview(as:)`) so the
/// same component set can be checked at `.systemLarge` too, even though only small/medium are
/// wired into `supportedFamilies` above — sizing widget families is a Widgets-BC decision, this
/// task only validates that tokens/components scale, without changing what's shipped.
/// Approximate macOS widget canvas sizes; exact system padding isn't reproduced, only used to
/// sanity-check layout at roughly the right proportions.
private extension IntegrationStatusEntry {
    static func sample(
        status: IntegrationStatus,
        minutesAgo: Double,
        headline: String = "CI passing",
        detail: String = "a3f9c21 · master"
    ) -> IntegrationStatusEntry {
        IntegrationStatusEntry(
            date: .now,
            snapshot: IntegrationSnapshot(
                integrationID: UUID(),
                projectName: "mise_pwa",
                providerKind: .githubRepository,
                displayName: "LorenzoEmanuele00/mise_pwa",
                status: status,
                payload: IntegrationPayload(headline: headline, detail: detail),
                generatedAt: Date().addingTimeInterval(-minutesAgo * 60),
                lastAttemptAt: nil,
                lastError: nil
            )
        )
    }
}

private struct WidgetPreviewCanvas: View {
    let entry: IntegrationStatusEntry
    let size: CGSize

    var body: some View {
        IntegrationStatusWidgetView(entry: entry)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: MCRadius.widget, style: .continuous))
    }
}

private enum PreviewSize {
    static let small = CGSize(width: 164, height: 164)
    static let medium = CGSize(width: 344, height: 164)
    static let large = CGSize(width: 344, height: 344)
}

#Preview("Small — fresh — light") {
    WidgetPreviewCanvas(entry: .sample(status: .connected, minutesAgo: 2), size: PreviewSize.small)
        .preferredColorScheme(.light)
}

#Preview("Small — fresh — dark") {
    WidgetPreviewCanvas(entry: .sample(status: .connected, minutesAgo: 2), size: PreviewSize.small)
        .preferredColorScheme(.dark)
}

#Preview("Medium — subdued — light") {
    WidgetPreviewCanvas(entry: .sample(status: .degraded, minutesAgo: 25), size: PreviewSize.medium)
        .preferredColorScheme(.light)
}

#Preview("Medium — subdued — dark") {
    WidgetPreviewCanvas(entry: .sample(status: .degraded, minutesAgo: 25), size: PreviewSize.medium)
        .preferredColorScheme(.dark)
}

#Preview("Large — flagged/disconnected — light") {
    WidgetPreviewCanvas(entry: .sample(status: .disconnected, minutesAgo: 90), size: PreviewSize.large)
        .preferredColorScheme(.light)
}

#Preview("Large — flagged/disconnected — dark") {
    WidgetPreviewCanvas(entry: .sample(status: .disconnected, minutesAgo: 90), size: PreviewSize.large)
        .preferredColorScheme(.dark)
}

#Preview("Small — no data — light") {
    WidgetPreviewCanvas(entry: IntegrationStatusEntry(date: .now, snapshot: nil), size: PreviewSize.small)
        .preferredColorScheme(.light)
}

#Preview("Small — no data — dark") {
    WidgetPreviewCanvas(entry: IntegrationStatusEntry(date: .now, snapshot: nil), size: PreviewSize.small)
        .preferredColorScheme(.dark)
}
