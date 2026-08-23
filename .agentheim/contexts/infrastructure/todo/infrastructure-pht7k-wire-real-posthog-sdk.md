---
id: infrastructure-pht7k
title: Wire the real PostHog SDK for the ADR-0010 structured event set
status: todo
type: task
context: infrastructure
created: 2026-08-14
completed:
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [walking-skeleton-followup]
related_adrs: [0010]
related_research: []
prior_art: []
---

## Why

ADR-0010 (as amended) wants PostHog wired in the main app for a narrow structured-event set:
unhandled crashes, "Integration credential expired", deploy started/ended, "Integration
disconnected" (circuit breaker). ADR-0010 explicitly allowed the walking-skeleton spike
(`infrastructure-001-walking-skeleton`) to stub this if it threatened the spike's stop-loss
(ADR-0065) — it did, so the spike shipped a no-op `AnalyticsEventLogger` protocol
(`MissionControl/Logging.swift`) with an `os.Logger`-backed stub implementation
(`NoOpAnalyticsEventLogger`) instead of the real SDK.

## What

- Add the PostHog Swift SDK as a dependency of the `MissionControl` app target only (never the
  widget extension — ADR-0004/ADR-0010).
- Implement a `PostHogAnalyticsEventLogger: AnalyticsEventLogger` and swap it in for
  `NoOpAnalyticsEventLogger` in `AppEnvironment`/`PollingCoordinator`'s composition.
- Confirm the two call sites already wired in `PollingCoordinator.pollOne` (credential-expired,
  circuit-breaker-disconnected) fire correctly, and add the two not yet wired anywhere in the
  spike: unhandled-crash reporting, deploy started/ended (deploy events don't exist yet in this
  codebase at all — likely lands together with whatever BC first models a "deploy").
- Confirm credential material never reaches PostHog, including inside error descriptions
  (ADR-0010's redaction requirement) — this was already a design constraint in the stub's
  signature (`providerKind`/`integrationID` only, no error strings), keep it that way.

## Acceptance criteria

- [ ] Real PostHog SDK sends the credential-expired and disconnected events in a manual test
      (trigger a 401 from a test/mock server or temporarily corrupt a stored credential).
- [ ] Widget extension target still does not link PostHog (verify via `project.yml`'s per-target
      package list, same structural check ADR-0004 already relies on).
- [ ] No credential material appears in any PostHog payload — spot-check by inspecting the actual
      network request bodies during the manual test.
