import Testing
@testable import MCDomain
import Foundation

/// ADR-0006's burst-mode decision logic. Kept as a pure function of
/// (currently-bursting?, burst-start-time, latest-poll's work-in-flight signal, circuit-breaker
/// state, now) so it's testable at package level, independent of `NSBackgroundActivityScheduler`
/// / `Task`, which only exist in the app target (`PollingCoordinator`) per the infrastructure BC
/// README's target/package layout.
@Suite struct BurstPollingTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func entersBurstWhenWorkObservedInFlightFromBaseline() {
        let decision = BurstPolling.decide(
            isCurrentlyBursting: false,
            burstStartedAt: nil,
            isWorkInFlight: true,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .enterBurst)
    }

    @Test func remainsAtBaselineWhenNoWorkInFlight() {
        let decision = BurstPolling.decide(
            isCurrentlyBursting: false,
            burstStartedAt: nil,
            isWorkInFlight: false,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .remainBaseline)
    }

    @Test func remainsAtBaselineOnNilSignalWhenNotBursting() {
        // A transient/terminal failure carries no new work-in-flight signal (ADR-0008's
        // last-good-wins) — it must not spuriously trigger burst mode.
        let decision = BurstPolling.decide(
            isCurrentlyBursting: false,
            burstStartedAt: nil,
            isWorkInFlight: nil,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .remainBaseline)
    }

    @Test func doesNotEnterBurstWhenCircuitAlreadyOpen() {
        // Don't start hammering an already-broken Integration faster just because its last
        // (pre-breaker) payload happened to say work was in flight.
        let decision = BurstPolling.decide(
            isCurrentlyBursting: false,
            burstStartedAt: nil,
            isWorkInFlight: true,
            isCircuitOpen: true,
            now: now
        )
        #expect(decision == .remainBaseline)
    }

    @Test func remainsInBurstWhileWorkStillInFlightAndUnderCap() {
        let decision = BurstPolling.decide(
            isCurrentlyBursting: true,
            burstStartedAt: now.addingTimeInterval(-60),
            isWorkInFlight: true,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .remainInBurst)
    }

    @Test func remainsInBurstOnNilSignalWhileBursting() {
        // A transient failure mid-burst shouldn't drop back to baseline on its own — only an
        // explicit "no longer in flight" success/not-modified signal, the cap, or the circuit
        // breaker end a burst.
        let decision = BurstPolling.decide(
            isCurrentlyBursting: true,
            burstStartedAt: now.addingTimeInterval(-60),
            isWorkInFlight: nil,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .remainInBurst)
    }

    @Test func exitsBurstWhenWorkNoLongerInFlight() {
        let decision = BurstPolling.decide(
            isCurrentlyBursting: true,
            burstStartedAt: now.addingTimeInterval(-60),
            isWorkInFlight: false,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .exitBurst(reason: .workNoLongerInFlight))
    }

    @Test func exitsBurstWhenTwentyMinuteCapReached() {
        let decision = BurstPolling.decide(
            isCurrentlyBursting: true,
            burstStartedAt: now.addingTimeInterval(-BurstPolling.maxDuration),
            isWorkInFlight: true,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .exitBurst(reason: .capReached))
    }

    @Test func remainsInBurstJustUnderTheCap() {
        let decision = BurstPolling.decide(
            isCurrentlyBursting: true,
            burstStartedAt: now.addingTimeInterval(-BurstPolling.maxDuration + 1),
            isWorkInFlight: true,
            isCircuitOpen: false,
            now: now
        )
        #expect(decision == .remainInBurst)
    }

    @Test func exitsBurstWhenCircuitOpensMidBurst() {
        // ADR-0008: burst mode must not bypass the circuit breaker — a bursting Integration
        // that trips the breaker reverts to baseline like any other, rather than continuing to
        // hammer a now-disconnected provider at burst cadence.
        let decision = BurstPolling.decide(
            isCurrentlyBursting: true,
            burstStartedAt: now.addingTimeInterval(-60),
            isWorkInFlight: true,
            isCircuitOpen: true,
            now: now
        )
        #expect(decision == .exitBurst(reason: .circuitOpen))
    }

    @Test func intervalAndCapMatchADR0006() {
        #expect(BurstPolling.interval == 30)
        #expect(BurstPolling.maxDuration == 20 * 60)
    }
}
