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

    /// True when the provider reports work still in progress for this resource (e.g. a
    /// GitHub Actions run `queued`/`in_progress`) — the burst-mode signal per ADR-0006. Every
    /// adapter defaults this to `false`; only adapters that can actually observe an in-flight
    /// state (currently `GitHubActionsAdapter`) set it.
    public var isWorkInFlight: Bool

    public init(headline: String, detail: String, isAttentionNeeded: Bool = false, isWorkInFlight: Bool = false) {
        self.headline = headline
        self.detail = detail
        self.isAttentionNeeded = isAttentionNeeded
        self.isWorkInFlight = isWorkInFlight
    }

    private enum CodingKeys: String, CodingKey {
        case headline, detail, isAttentionNeeded, isWorkInFlight
    }

    /// Custom decode so snapshots written before `isWorkInFlight` existed (everything persisted
    /// by the walking-skeleton spike) still decode instead of failing and falling back to
    /// `nil` in `SnapshotStore.readSnapshot`, which would break ADR-0008's last-good-wins rule.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headline = try container.decode(String.self, forKey: .headline)
        detail = try container.decode(String.self, forKey: .detail)
        isAttentionNeeded = try container.decode(Bool.self, forKey: .isAttentionNeeded)
        isWorkInFlight = try container.decodeIfPresent(Bool.self, forKey: .isWorkInFlight) ?? false
    }
}
