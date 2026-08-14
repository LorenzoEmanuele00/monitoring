import Foundation

/// Exponential backoff with full jitter (ADR-0008: "retries transient failures ... with
/// exponential backoff + full jitter (small bounded attempts per poll cycle)"). Bounded to a
/// handful of attempts per poll cycle — the outer scheduler (baseline/burst cadence) is what
/// spaces out poll cycles themselves, this only covers retries *within* one cycle.
public struct RetryPolicy: Sendable {
    public let maxAttemptsPerCycle: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval

    public init(maxAttemptsPerCycle: Int = 3, baseDelay: TimeInterval = 0.5, maxDelay: TimeInterval = 8.0) {
        self.maxAttemptsPerCycle = maxAttemptsPerCycle
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    /// Full-jitter delay for a given (0-based) attempt index.
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        let capped = min(maxDelay, baseDelay * pow(2.0, Double(attempt)))
        return Double.random(in: 0...capped)
    }

    /// Runs `operation` up to `maxAttemptsPerCycle` times, retrying only when `operation`
    /// signals a transient failure via `PollOutcome.transientFailure`. A `Retry-After` /
    /// rate-limit floor supplied by the adapter (via `minimumDelay`) is honoured as a hard
    /// floor on top of the computed backoff delay.
    public func run(
        clock: @escaping (TimeInterval) async -> Void = { seconds in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        },
        operation: @escaping (Int) async -> (outcome: PollOutcomeRetryClassification, minimumDelay: TimeInterval?)
    ) async -> PollOutcomeRetryClassification {
        var lastOutcome: PollOutcomeRetryClassification = .transient(reason: "no attempts made")
        for attempt in 0..<maxAttemptsPerCycle {
            let (outcome, minimumDelay) = await operation(attempt)
            lastOutcome = outcome
            guard case .transient = outcome else {
                return outcome
            }
            guard attempt < maxAttemptsPerCycle - 1 else { break }
            let computed = delay(forAttempt: attempt)
            let waitTime = max(computed, minimumDelay ?? 0)
            await clock(waitTime)
        }
        return lastOutcome
    }
}

/// Retry-relevant classification of an attempt, distinct from `PollOutcome` so `RetryPolicy`
/// doesn't need to know about `success`/`notModified` payload shapes.
public enum PollOutcomeRetryClassification: Sendable {
    case success
    case notModified
    case transient(reason: String)
    case terminal(reason: String)
}
