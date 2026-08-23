---
id: infrastructure-pht7k
title: Wire the real PostHog SDK for the ADR-0010 structured event set
status: done
type: task
context: infrastructure
created: 2026-08-14
completed: 2026-08-23
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [walking-skeleton-followup]
related_adrs: [0010, 0017]
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

**Amends ADR-0010's storage clause (builder-approved 2026-08-23):** ADR-0010 currently says
"The PostHog project API key is a single app-level credential stored via `MCSecrets` (ADR-0007's
`SecretStore`)". This task deliberately does the opposite — see the `.env` convention below —
and that is an intentional, discussed override, not an oversight. **Write a new ADR recording
this** (next free number under `.agentheim/knowledge/decisions/`), titled along the lines of
"PostHog Project API Key is stored via a gitignored build-time `.env`, not `MCSecrets`/Keychain
— amends ADR-0010's storage clause". Follow the existing precedent for a partial-override ADR
(see `0015-staleness-thresholds-15-60-minutes.md`, whose title says "overriding ADR-0008's
placeholder" while `supersedes`/`superseded_by` stay `[]` on both sides — a full
supersession/deprecation is not what's happening here, just one clause changing). Justify it on
the actual trust-category distinction (write-only client key vs. read/write per-Integration
provider credential; one static app-wide value vs. per-Integration entity requiring a validation
call) — not merely "the builder asked for `.env`".

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

## Outcome

Real PostHog Swift SDK (`https://github.com/PostHog/posthog-ios`, pinned `from: 3.69.8`) wired
as a `MissionControl` app-target-only SPM dependency (`MissionControl/project.yml`'s `packages:`
+ target `dependencies:` — `MissionControlWidgets` untouched, confirmed by grep and by the
extension's built `.appex` containing no PostHog bundle in a real `xcodebuild build`).

- `MissionControl/MissionControlKit/Sources/MCDomain/AnalyticsEvent.swift` — pure,
  PostHog-SDK-independent event shape. `AnalyticsEvent.credentialExpired`/
  `.integrationDisconnected` stamp `system: "monitoring"` (builder's shared-project setup) and
  accept only `providerKind`/`integrationID`, making the ADR-0010 redaction contract structural.
- `MissionControl/MissionControlKit/Sources/MCDomain/AnalyticsConfiguration.swift` — pure
  `.resolve(apiKey:host:)` — `nil` when either value is missing/blank, the graceful-fallback
  signal.
- `MissionControl/MissionControl/PostHogAnalyticsEventLogger.swift` — `PostHogAnalyticsEventLogger`
  (real `AnalyticsEventLogger` impl, calls `PostHogSDK.shared.capture`) +
  `AnalyticsEventLoggerFactory.make()` (reads `PostHogAPIKey`/`PostHogHost` from
  `Bundle.main`'s Info.plist, sets up the SDK with `errorTrackingConfig.autoCapture = true` for
  ADR-0010's unhandled-crash event, or falls back to `NoOpAnalyticsEventLogger` with a logged
  warning). Composed into `PollingCoordinator` via `AppEnvironment.swift`.
- `MissionControl/project.yml` — PostHog SPM package declaration, `MissionControl`-only
  dependency entry, and a `postBuildScripts` phase that sources gitignored `MissionControl/.env`
  and injects `POSTHOG_API_KEY`/`POSTHOG_HOST` into the *built* Info.plist via `PlistBuddy`
  (never into the committed `Generated/MissionControl-Info.plist`); falls back to a logged
  warning + `exit 0` when `.env` is absent/incomplete. `MissionControl/.gitignore` gained `.env`.
  `xcodegen generate` re-run; regenerated `MissionControl.xcodeproj/project.pbxproj` committed
  alongside per ADR-0013.
- `.agentheim/knowledge/decisions/0017-posthog-key-via-gitignored-env-not-mcsecrets.md` — the
  required ADR amending ADR-0010's storage clause (builder-approved 2026-08-23).

**Deploy started/ended events are not wired** — no "deploy" domain concept exists anywhere in
this codebase yet (per the task's own "What" section); that pair lands together with whichever
BC first models a deploy. The two already-wired call sites (credential-expired,
circuit-breaker-disconnected in `PollingCoordinator.pollOne`) now flow through the real
`PostHogAnalyticsEventLogger` unchanged in shape.

**Verification performed:**
- `swift test --package-path MissionControl/MissionControlKit`: 70/70 passing (9 new —
  `AnalyticsEventTests`, `AnalyticsConfigurationTests` — 0 regressions).
- `xcodebuild build -project MissionControl.xcodeproj -scheme MissionControl -destination
  'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`: **BUILD SUCCEEDED** (real
  build, not just `xcodegen generate` — resolved the PostHog SPM package over the network,
  compiled and linked both `MissionControl.app` and `MissionControlWidgets.appex`). The
  `postBuildScripts` phase ran and correctly logged the "`.env` not found" fallback warning,
  confirming the graceful-degradation path end-to-end at the build-system level (no `.env`
  exists in this worktree, by design — the worker was never given real PostHog credentials, per
  the task's own instructions).
- The three acceptance-criteria checkboxes above were **not** hand-ticked: per the task's own
  Notes, the "manual test" bullets (real 401 trigger, live PostHog network payload inspection)
  require live PostHog credentials in a real `.env` and are explicitly the builder's own
  verification to perform once populated, not something reproducible in this environment. The
  second bullet (widget extension doesn't link PostHog) *was* independently verified above via
  both static `project.yml` inspection and the built `.appex`'s actual contents.

Environment note: the build machine's disk briefly hit `ENOSPC` mid-task (root volume at ~95-98%
capacity) while resolving the GRDB submodule checkout; resolved by clearing the (regenerable,
non-source) `~/Library/Developer/Xcode/DerivedData/MissionControl-*` build cache, not by
touching anything in the repo. Not a code issue — noted here only in case disk pressure recurs
for a future task on this machine.
