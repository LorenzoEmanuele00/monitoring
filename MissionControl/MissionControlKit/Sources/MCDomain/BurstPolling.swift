import Foundation

/// What `BurstPolling.decide` tells the caller to do next, per ADR-0006's two-speed
/// scheduling (baseline `NSBackgroundActivityScheduler` cadence vs. a `Task`-based ~30s burst
/// cadence while work is observed in flight, hard-capped at ~20 min).
public enum BurstPollingDecision: Equatable, Sendable {
    case enterBurst
    case remainInBurst
    case exitBurst(reason: BurstExitReason)
    case remainBaseline
}

public enum BurstExitReason: Equatable, Sendable {
    /// A poll gave an explicit "no longer in flight" signal (fresh success or a
    /// not-modified confirming the last-known payload).
    case workNoLongerInFlight
    /// ADR-0006's ~20 min hard cap elapsed while work was still (or ambiguously) in flight.
    case capReached
    /// ADR-0008's circuit breaker tripped mid-burst — burst mode must not bypass it by
    /// continuing to hammer an already-broken Integration faster than baseline.
    case circuitOpen
}

/// Pure decision logic for ADR-0006's burst polling mode. Provider- and scheduler-agnostic on
/// purpose: it knows nothing about `NSBackgroundActivityScheduler`, `Task`, or any specific
/// provider adapter, so it's testable at package level (`swift test`) independent of
/// `PollingCoordinator`, which is app-target-only code (see the infrastructure BC README's
/// target/package layout).
public enum BurstPolling {
    /// ADR-0006: "burst mode of ~30 s polling".
    public static let interval: TimeInterval = 30

    /// ADR-0006: "hard-capped (~20 min) before reverting to baseline".
    public static let maxDuration: TimeInterval = 20 * 60

    /// - Parameters:
    ///   - isCurrentlyBursting: whether this Integration is presently in burst mode.
    ///   - burstStartedAt: when the current burst began; `nil` when `isCurrentlyBursting` is
    ///     `false`.
    ///   - isWorkInFlight: the latest poll's work-in-flight signal — `true`/`false` from a
    ///     fresh success or a not-modified confirming the last-known payload, `nil` when the
    ///     poll gave no new signal (a transient or terminal failure — ADR-0008's last-good-wins
    ///     means burst state is left alone rather than dropped on a blip).
    ///   - isCircuitOpen: the Integration's ADR-0008 circuit-breaker state after the latest
    ///     poll.
    ///   - now: the current time (injected for testability).
    public static func decide(
        isCurrentlyBursting: Bool,
        burstStartedAt: Date?,
        isWorkInFlight: Bool?,
        isCircuitOpen: Bool,
        now: Date
    ) -> BurstPollingDecision {
        if isCurrentlyBursting {
            if isCircuitOpen {
                return .exitBurst(reason: .circuitOpen)
            }
            if let burstStartedAt, now.timeIntervalSince(burstStartedAt) >= maxDuration {
                return .exitBurst(reason: .capReached)
            }
            if isWorkInFlight == false {
                return .exitBurst(reason: .workNoLongerInFlight)
            }
            return .remainInBurst
        } else {
            if isWorkInFlight == true && !isCircuitOpen {
                return .enterBurst
            }
            return .remainBaseline
        }
    }
}
