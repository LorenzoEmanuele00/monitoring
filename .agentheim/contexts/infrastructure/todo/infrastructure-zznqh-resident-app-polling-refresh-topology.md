---
id: infrastructure-zznqh
title: v1 refresh is polling from a single resident menu-bar app process; webhooks and a helper daemon are deferred
status: todo
type: decision
context: infrastructure
created: 2026-08-07
completed:
depends_on: [infrastructure-x23a8, infrastructure-fskyk, infrastructure-hv013]
blocks: []
tags: [captured, architecture-foundation]
related_adrs: []
related_research: []
prior_art: []
---

## Why

Desktop widgets must stay useful with the app closed (ADR-0003), but WidgetKit grants only a
small, OS-managed number of timeline refreshes per day. Separately, notifications for deploy
start/end and PR-to-master want near-real-time latency, and there is no server here to receive
provider webhooks. The decisive fact: a running app calling `WidgetCenter.reloadTimelines` is
not constrained by the widget's own timeline budget — freshness tracks the app's poll cadence
whenever it's running, and falls back to the OS budget only when it isn't.

## What

The main app is the only moving part in v1: a login item with a menu-bar presence that owns the
full pipeline (poll → write Tier A → project Tier B snapshots → `reloadTimelines` → post
notifications). Two-speed scheduling: a baseline cadence per provider (GitHub ~2 min, Firebase
Hosting ~5 min, Supabase ~15 min) that bursts to ~30s polling (capped ~20 min) when work is
detected in flight (e.g. a GitHub Actions run in progress). A separate background helper daemon
and provider webhooks are explicitly deferred, with named triggers to revisit each — this is a
genuine tradeoff (events while the app is closed are missed, not delayed), not hand-waved.

Full ADR draft, including the deferred-mechanism triggers, is in Notes below.

## Acceptance criteria

- [ ] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: global`, matching the draft in Notes (or a user-amended version, amendments noted
      in the commit).
- [ ] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07. The architect flagged two research spikes worth running before finalizing
per-provider cadences: (1) whether Firebase Hosting's REST API even exposes "deploy started" to
a service account, or whether that signal has to come from GitHub Actions instead (the
architect's working assumption — build the GitHub adapter first); (2) WidgetKit's real-world
timeline-budget behavior on current macOS when the host app isn't running. Per-provider cadence
and burst-trigger specifics are a `service-integrations`-local follow-on decision, not fixed
here.

```markdown
---
id: TBD
title: v1 refresh is polling from a single resident menu-bar app process; webhooks and a helper daemon are deferred
scope: global
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [infrastructure-zznqh]
related_research: []
---

# ADR TBD: v1 refresh is polling from a single resident menu-bar app process; webhooks and a helper daemon are deferred

## Context
Two goals pull in opposite directions. Desktop widgets must stay useful with the app closed
(ADR-0003), but WidgetKit grants a widget only a small, OS-managed number of timeline refreshes
per day. Separately, notifications for deploy start/end and PR-to-master want near-real-time
latency, and macOS user notifications can only be posted by a running, bundled process — there
is no server and no APNs path here.

Three mechanisms were considered: polling from the main app plus WidgetKit's own timeline
reloads; a separate always-running background helper (login item / launch agent) polling more
aggressively; and provider webhooks relayed to the Mac through a public endpoint.

The decisive technical fact: a running app calling `WidgetCenter.reloadTimelines(ofKind:)` is not
constrained by the widget's own timeline budget. Widget freshness therefore tracks the app's poll
cadence whenever the app is running, and falls back to the OS budget only when it is not.

## Decision
For v1, the main app is the only moving part. It registers itself as a login item via
`SMAppService.mainApp.register()` and keeps a status-bar presence so it stays resident after its
window is closed. It owns the full pipeline: poll provider APIs → write Tier A → project Tier B
snapshots → `WidgetCenter.shared.reloadTimelines(ofKind:)` → post `UNUserNotificationCenter`
alerts for matched Notification Rules.

Scheduling is two-speed. A baseline cadence runs under `NSBackgroundActivityScheduler` (so the OS
can coalesce it and respect power and thermal state), with per-provider intervals and jitter:
GitHub ~2 min, Firebase Hosting ~5 min, Supabase ~15 min. When a poll observes work in flight — a
GitHub Actions run `queued`/`in_progress`, an unfinalised Hosting version — that Integration
enters a burst mode of ~30 s polling under a plain `Task`, hard-capped (~20 min) before reverting
to baseline. The app resyncs immediately on `NSWorkspace.didWakeNotification` and when
`NWPathMonitor` reports connectivity returning.

Widget `TimelineProvider`s read the current snapshot and return entries with a conservative
`.after(...)` policy (~15 min) purely as an app-not-running fallback. Every widget renders its
snapshot's `generatedAt` as relative time and visibly degrades past a staleness threshold.

Deferred, with explicit triggers to revisit:
- **Separate LaunchAgent/login-item helper** — revisit if the app is routinely quit, or if
  missed-while-quit events become a real annoyance. Note it must itself be a bundled
  `LSUIElement` app to post user notifications, and Tier A's SQLite WAL already supports the
  second process.
- **Webhook relay** — revisit only if sub-minute latency becomes a genuine requirement. It
  implies a public always-on endpoint and is therefore a new deploy target (see the deployment
  topology ADR).

## Consequences
### Positive
- Zero new infrastructure, one process, one signing target, one place where polling logic lives.
- ~30 s notification and widget latency during the events that actually matter (an in-flight
  deploy or a freshly opened PR), without burning rate limit while idle.
- WidgetKit's refresh budget stops being a data-freshness constraint and becomes only a
  display-freshness constraint for the app-not-running case.

### Negative
- **While the app is not running, no polling happens and no notifications fire — events in that
  window are missed, not merely delayed.** Widgets show stale data on the OS's own schedule
  (~15–60 min best effort, worst case hours).
- Baseline latency of 2–15 min for the first detection of an event, since burst mode can only
  engage after a baseline poll notices something in flight.
- Polling consumes provider rate limit continuously, even when nothing changes. Mitigated by
  conditional requests (ETag / `If-None-Match`) — see the error-handling ADR.

### Neutral
- Per-provider cadences and burst triggers are Service Integrations' decision, not this ADR's;
  this ADR fixes only the process topology and the scheduling mechanism.
- Widget staleness display is required by this decision but designed in Widgets/Design System.

## Alternatives considered
- **Rely solely on WidgetKit timeline reloads, with the extension fetching data** — rejected:
  a handful of refreshes a day is far too coarse for deploy tracking, it forces credentials and
  networking into the extension, and it delivers no notifications at all.
- **Separate background helper daemon in v1** — rejected for now: a second signing target, a
  second process contending for the store, and duplicated lifecycle handling, bought before
  there is evidence the resident app is insufficient. Cheap to add later precisely because Tier A
  is multi-process safe.
- **Provider webhooks via a public relay** — rejected for v1: it converts a zero-infrastructure
  personal tool into a system with a deployed cloud component, an inbound tunnel to the Mac, and
  a new class of secrets, in exchange for latency the user has not yet asked for.

## References
- `.agentheim/knowledge/decisions/0003-native-macos-desktop-widgets-are-core.md`
- `.agentheim/vision.md` — open question on refresh cadence.
- Apple: WidgetCenter, NSBackgroundActivityScheduler, SMAppService, UserNotifications.
```
