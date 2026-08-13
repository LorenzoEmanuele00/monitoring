---
id: 0010
title: Local unified logging for tracing, PostHog for structured domain events in the main app only
scope: global
status: accepted
date: 2026-08-13
supersedes: []
superseded_by: []
related_tasks: [infrastructure-rxd87]
related_research: []
---

# ADR 0010: Local unified logging for tracing, PostHog for structured domain events in the main app only

## Context
The app runs on exactly one machine, owned by the only person who will ever debug it (ADR-0001),
and has no backend of its own (ADR-0006's "no backend" decision — see also the deployment
topology ADR). It nonetheless has real observability needs: a background poller and a widget
extension both do work the user never directly watches, and "the widget shows old data" must be
diagnosable after the fact. Apple's unified logging covers this well but is ephemeral — the
system log store ages out, so a problem noticed days later may already be gone.

Separately, the user intends to standardize on PostHog for structured event/error tracking across
future personal apps, and wants to adopt it starting with this project rather than bolting it on
later. PostHog is a cloud SaaS (unless self-hosted): sending it data is a meaningful departure
from "nothing leaves this Mac," and it carries real SDK weight that the widget extension — which
ADR-0004 deliberately keeps free of anything but snapshot-reading code — should not absorb.

## Decision
Two channels, split by what each is good at, not a full replacement of one by the other.

**Local tracing — `os.Logger`, everywhere, including the widget extension.** One subsystem (the
app's bundle identifier), one category per bounded context plus one for the widget extension.
Levels used deliberately: `.debug` for poll-loop detail, `.info` for state transitions, `.error`
for handled failures, `.fault` for invariant violations. `OSSignposter` wraps each provider poll
for Instruments-visible latency. A "Copy diagnostics" action collects a bounded log window on
demand. This is the only observability path inside the widget extension — PostHog is not linked
there, preserving ADR-0004's "extension links nothing heavy" rule.

**Structured domain events — PostHog, main app process only.** A narrow, explicit event set is
sent to PostHog from `MissionControl.app`: unhandled crashes/exceptions, and named domain events
that Notifications already cares about (`Integration credential expired`, deploy started/ended,
Integration disconnected via the circuit breaker in the failure-policy ADR). This is not general
app logging and not user/product analytics — there is exactly one user (ADR-0001), so
funnels/cohorts/session-replay have no target. It exists purely to give persistent, searchable
history beyond what the local log store retains, and to standardize the pattern across the user's
future apps.

Every log site and every PostHog event that touches provider data uses explicit privacy handling.
Fields safe to read are sent/logged plainly; everything else stays out. Credential material is
never logged or sent to PostHog at any level or in any form — including inside error
descriptions, which must be mapped to a redacted domain error before either channel sees them.
This rule is stricter for PostHog than for local logs, since PostHog data leaves the Mac.

Implementation detail, not fixed by this ADR: PostHog Cloud (hosted) is the default, consistent
with how this project already consumes GitHub/Firebase/Supabase as external SaaS rather than
self-hosting; a self-hosted PostHog instance is a drop-in swap of the ingestion URL if that's
ever preferred. The PostHog project API key is a single app-level credential stored via
`MCSecrets` (ADR-0007's `SecretStore`), not per-Integration.

No crash reporting service beyond PostHog's own crash capture, and no self-managed rotating log
files.

## Consequences
### Positive
- Zero-dependency, zero-config tracing (`os.Logger`) stays available everywhere, including the
  one place (the widget extension) where adding an SDK is most expensive.
- Structured events survive past the local log store's retention window and are searchable,
  fixing the main weakness of unified logging alone.
- Establishes one consistent event-tracking pattern the user can reuse in future apps, rather than
  designing it from scratch each time.
- Signposts still make "which provider is slow" answerable without adding timing code.

### Negative
- Introduces a real cloud dependency and a third-party SDK into the main app — a departure from
  the fully local, zero-external-service posture the rest of this project otherwise holds to.
- A second place (beyond the four Service Integration providers) where credential-adjacent data
  could leak if a redaction rule is missed — the cost of a forgotten redaction is now "sent to a
  third party," not just "wrote to a local file only the user reads."
- Two logging paths to keep straight: a bug fixed by "just add an `os.Logger` call" is easy to
  reach for by habit, when the event actually belongs in the structured PostHog set (or vice
  versa).
- Local unified-log limitations remain for everything not promoted to a PostHog event: still
  ephemeral, still bounded by the system log store.

### Neutral
- If a persistent audit trail of *all* provider events is ever wanted (not just the notable
  subset), that is domain data belonging in Tier A, not a logging or PostHog concern, and does
  not reopen this decision.
- Self-hosted vs. PostHog Cloud is an operational choice, not an architectural one — either way,
  the app talks to one HTTPS ingestion endpoint via the PostHog SDK.

## Alternatives considered
- **`os.Logger` only, no PostHog (the original draft)** — rejected per the user's explicit intent
  to standardize on PostHog across future apps, starting here; still the simpler and more
  "purely local" option if that intent changes.
- **PostHog everywhere, including the widget extension, replacing `os.Logger`** — rejected: pulls
  a real SDK and a network dependency into the extension's tight budget, directly against ADR-0004,
  and buys nothing the extension needs (it has no domain events of its own to report — it only
  renders snapshots).
- **A logging library (SwiftyBeaver, CocoaLumberjack) writing rotating files** — rejected: a
  dependency and a file-management problem to replicate what the OS already does better, and does
  not solve the "history ages out" problem PostHog was chosen for.

## References
- `.agentheim/knowledge/decisions/0001-permanent-single-user-personal-tool.md`
- `.agentheim/knowledge/decisions/0004-native-swiftui-app-widgetkit-extension-app-group.md` —
  "extension links nothing heavy."
- `.agentheim/knowledge/decisions/0007-keychain-secret-storage-shared-access-group.md` — where
  the PostHog API key is stored.
- `.agentheim/knowledge/decisions/0008-failure-staleness-backoff-policy.md` — the domain events
  (credential expired, circuit breaker tripped) that become PostHog events.
