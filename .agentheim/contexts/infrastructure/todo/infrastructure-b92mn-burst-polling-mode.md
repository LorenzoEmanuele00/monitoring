---
id: infrastructure-b92mn
title: Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)
status: todo
type: task
context: infrastructure
created: 2026-08-14
completed:
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [walking-skeleton-followup]
related_adrs: [0006, 0008]
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

- [ ] A GitHub Actions run observed as `in_progress` causes that Integration to poll at ~30s
      cadence (verify via `os.Logger`'s `polling` category timestamps) until it completes or
      20 minutes elapse, then reverts to the ~2min baseline.
- [ ] Existing walking-skeleton behavior (baseline cadence, jitter, wake/connectivity resync,
      last-good-wins on failure) is unchanged for Integrations with no work in flight.
