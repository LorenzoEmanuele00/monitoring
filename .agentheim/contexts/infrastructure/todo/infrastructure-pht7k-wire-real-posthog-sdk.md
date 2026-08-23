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

## Notes

**PostHog project setup (builder-provided, decided 2026-08-23):** one shared PostHog project
receives events from this app and the builder's other personal systems (mise_pwa, mise_web),
distinguished by a `system` event property this task's `PostHogAnalyticsEventLogger` must set
on every event it sends (value: `"monitoring"`). Not per-provider credentials — do not route
this through `MCSecrets`/Keychain (ADR-0007 is about Service Integration provider credentials;
the PostHog Project API Key is a write-only client key by PostHog's own design, a different
trust category).

**Build-time injection convention:** the builder will create a gitignored `MissionControl/.env`
holding `POSTHOG_API_KEY=<phc_...>` and `POSTHOG_HOST=<https://us.i.posthog.com or eu>` — the
worker does not need the actual values to implement this, only the convention. Implementation
must:
- Add `.env` to `MissionControl/.gitignore` (it does not exist there yet).
- Wire a build-time mechanism that reads `MissionControl/.env` and makes the two values
  available to `PostHogAnalyticsEventLogger` at runtime without ever writing them into a
  *committed* file (the committed `Generated/MissionControl-Info.plist` and `project.yml` stay
  free of the actual key/host values) — e.g. a `buildScripts` entry in `project.yml` (xcodegen
  supports this, survives `xcodegen generate` per ADR-0013, unlike a hand-edited pbxproj build
  phase) that sources `.env` and injects the values into the *built* Info.plist via
  `PlistBuddy`, read back at runtime via `Bundle.main.object(forInfoDictionaryKey:)`. Pick
  whatever concrete mechanism is simplest and actually testable; document the choice (ADR or
  README note) since it's the first build-time-secret-injection pattern in this codebase and
  future config values will likely reuse it.
- If `.env` is absent at build time (e.g. CI, or before the builder has created it), fail
  gracefully — `PostHogAnalyticsEventLogger` should not crash the app; falling back to a no-op
  logger with a logged warning is reasonable, consistent with the existing
  `NoOpAnalyticsEventLogger` this task is replacing.

The acceptance criteria's "manual test" steps (real 401 trigger, live network payload
inspection) are the builder's own verification once they've populated `.env` with real
values — not something the worker or verifier can execute without live credentials. Confirm the
plumbing compiles and unit-test whatever can be tested without live credentials (e.g. redaction
logic, the `system` property being set, graceful fallback when `.env` is absent); leave the
live-network criteria for the builder to check by hand afterward.
