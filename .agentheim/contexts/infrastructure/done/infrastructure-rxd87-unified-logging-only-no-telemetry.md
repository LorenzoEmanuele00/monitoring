---
id: infrastructure-rxd87
title: Observability is Apple unified logging only — no telemetry, no log files, no crash reporting
status: done
type: decision
context: infrastructure
created: 2026-08-07
completed: 2026-08-13
depends_on: [infrastructure-x23a8]
blocks: []
tags: [captured, architecture-foundation, amended]
related_adrs: [0010]
related_research: []
prior_art: []
---

## Why

The app runs on one machine owned by the only person who will ever debug it (ADR-0001), with no
backend to ship telemetry to. It still has real observability needs: a background poller and a
widget extension both do invisible work, and "the widget shows old data" must be diagnosable
after the fact.

## What

Use `os.Logger` exclusively — one subsystem, one category per bounded context plus one for the
widget extension, with deliberate log levels and `OSSignposter` around each provider poll.
Credential material is never logged at any level, including inside error descriptions (mapped to
a redacted domain error first). No analytics SDK, no crash reporting service, no self-managed
rotating log files. A "Copy diagnostics" action collects a bounded log window on demand.

Full ADR draft is in Notes below.

## Acceptance criteria

- [x] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: global`, matching the draft in Notes (or a user-amended version, amendments noted
      in the commit) — committed as ADR-0010, **amended**: the draft's "no telemetry" stance was
      overridden per user intent to standardize on PostHog across future apps. Final decision is
      a hybrid — `os.Logger` everywhere (including the widget extension) for local tracing, plus
      PostHog in the main app only for a narrow set of structured domain events (crashes,
      credential-expired, deploy start/end). See ADR-0010 for the full reasoning.
- [x] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07.

```markdown
---
id: TBD
title: Observability is Apple unified logging only — no telemetry, no log files, no crash reporting
scope: global
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [infrastructure-rxd87]
related_research: []
---

# ADR TBD: Observability is Apple unified logging only — no telemetry, no log files, no crash reporting

## Context
The app runs on exactly one machine, owned by the only person who will ever debug it (ADR-0001),
and has no backend to ship data to (see the deployment topology ADR). It nonetheless has real
observability needs: a background poller and a widget extension both do work the user never
directly watches, and "the widget shows old data" must be diagnosable after the fact.

## Decision
Use Apple's unified logging exclusively, via `os.Logger`. One subsystem (the app's bundle
identifier), one category per bounded context plus one for the widget extension. Levels are used
deliberately: `.debug` for poll-loop detail (not persisted by default), `.info` for state
transitions, `.error` for handled failures, `.fault` for invariant violations. Signposts
(`OSSignposter`) wrap each provider poll so latency is measurable in Instruments.

Every log site that touches provider data uses explicit privacy annotations: fields safe to read
are marked `.public`, everything else stays private by default, and credential material is never
logged at any level or in any form — including inside error descriptions, which must be mapped to
a redacted domain error before logging.

The app ships a "Copy diagnostics" action that collects a bounded window of unified-log output
for the subsystem into the clipboard or a temp file on demand.

No analytics SDK, no crash reporting service, no self-managed rotating log files.

## Consequences
### Positive
- Zero dependencies, zero configuration, zero cost; works identically in the app and the widget
  extension, which is where post-hoc debugging is otherwise hardest.
- Console.app and `log show` give filtering, streaming and historical query for free.
- Signposts make "which provider is slow" answerable without adding timing code.

### Negative
- Logs are ephemeral and bounded by the system log store; a problem noticed days later may have
  aged out.
- Crashes must be diagnosed from macOS's own crash reports rather than a symbolicated dashboard.
- Privacy annotations are easy to forget, and a forgotten one silently redacts a field you needed
  — this costs occasional debugging time.

### Neutral
- If a persistent audit trail of provider events is ever wanted, that is domain data belonging in
  Tier A, not a logging concern, and does not reopen this decision.

## Alternatives considered
- **A logging library (SwiftyBeaver, CocoaLumberjack) writing rotating files** — rejected:
  a dependency and a file-management problem to replicate what the OS already does better,
  including across process boundaries.
- **A hosted telemetry/crash service** — rejected: requires a backend relationship and sends a
  single user's personal project data off-machine for no benefit.
```
