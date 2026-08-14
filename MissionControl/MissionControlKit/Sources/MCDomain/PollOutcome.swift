import Foundation

/// What a provider adapter's `poll` call renders down to, for the polling pipeline to apply
/// the ADR-0008 failure policy uniformly across providers.
public enum PollOutcome: Sendable {
    /// New data. `etag` (when the provider supports conditional requests) is persisted onto
    /// the Integration and sent back on the next poll.
    case success(payload: IntegrationPayload, etag: String?)

    /// Conditional request returned 304 — data unchanged, still fresh. Treated the same as
    /// `success` for staleness purposes (`lastSuccessAt` advances) but there is no new
    /// payload to project into Tier B.
    case notModified

    /// Network error / 5xx / 429 — transient, retried with backoff. Never clears last-good
    /// data (ADR-0008). `retryAfter`, when the provider supplied a `Retry-After` / rate-limit
    /// reset header, is honoured by `RetryPolicy` as a hard floor on the next attempt's delay.
    case transientFailure(reason: String, retryAfter: TimeInterval? = nil)

    /// 401/403/404 or equivalent — stop retrying, raise "credential expired"/"resource gone".
    case terminalFailure(reason: String)
}

/// Render-ready payload an adapter hands back on success. Provider-specific detail is reduced
/// to this common shape so the projection step (Tier A -> Tier B) doesn't need per-provider
/// branching beyond formatting `headline`/`detail`.
public struct IntegrationPayload: Codable, Equatable, Sendable {
    /// Short status line, e.g. "CI passing" / "Deploy live" / "2 projects".
    public var headline: String

    /// One extra line of detail, e.g. a commit SHA, a hosting version ID, a timestamp.
    public var detail: String

    /// True when the underlying provider condition is "bad" (failed build, error state) —
    /// lets rendering surfaces flag it distinctly from a merely-stale-but-fine snapshot.
    public var isAttentionNeeded: Bool

    public init(headline: String, detail: String, isAttentionNeeded: Bool = false) {
        self.headline = headline
        self.detail = detail
        self.isAttentionNeeded = isAttentionNeeded
    }
}
