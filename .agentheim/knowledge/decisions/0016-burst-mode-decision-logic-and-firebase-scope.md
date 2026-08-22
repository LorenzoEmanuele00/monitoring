---
id: 0016
title: Burst-mode enter/exit logic is a pure, package-testable decision function; Firebase Hosting burst detection deferred until the adapter models release status
scope: infrastructure
status: accepted
date: 2026-08-22
supersedes: []
superseded_by: []
related_tasks: [infrastructure-b92mn]
related_research: []
---

# ADR 0016: Burst-mode enter/exit logic is a pure, package-testable decision function; Firebase Hosting burst detection deferred until the adapter models release status

## Context
ADR-0006 specifies burst mode (~30 s polling, hard-capped ~20 min, entered when work is
observed in flight) but leaves the concrete enter/exit mechanics and per-provider triggers
unspecified. `PollingCoordinator`, where this had to be wired, is app-target-only code — it
isn't covered by `swift test` (see the BC README's "Target/package layout"), so a naive
implementation entirely inside it would have shipped burst mode with no automated test coverage
at all, only manual/log verification.

Separately, the task's "What" section named two concrete triggers: a GitHub Actions run
`queued`/`in_progress`, and "an unfinalized Firebase Hosting release". `GitHubActionsAdapter`
already parses `status`/`conclusion` per run and could surface this trivially. But
`FirebaseHostingAdapter.poll` calls Firebase Hosting's `releases` endpoint, whose `Release`
resource does not carry an in-progress/pending status the adapter currently reads — a Hosting
`Release` represents a deploy that has already happened by the time it appears there. Modelling
"unfinalized" would mean either guessing at fields not covered by any existing test fixture, or
switching to a different Firebase Hosting API surface (Versions, which do have a
`CREATED`/`FINALIZED` status) — a real adapter change outside the shape of a burst-mode task.

## Decision
1. **Burst enter/exit is a pure function**, `BurstPolling.decide` (`MCDomain/BurstPolling.swift`):
   given (is-currently-bursting, burst-start-time, latest work-in-flight signal as `Bool?`,
   circuit-breaker-open, now), it returns `.enterBurst` / `.remainInBurst` /
   `.exitBurst(reason:)` / `.remainBaseline`. It knows nothing about `NSBackgroundActivityScheduler`,
   `Task`, or any adapter — `PollingCoordinator.pollAndAdapt` is the only caller, and owns all the
   actual scheduling side effects (invalidating/recreating the baseline activity, starting/
   cancelling the burst `Task`). This is what makes the decision logic unit-testable
   (`BurstPollingTests`, 11 cases) despite `PollingCoordinator` itself having no automated
   coverage.
2. **The work-in-flight signal is `Bool?`, not `Bool`.** `nil` means "this poll cycle carried no
   new signal" — a transient or terminal failure. Per ADR-0008's last-good-wins, a failure must
   not flip burst state in either direction on its own; only a fresh success or a not-modified
   (confirming the last-known payload) can start or end a burst.
3. **A burst exits immediately if the ADR-0008 circuit breaker opens mid-burst**
   (`BurstExitReason.circuitOpen`), and burst mode never engages for an already-open circuit.
   The breaker's threshold (`ServiceIntegration.circuitBreakerThreshold`) is untouched by burst
   mode either way — `pollOne`'s failure counting has no notion of which cadence called it — but
   letting a bursting Integration keep polling every ~30s *after* the breaker has already opened
   would burn rate limit on a provider already known to be broken, for no benefit.
4. **Firebase Hosting burst detection is out of scope for this task.** `IntegrationPayload
   .isWorkInFlight` defaults to `false` and only `GitHubActionsAdapter` sets it (for a run
   `status` of `queued`/`in_progress` with no `conclusion` yet). Extending Firebase Hosting to
   surface an in-progress signal is left for a future task once/if the adapter's data source
   changes to one that actually exposes it.

## Consequences
### Positive
- Burst mode's core logic — the part most likely to have an off-by-one or a race between the
  cap, the failure signal, and the circuit breaker — is exercised by fast, deterministic unit
  tests instead of relying solely on `os.Logger` timestamp inspection.
- The `Bool?` signal makes ADR-0008 last-good-wins an explicit, testable property of burst state
  rather than an implicit consequence of how `PollingCoordinator` happens to be wired.
- No adapter carries speculative, untested parsing of a Firebase Hosting API shape that isn't
  actually exercised by any fixture.

### Negative
- A real in-flight Firebase Hosting deploy will not trigger burst mode in this version — that
  Integration stays on its ~5 min baseline cadence until deploy completion is picked up on the
  next baseline poll, same as before this task. Detection is therefore up to ~5 min slower for
  Firebase Hosting specifically, not the ~30s ADR-0006 describes as the general goal.
- `PollingCoordinator`'s wiring around `BurstPolling.decide` (the `Task` lifecycle, the
  `NSBackgroundActivityScheduler` invalidate/recreate dance) is still only verified by build
  success and manual/log inspection, not automated tests — inherent to it being app-target code,
  not something this ADR changes.

### Neutral
- Extending `FirebaseHostingAdapter` to read Firebase Hosting's Versions API (which does carry a
  `CREATED`/`FINALIZED` status) instead of, or alongside, Releases would resolve the Negative
  above but is a Service Integrations adapter change, not a burst-mode-mechanism change — belongs
  in a separate task if picked up.

## Alternatives considered
- **Implement burst enter/exit entirely inline in `PollingCoordinator`** — rejected: leaves the
  highest-risk logic (cap math, signal-vs-no-signal handling, breaker interaction) with zero
  automated coverage, in the one part of the codebase `swift test` can't reach.
- **Guess at a Firebase Hosting "unfinalized" release shape and wire it up untested** —
  rejected: would ship parsing logic against an API shape not backed by any real response
  sample or test fixture, for a currently-hypothetical field.
- **Let a bursting Integration keep polling at burst cadence even after the circuit breaker
  opens** — rejected: the task explicitly calls out that burst must not "bypass" the breaker;
  continuing to poll a known-broken Integration every 30s instead of falling back to baseline
  cadence is the concrete way that bypass would happen.

## References
- `.agentheim/knowledge/decisions/0006-resident-app-polling-refresh-topology.md`
- `.agentheim/knowledge/decisions/0008-failure-staleness-backoff-policy.md`
- `MissionControl/MissionControlKit/Sources/MCDomain/BurstPolling.swift`
- `MissionControl/MissionControl/Polling/PollingCoordinator.swift`
