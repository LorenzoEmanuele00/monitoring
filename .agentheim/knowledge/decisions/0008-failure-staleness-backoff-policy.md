---
id: 0008
title: Failure policy — last-good data wins, staleness is always visible, providers are treated as rate-limited and flaky
scope: global
status: accepted
date: 2026-08-13
supersedes: []
superseded_by: []
related_tasks: [infrastructure-mam0r]
related_research: []
---

# ADR 0008: Failure policy — last-good data wins, staleness is always visible, providers are treated as rate-limited and flaky

## Context
Every datum this product shows comes from a third-party API that will, routinely, be slow,
rate-limited, temporarily 5xx, or reachable only when the Mac has network. A polling architecture
(see the background refresh ADR) makes this a continuous condition rather than an edge case. The
dangerous failure mode for a glanceable cockpit is not an error message — it is a widget that
confidently displays hours-old data as if it were current, which actively misleads the user about
the state of a production deploy.

## Decision
Three rules apply to every provider interaction, in every bounded context.

**1. Last-good data wins.** A failed refresh never overwrites or clears a good snapshot. Success
updates the payload and `generatedAt`; failure updates only `lastAttemptAt` and `lastError`.
A provider outage degrades freshness, never content.

**2. Staleness is always visible.** Every snapshot carries `generatedAt`, and every rendering
surface — desktop widget and in-app panel alike — displays freshness as relative time and
degrades visibly past a threshold (suggested: subdued past ~30 min, explicitly flagged past
~2 h). A widget that silently shows stale data is a defect, not a cosmetic issue.

**3. Providers are assumed rate-limited and flaky.** Every adapter:
- issues conditional requests where supported, persisting ETag / `Last-Modified` validators in
  Tier A and treating 304 as "unchanged, still fresh" (GitHub's REST 304s notably do not consume
  primary rate limit — a strong reason to make this the default path);
- honours `Retry-After` and rate-limit reset headers as hard floors on the next attempt;
- retries transient failures (network errors, 5xx, 429) with exponential backoff plus full
  jitter, bounded to a small number of attempts within one poll cycle;
- classifies 401/403/404 as **terminal**: stop retrying, raise the corresponding domain event
  (credential expired, resource gone), and let Notifications surface it once;
- trips a per-credential circuit breaker after repeated consecutive hard failures, parking that
  Integration in a visible "disconnected" state instead of continuing to poll.

Transient failures are silent (logged, not notified). Terminal failures always reach the user
exactly once — deduped by Notifications, not by the adapter.

## Consequences
### Positive
- Provider outages degrade the product gracefully: widgets keep showing the last known truth,
  correctly labelled as old.
- The single most misleading failure — confidently stale data — is designed out rather than
  patched later.
- Conditional requests keep polling well inside rate limits, which is what makes the refresh
  ADR's short cadences sustainable.

### Negative
- Every adapter carries validator-caching, backoff and classification code; a shared
  `ProviderClient` helper is needed or this will be reimplemented four times, inconsistently.
- Staleness indicators consume scarce pixels in small widget families and constrain the design.
- Circuit breakers can mask a genuinely recovered provider until the breaker resets, delaying
  recovery by up to one reset interval.

### Neutral
- Concrete per-provider limits, header names and ETag support belong to Service Integrations, not
  here; this ADR fixes only the policy every adapter must satisfy.
- The visual treatment of staleness is Widgets' and Design System's to specify.

## Alternatives considered
- **Fail loudly: blank the widget or show an error on any refresh failure** — rejected: converts
  a brief network blip into a useless widget, which is worse than slightly old but accurate data.
- **Fixed-interval retry with no backoff and no conditional requests** — rejected: burns rate
  limit fastest exactly when a provider is already struggling, and risks secondary rate limits
  and IP-level throttling.
- **Trust the poll cadence and omit freshness indicators** — rejected: the cadence is best-effort
  and can be suspended entirely (app quit, Mac asleep), so displayed freshness cannot be inferred
  from configuration.

## References
- `.agentheim/knowledge/decisions/0006-resident-app-polling-refresh-topology.md`
- `.agentheim/contexts/service-integrations/README.md` — conformist to each platform's API and
  rate limits.
- `.agentheim/contexts/widgets/README.md`.
