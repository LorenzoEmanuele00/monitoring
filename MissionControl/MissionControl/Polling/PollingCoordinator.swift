import Foundation
import os
import Network
import AppKit
import WidgetKit
import MCDomain
import MCPersistence
import MCSnapshot
import MCSecrets
import MCProviders

/// Baseline + burst polling pipeline (ADR-0006): the resident menu-bar app is the only moving
/// part. Poll -> write Tier A -> project Tier B -> `WidgetCenter.reloadTimelines` -> (on
/// terminal failure) notify once. Applies the ADR-0008 failure policy: `pollOne` retries
/// transient failures in-cycle via `RetryPolicy` (bounded attempts, exponential backoff + full
/// jitter, `Retry-After` honoured as a hard floor) before the outer baseline/burst cadence ever
/// sees a failed cycle.
@MainActor
final class PollingCoordinator {
    private let projectRepository: ProjectRepository
    private let integrationRepository: ServiceIntegrationRepository
    private let secretStore: SecretStore
    private let snapshotStore: SnapshotStore
    private let analytics: AnalyticsEventLogger
    private let signposter = OSSignposter(logger: AppLog.polling)

    private let adapters: [ProviderKind: any ProviderAdapter] = [
        .githubRepository: GitHubActionsAdapter(),
        .firebaseHosting: FirebaseHostingAdapter(),
        .supabaseProject: SupabaseAdapter(),
    ]

    /// Baseline cadence per provider (ADR-0006): GitHub ~2 min, Firebase Hosting ~5 min,
    /// Supabase ~15 min, each with jitter.
    private static let baselineIntervals: [ProviderKind: TimeInterval] = [
        .githubRepository: 120,
        .firebaseHosting: 300,
        .supabaseProject: 900,
    ]

    /// Baseline cadence runs under `NSBackgroundActivityScheduler` per ADR-0006 ("so the OS can
    /// coalesce it and respect power and thermal state"), one activity per Integration.
    private var scheduledActivities: [UUID: NSBackgroundActivityScheduler] = [:]
    private var pathMonitor: NWPathMonitor?
    private let retryPolicy = RetryPolicy()

    /// Burst mode (ADR-0006): while a value is present for an Integration, that Integration is
    /// bursting under a plain `Task` at `BurstPolling.interval` instead of its baseline
    /// `NSBackgroundActivityScheduler` activity. The value is when the current burst started,
    /// fed to `BurstPolling.decide` for the ~20 min cap. Entering/exiting burst is decided
    /// purely by `BurstPolling` (MCDomain) after every poll, baseline or burst alike.
    private var burstStartedAt: [UUID: Date] = [:]
    private var burstTasks: [UUID: Task<Void, Never>] = [:]

    init(
        projectRepository: ProjectRepository,
        integrationRepository: ServiceIntegrationRepository,
        secretStore: SecretStore,
        snapshotStore: SnapshotStore,
        analytics: AnalyticsEventLogger = NoOpAnalyticsEventLogger()
    ) {
        self.projectRepository = projectRepository
        self.integrationRepository = integrationRepository
        self.secretStore = secretStore
        self.snapshotStore = snapshotStore
        self.analytics = analytics
    }

    /// Schedules every Integration on its baseline cadence and wires wake/connectivity resync
    /// (ADR-0006: "resync immediately on NSWorkspace.didWakeNotification and
    /// NWPathMonitor connectivity-returned").
    func start() {
        AppLog.polling.info("Polling coordinator starting")
        rescheduleAll()

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLog.polling.info("Wake from sleep — resyncing all integrations")
            Task { @MainActor in self?.pollAllNow() }
        }

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            AppLog.polling.info("Connectivity returned — resyncing all integrations")
            Task { @MainActor in self?.pollAllNow() }
        }
        monitor.start(queue: DispatchQueue(label: "com.lorenzoemanuele.missioncontrol.pathmonitor"))
        self.pathMonitor = monitor
    }

    /// Call after a new Integration is attached (Connect Integration flow) so it joins the
    /// baseline schedule without waiting for the next app launch.
    func integrationsChanged() {
        rescheduleAll()
    }

    private func rescheduleAll() {
        for activity in scheduledActivities.values { activity.invalidate() }
        scheduledActivities.removeAll()
        for task in burstTasks.values { task.cancel() }
        burstTasks.removeAll()
        burstStartedAt.removeAll()

        guard let integrations = try? integrationRepository.fetchAll() else { return }
        for integration in integrations {
            scheduleBaseline(for: integration)
        }
    }

    private func scheduleBaseline(for integration: ServiceIntegration) {
        let baseInterval = Self.baselineIntervals[integration.providerKind] ?? 300
        let activity = NSBackgroundActivityScheduler(
            identifier: "com.lorenzoemanuele.missioncontrol.poll.\(integration.id.uuidString)"
        )
        activity.repeats = true
        activity.interval = baseInterval
        // Jitter, per ADR-0006 ("per-provider intervals and jitter"): expressed as
        // `tolerance`, the window the OS is free to use to coalesce this activity with other
        // system activity and align it to power-friendly wake windows, rather than a
        // manually-computed sleep offset.
        activity.tolerance = baseInterval * 0.15
        activity.qualityOfService = .utility
        scheduledActivities[integration.id] = activity

        activity.schedule { [weak self] completion in
            guard let self else {
                completion(.finished)
                return
            }
            Task { @MainActor in
                await self.pollAndAdapt(integrationID: integration.id)
                completion(.finished)
            }
        }
    }

    /// Triggers an immediate poll of every known Integration (wake/connectivity resync, or a
    /// manual "poll now" action).
    func pollAllNow() {
        guard let integrations = try? integrationRepository.fetchAll() else { return }
        for integration in integrations {
            Task { await pollAndAdapt(integrationID: integration.id) }
        }
    }

    /// One poll cycle plus the ADR-0006 burst-mode decision it feeds. Shared by baseline
    /// activities, the burst loop itself, and wake/connectivity resync so every entry point
    /// applies the same enter/stay/exit logic (`BurstPolling.decide`, MCDomain — testable at
    /// package level independent of this app-target scheduling code).
    private func pollAndAdapt(integrationID: UUID) async {
        guard let result = await pollOne(integrationID: integrationID) else { return }

        let isBursting = burstStartedAt[integrationID] != nil
        let decision = BurstPolling.decide(
            isCurrentlyBursting: isBursting,
            burstStartedAt: burstStartedAt[integrationID],
            isWorkInFlight: result.isWorkInFlight,
            isCircuitOpen: result.isCircuitOpen,
            now: Date()
        )

        switch decision {
        case .enterBurst:
            enterBurstMode(integrationID: integrationID)
        case .remainInBurst, .remainBaseline:
            break
        case .exitBurst(let reason):
            exitBurstMode(integrationID: integrationID, reason: reason)
        }
    }

    /// Tears down the baseline `NSBackgroundActivityScheduler` activity for this Integration
    /// and replaces it with a `Task`-based ~30s poll loop (ADR-0006).
    private func enterBurstMode(integrationID: UUID) {
        guard burstStartedAt[integrationID] == nil else { return }
        AppLog.polling.info("Entering burst mode: \(integrationID, privacy: .public) — work in flight, polling every ~\(Int(BurstPolling.interval), privacy: .public)s (cap ~\(Int(BurstPolling.maxDuration / 60), privacy: .public)min)")
        burstStartedAt[integrationID] = Date()
        scheduledActivities[integrationID]?.invalidate()
        scheduledActivities.removeValue(forKey: integrationID)

        burstTasks[integrationID] = Task { [weak self] in
            await self?.runBurstLoop(integrationID: integrationID)
        }
    }

    private func runBurstLoop(integrationID: UUID) async {
        while !Task.isCancelled && burstStartedAt[integrationID] != nil {
            try? await Task.sleep(nanoseconds: UInt64(BurstPolling.interval * 1_000_000_000))
            guard !Task.isCancelled, burstStartedAt[integrationID] != nil else { break }
            await pollAndAdapt(integrationID: integrationID)
        }
    }

    /// Cancels the burst `Task` and restores the baseline `NSBackgroundActivityScheduler`
    /// activity (ADR-0006: "reverting to baseline").
    private func exitBurstMode(integrationID: UUID, reason: BurstExitReason) {
        guard burstStartedAt[integrationID] != nil else { return }
        AppLog.polling.info("Exiting burst mode (\(String(describing: reason), privacy: .public)): \(integrationID, privacy: .public) — reverting to baseline cadence")
        burstStartedAt.removeValue(forKey: integrationID)
        burstTasks[integrationID]?.cancel()
        burstTasks.removeValue(forKey: integrationID)

        if let integration = try? integrationRepository.fetch(id: integrationID) {
            scheduleBaseline(for: integration)
        }
    }

    /// One poll attempt, applying the ADR-0008 failure policy. Returns the ADR-0006 burst
    /// signal derived from the outcome — `nil` when no poll was actually attempted (missing
    /// integration/adapter/credential).
    private func pollOne(integrationID: UUID) async -> PollResult? {
        guard var integration = try? integrationRepository.fetch(id: integrationID),
              let adapter = adapters[integration.providerKind] else {
            return nil
        }
        guard let credential = try? secretStore.read(for: integrationID) else {
            AppLog.secrets.error("No credential found for integration \(integrationID, privacy: .public)")
            return nil
        }

        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval("provider-poll", id: signpostID, "\(integration.providerKind.rawValue)")
        defer { signposter.endInterval("provider-poll", state) }

        let previousStatus = integration.status
        let externalRef = integration.externalRef
        let etag = integration.etag

        // ADR-0008: retry transient failures in-cycle with exponential backoff + full jitter,
        // bounded to a small number of attempts, before letting the outer baseline/burst
        // cadence see a failed cycle. A provider-supplied `Retry-After` is honoured as a hard
        // floor on top of the computed backoff delay via `minimumDelay`. `RetryPolicy.run`'s
        // `operation` closure must be `@Sendable`, so the actual per-attempt `PollOutcome`
        // (which `PollOutcomeRetryClassification` deliberately doesn't carry) is threaded back
        // out through a lock-protected box rather than a captured `var`, mirroring
        // `FirebaseHostingAdapter`'s `OSAllocatedUnfairLock`-backed cache.
        let outcomeBox = OSAllocatedUnfairLock<PollOutcome>(initialState: .transientFailure(reason: "no attempts made"))
        _ = await retryPolicy.run { @Sendable _ in
            let attemptOutcome = await adapter.poll(externalRef: externalRef, credential: credential, etag: etag)
            outcomeBox.withLock { $0 = attemptOutcome }
            switch attemptOutcome {
            case .success:
                return (.success, nil)
            case .notModified:
                return (.notModified, nil)
            case .transientFailure(_, let retryAfter):
                return (.transient(reason: "transient"), retryAfter)
            case .terminalFailure(let reason):
                return (.terminal(reason: reason), nil)
            }
        }
        let outcome = outcomeBox.withLock { $0 }
        integration.lastAttemptAt = Date()

        // ADR-0006 burst-mode signal: `nil` unless this cycle actually confirms a work-in-
        // flight state one way or the other (fresh success, or not-modified confirming the
        // last-known payload). A transient/terminal failure carries no new signal — burst
        // state is left for `BurstPolling.decide` to leave alone (ADR-0008 last-good-wins).
        var isWorkInFlight: Bool?

        switch outcome {
        case .success(let payload, let newETag):
            integration.status = .connected
            integration.lastSuccessAt = integration.lastAttemptAt
            integration.lastError = nil
            integration.etag = newETag ?? integration.etag
            integration.consecutiveFailureCount = 0
            try? integrationRepository.update(integration)
            await writeSnapshot(for: integration, payload: payload, generatedAt: Date())
            AppLog.polling.debug("Poll success: \(integration.providerKind.rawValue, privacy: .public) \(integration.displayName, privacy: .public)")
            isWorkInFlight = payload.isWorkInFlight

        case .notModified:
            integration.status = .connected
            integration.lastSuccessAt = integration.lastAttemptAt
            integration.lastError = nil
            integration.consecutiveFailureCount = 0
            try? integrationRepository.update(integration)
            // ADR-0008: 304 is "unchanged-still-fresh" — same payload content, but confirmed
            // current as of now, so the existing snapshot's `generatedAt` advances too.
            if let existing = snapshotStore.readSnapshot(integrationID: integration.id) {
                await writeSnapshot(for: integration, payload: existing.payload, generatedAt: Date())
                isWorkInFlight = existing.payload?.isWorkInFlight
            }
            AppLog.polling.debug("Poll not-modified: \(integration.providerKind.rawValue, privacy: .public)")

        case .transientFailure(let reason, _):
            integration.lastError = reason
            integration.consecutiveFailureCount += 1
            integration.status = integration.isCircuitOpen ? .disconnected : .degraded
            try? integrationRepository.update(integration)
            AppLog.polling.info("Poll transient failure after in-cycle retries: \(integration.providerKind.rawValue, privacy: .public) — \(reason, privacy: .public)")
            if integration.isCircuitOpen && previousStatus != .disconnected {
                analytics.logIntegrationDisconnected(providerKind: integration.providerKind, integrationID: integration.id)
            }
            // Last-good wins (ADR-0008): Tier B snapshot is untouched on failure.

        case .terminalFailure(let reason):
            integration.lastError = reason
            integration.status = .credentialExpired
            try? integrationRepository.update(integration)
            AppLog.polling.error("Poll terminal failure: \(integration.providerKind.rawValue, privacy: .public) — \(reason, privacy: .public)")
            if previousStatus != .credentialExpired {
                analytics.logCredentialExpired(providerKind: integration.providerKind, integrationID: integration.id)
            }
            // Last-good wins (ADR-0008): Tier B snapshot is untouched on failure.
        }

        return PollResult(isWorkInFlight: isWorkInFlight, isCircuitOpen: integration.isCircuitOpen)
    }

    private func writeSnapshot(for integration: ServiceIntegration, payload: MCDomain.IntegrationPayload?, generatedAt: Date) async {
        guard let project = try? projectRepository.fetch(id: integration.projectID) else { return }
        let snapshot = IntegrationSnapshot(
            integrationID: integration.id,
            projectName: project.name,
            providerKind: integration.providerKind,
            displayName: integration.displayName,
            status: integration.status,
            payload: payload,
            generatedAt: generatedAt,
            lastAttemptAt: integration.lastAttemptAt,
            lastError: integration.lastError
        )
        do {
            try snapshotStore.writeSnapshot(snapshot)
            let allIDs = (try? integrationRepository.fetchAll().map(\.id)) ?? [integration.id]
            try snapshotStore.writeManifest(SnapshotManifest(integrationIDs: allIDs, generatedAt: Date()))
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKindIdentifiers.integrationStatus)
        } catch {
            AppLog.polling.error("Failed to write Tier B snapshot: \(String(describing: error), privacy: .public)")
        }
    }
}

/// Shared with `MissionControlWidgets` (both must agree on the `kind` string). Kept as a
/// small standalone enum rather than importing anything extra into the extension.
enum WidgetKindIdentifiers {
    static let integrationStatus = "com.lorenzoemanuele.missioncontrol.integrationStatus"
}

/// What one `pollOne` cycle hands back to `pollAndAdapt` for the ADR-0006 burst-mode decision.
private struct PollResult {
    let isWorkInFlight: Bool?
    let isCircuitOpen: Bool
}
