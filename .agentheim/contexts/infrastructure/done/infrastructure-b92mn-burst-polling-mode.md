---
id: infrastructure-b92mn
title: Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)
status: done
type: task
context: infrastructure
created: 2026-08-14
completed: 2026-08-22
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [walking-skeleton-followup]
related_adrs: [0006, 0008, 0016]
related_research: []
prior_art: []
---

## Why

ADR-0006 specifies two-speed scheduling: a baseline cadence per provider (GitHub ~2 min, Firebase
Hosting ~5 min, Supabase ~15 min, with jitter) plus a burst mode — when work is observed in
flight (a GitHub Actions run queued/in_progress, an unfinalised Hosting version), that Integration
bursts to ~30s polling under a plain `Task`, capped at ~20 minutes before reverting to baseline.

`infrastructure-001-walking-skeleton`'s `PollingCoordinator`
(`MissionControl/MissionControl/Polling/PollingCoordinator.swift`) implements the baseline
cadence, jitter, and wake/connectivity resync in full, but does NOT implement burst mode — this
was a deliberate stop-loss call (ADR-0065) to keep the spike's polling pipeline provably correct
rather than gold-plated. The task's acceptance criteria ("a real change on at least one provider
... results in the widget's displayed data updating within one baseline poll interval") only
requires baseline cadence to hold, which it does.

## What

- Detect "work in flight" per provider from the existing `IntegrationPayload`/adapter response
  shape — e.g. GitHub Actions `status` of `queued`/`in_progress` (already parsed in
  `GitHubActionsAdapter`, just not surfaced as a burst signal today), an unfinalized Firebase
  Hosting release.
- When detected, replace that Integration's `Task`-based baseline sleep loop with a ~30s cadence
  for up to ~20 minutes (capped, per ADR-0006), then revert to baseline automatically.
- Make sure burst mode composes cleanly with the existing wake/connectivity resync and the
  ADR-0008 circuit breaker (a bursting Integration that starts failing should still trip the
  breaker on the same threshold, not bypass it via faster polling).

## Acceptance criteria

- [x] A GitHub Actions run observed as `in_progress` causes that Integration to poll at ~30s
      cadence (verify via `os.Logger`'s `polling` category timestamps) until it completes or
      20 minutes elapse, then reverts to the ~2min baseline.
- [x] Existing walking-skeleton behavior (baseline cadence, jitter, wake/connectivity resync,
      last-good-wins on failure) is unchanged for Integrations with no work in flight.

## Outcome

Implemented ADR-0006's burst polling mode. The enter/stay/exit decision is a pure function,
`BurstPolling.decide` (`MissionControl/MissionControlKit/Sources/MCDomain/BurstPolling.swift`),
taking (currently-bursting?, burst-start-time, work-in-flight signal as `Bool?`, circuit-breaker
state, now) and returning `.enterBurst` / `.remainInBurst` / `.exitBurst(reason:)` /
`.remainBaseline` — provider- and scheduler-agnostic, unit-tested at package level
(`BurstPollingTests`, 11 cases covering enter/exit/cap/circuit-breaker/nil-signal semantics).

`GitHubActionsAdapter.poll` now sets the new `IntegrationPayload.isWorkInFlight` field
(`MCDomain/PollOutcome.swift`) to `true` for a run `status` of `queued`/`in_progress` with no
`conclusion` yet — covered by three new `GitHubActionsAdapterTests` cases. Firebase
Hosting/Supabase adapters leave it at the default `false`; extending Firebase Hosting is
deferred (see ADR-0016) since the adapter's current data source (Hosting `releases`) doesn't
expose an in-progress state at all.

`PollingCoordinator` (`MissionControl/MissionControl/Polling/PollingCoordinator.swift`) wires
the mechanism: `pollAndAdapt` runs one poll cycle via `pollOne` (now returning a `PollResult`
carrying the work-in-flight signal and circuit-breaker state), feeds `BurstPolling.decide`, and
acts on the result. `enterBurstMode` invalidates the Integration's baseline
`NSBackgroundActivityScheduler` activity and starts a plain `Task` (`runBurstLoop`) polling every
`BurstPolling.interval` (~30s); `exitBurstMode` cancels that `Task` and calls `scheduleBaseline`
again, restoring the ~2/5/15 min baseline cadence unchanged. Baseline scheduling, jitter,
wake/connectivity resync, and last-good-wins on failure are otherwise untouched — `pollAndAdapt`
is a thin wrapper around the pre-existing `pollOne` body, and `rescheduleAll` now also tears down
any live burst `Task`s so `integrationsChanged()` can't leak them.

`PollingCoordinator` itself is app-target code, not covered by `swift test` (per the BC README's
target/package layout) — its wiring is verified by `xcodebuild build` succeeding for both the
`MissionControl` and `MissionControlWidgets` targets (signing disabled) plus code review against
the acceptance criteria; the decision logic it calls into is what carries automated coverage.

Key files:
- `MissionControl/MissionControlKit/Sources/MCDomain/BurstPolling.swift` (new)
- `MissionControl/MissionControlKit/Sources/MCDomain/PollOutcome.swift` (`isWorkInFlight` field)
- `MissionControl/MissionControlKit/Sources/MCProviders/GitHubActionsAdapter.swift`
- `MissionControl/MissionControl/Polling/PollingCoordinator.swift`
- `MissionControl/MissionControlKit/Tests/MCDomainTests/BurstPollingTests.swift` (new)
- `MissionControl/MissionControlKit/Tests/MCProvidersTests/GitHubActionsAdapterTests.swift`
- `.agentheim/knowledge/decisions/0016-burst-mode-decision-logic-and-firebase-scope.md` (new)
- `.agentheim/contexts/infrastructure/README.md` (burst mode mechanism section)

`swift test --package-path MissionControl/MissionControlKit`: 58 tests, 0 failures (14 new:
11 `BurstPollingTests` + 3 `GitHubActionsAdapterTests`).

## Verifier note (iteration 1)

**VERDICT: FAIL**

**REASONS:**
- Acceptance criterion 2 ("Existing walking-skeleton behavior (baseline cadence, jitter, wake/connectivity resync, last-good-wins on failure) is unchanged for Integrations with no work in flight") is violated by the diff, not merely uncovered. `MissionControl/MissionControlKit/Sources/MCDomain/PollOutcome.swift:42` adds `public var isWorkInFlight: Bool` as a NON-optional stored property on the `Codable` Tier B DTO `IntegrationPayload`, with the default only on the initializer (`:44`) and no custom `init(from:)`. Swift's synthesized `Decodable` therefore requires the key to be present, so every already-written snapshot file under the App Group becomes undecodable.
- Empirically confirmed, not inferred: the user's live snapshot `~/Library/Group Containers/<group>/Snapshots/177DD845-CF42-43AB-857E-D6893DFDEE44.json` (written 2026-08-22 17:42, i.e. before this commit) contains `"payload":{"detail":...,"headline":...,"isAttentionNeeded":false}` with no `isWorkInFlight`. Compiling the diff's own `MCDomain` + `MCSnapshot` sources and decoding that exact file yields `DecodingError.keyNotFound: Key 'isWorkInFlight' not found ... Path: payload`.
- Downstream effect 1 (last-good-wins broken): `MCSnapshot/SnapshotStore.swift:79-89` collapses that throw to `nil`, so after this change the widget extension reads `nil` for all three existing Integrations — the last-good snapshot is effectively cleared, which is exactly what ADR-0008 rule 1 forbids ("a failed refresh never overwrites or clears a good snapshot") and what criterion 2 asserts is unchanged.
- Downstream effect 2 (self-healing blocked, worse than a one-cycle blip): `PollingCoordinator.swift:285` rewrites the snapshot on `.notModified` only `if let existing = snapshotStore.readSnapshot(...)`. Since that now returns `nil` for old-format files, a GitHub/Supabase Integration whose ETag still matches will 304 forever and never regenerate a new-format snapshot — the widget stays at "No data yet" indefinitely, not until the next poll. This is the same class of bug as `infrastructure-w4dg3`.
- No test in the diff would catch this: `SnapshotStoreTests.manifestAndSnapshotRoundTrip` encodes and decodes with the new type, so it can never observe a pre-field-addition file. `swift test --package-path MissionControl/MissionControlKit` passes (exit 0, 58 tests, 0 failures) — the suite is simply blind to this regression.
- Secondary: ADR-0016's `## References` cites `.agentheim/knowledge/decisions/0008-failure-policy-last-good-data-wins.md`, which does not exist on disk. The real file is `.agentheim/knowledge/decisions/0008-failure-staleness-backoff-policy.md`. Broken reference in a durable record.

**SUGGESTED_FIX:** Make `IntegrationPayload` tolerate snapshots written before this field existed — add a custom `init(from:)` that uses `decodeIfPresent(Bool.self, forKey: .isWorkInFlight) ?? false` (same treatment worth considering for `isAttentionNeeded`), and add a regression test in `SnapshotStoreTests`/`MCDomainTests` that decodes a literal pre-field-addition snapshot JSON fixture and asserts it succeeds with `isWorkInFlight == false`. Also fix ADR-0016's References path to `0008-failure-staleness-backoff-policy.md`.

**ITERATION_HINT:** likely-fixable

## Fix (iteration 2)

Addressed every item in the verifier note above:

- `IntegrationPayload` (`MissionControl/MissionControlKit/Sources/MCDomain/PollOutcome.swift`)
  now has a custom `init(from decoder:)` alongside the existing memberwise `init(...)`. The
  decoder path does `decodeIfPresent(Bool.self, forKey: .isWorkInFlight) ?? false`, so a
  pre-field-addition snapshot (no `isWorkInFlight` key at all) decodes successfully instead of
  throwing `keyNotFound` — restoring ADR-0008's last-good-wins for Integrations whose Tier B
  file predates this feature, and unblocking the `.notModified` self-heal path in
  `PollingCoordinator.swift` that depends on `readSnapshot` returning non-nil.
- Added `PollOutcomeTests.decodesPayloadMissingIsWorkInFlightKeyAsFalse` (new file
  `MissionControl/MissionControlKit/Tests/MCDomainTests/PollOutcomeTests.swift`), which decodes a
  literal JSON fixture with no `isWorkInFlight` key straight through `JSONDecoder` (exercising
  `Decodable`, not the convenience initializer) and asserts `isWorkInFlight == false`. Also added
  a companion case asserting the key, when present, decodes correctly. This is the test the
  verifier confirmed would have caught the regression.
- Added `SnapshotStoreTests.readSnapshotToleratesPayloadWrittenBeforeIsWorkInFlightExisted`
  (`MissionControl/MissionControlKit/Tests/MCSnapshotTests/SnapshotStoreTests.swift`), which
  writes a raw legacy-shaped `IntegrationSnapshot` JSON file directly to the App Group snapshots
  directory (bypassing `writeSnapshot`, since that always encodes the new field) and asserts
  `SnapshotStore.readSnapshot` returns it non-nil with `isWorkInFlight == false` — reproducing
  the exact scenario the verifier found empirically against the user's live snapshot file.
- Fixed ADR-0016's `## References` entry from the nonexistent
  `0008-failure-policy-last-good-data-wins.md` to the real
  `.agentheim/knowledge/decisions/0008-failure-staleness-backoff-policy.md`.

`swift test --package-path MissionControl/MissionControlKit`: 61 tests, 0 failures, exit 0
(added: `PollOutcomeTests` x2, `SnapshotStoreTests` x1 — 3 new tests total this iteration).
