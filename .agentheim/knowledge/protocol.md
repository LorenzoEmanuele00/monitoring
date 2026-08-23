# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

---

## 2026-08-23 16:51 -- Task verified and completed: infrastructure-pht7k - Wire the real PostHog SDK for the ADR-0010 structured event set

**Type:** Work / Task completion
**Task:** infrastructure-pht7k - Wire the real PostHog SDK for the ADR-0010 structured event set
**Summary:** Wired the real PostHog SDK (app target only) with a graceful .env-driven fallback factory, structural redaction contract, and ADR-0017 amending ADR-0010's storage clause to a gitignored build-time .env instead of MCSecrets/Keychain
**Duration:** ~15m (16:31 dispatch -> 16:46 PASS)
**Verification:** PASS (iteration 1)
**Files changed:** 13
**Tests added:** 9
**ADRs written:** 0017

---

## 2026-08-23 16:31 -- Batch started: [infrastructure-pht7k]

**Type:** Work / Batch start
**Tasks:** infrastructure-pht7k - Wire the real PostHog SDK for the ADR-0010 structured event set
**Parallel:** no (1 worker — only one task ready this batch)

---

## 2026-08-23 16:30 -- Modeling / Refined: infrastructure-pht7k - Wire the real PostHog SDK for the ADR-0010 structured event set

**Type:** Modeling / Refine
**BC:** infrastructure
**Status after:** todo
**Summary:** Added builder-decided PostHog project setup (one shared project across monitoring/mise_pwa/mise_web, distinguished by a `system` event property) and a build-time secret-injection convention (gitignored `MissionControl/.env` + a project.yml `buildScripts` entry writing into the built Info.plist, never a committed file) to the task's Notes, so the worker doesn't have to invent the mechanism mid-task. Clarified that the acceptance criteria's live-network manual-test steps are the builder's own verification, not something the worker/verifier can execute without real credentials.
**Split into:** none
**ADRs written:** none

---

## 2026-08-23 16:14 -- Modeling / Promoted: infrastructure-pht7k - Wire the real PostHog SDK for the ADR-0010 structured event set

**Type:** Modeling / Promote
**BC:** infrastructure
**From → To:** backlog → todo

---

## 2026-08-22 18:19 -- Work session ended

**Type:** Work / Session end
**Duration:** 23m (17:56 first batch start -> 18:19)
**Completed:** 1 (first-try PASS: 0, re-dispatched: 1, skipped: 0)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Dispatches:** infrastructure-b92mn: 2
**Commits:** 3
**Vision-conformance:** none — batch aligns with vision (burst-mode polling hardens the refresh-cadence mechanism ADR-0006 already committed to, in service of the near-real-time-notifications success criterion; touches no non-goal)
**Batch mix:** 0% product-facing / 100% harness / 0% bookkeeping (1 task)
**Carry-over:** `.agentheim/.dashboard/` (runtime.json, last-port.json): left behind (owner: the `/agentheim:dashboard` launcher run earlier this session — advisory runtime state, not project bookkeeping); `.agentheim/state/` (in-flight.json, whats-next.md): left behind (owner: `work`'s own Stop-hook heartbeat, ADR-0043, plus the prior session's whats-next advisory — both advisory-write artifacts, not this session's to commit); left behind (user WIP, 1 file: `MissionControl/.DS_Store`, macOS Finder metadata, non-`.agentheim`)

---

## 2026-08-22 18:18 -- Task verified and completed: infrastructure-b92mn - Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)

**Type:** Work / Task completion
**Task:** infrastructure-b92mn - Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)
**Summary:** Implemented ADR-0006 burst polling mode with a pure, package-testable BurstPolling.decide function (MCDomain), GitHubActionsAdapter work-in-flight signal, and PollingCoordinator wiring; iteration-1 verifier FAIL (non-optional isWorkInFlight field broke Decodable for pre-existing snapshots, violating ADR-0008 last-good-wins) fixed in iteration 2 with a tolerant custom Decodable initializer and regression tests
**Duration:** ~19m (17:58 dispatch -> 18:17 PASS)
**Verification:** PASS (iteration 2)
**Files changed:** 9
**Tests added:** 17
**ADRs written:** 0016

---

## 2026-08-22 18:10 -- Verification failed: infrastructure-b92mn - Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)

**Type:** Work / Verification failure
**Task:** infrastructure-b92mn - Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)
**Iteration:** 1 of 3
**Reasons:** adding `IntegrationPayload.isWorkInFlight` as a non-optional `Codable` field breaks decoding of every pre-existing App Group snapshot (confirmed against a live snapshot file), collapsing to `nil` in `SnapshotStore` and violating ADR-0008 last-good-wins (acceptance criterion 2); a `.notModified` Integration whose ETag still matches would then never regenerate a new-format snapshot; secondary: ADR-0016 cites a nonexistent ADR-0008 filename
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-08-22 17:56 -- Batch started: [infrastructure-b92mn]

**Type:** Work / Batch start
**Tasks:** infrastructure-b92mn - Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)
**Parallel:** no (1 worker — only one task ready this batch)

---

## 2026-08-22 17:55 -- Modeling / Promoted: infrastructure-b92mn - Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min)

**Type:** Modeling / Promote
**BC:** infrastructure
**From → To:** backlog → todo

---

## 2026-08-21 00:35 -- Work session ended

**Type:** Work / Session end
**Completed:** 1 — project-registry-vnk4t (first-try PASS: 0, re-dispatched: 1, skipped: 0); board then empty — vacuum guard exit (no ready tasks; open vision questions surfaced above: Service Integration provider scope, credential storage/auth flow, refresh/polling cadence — all open since 2026-08-07)

---

## 2026-08-21 00:31 -- Task verified and completed: project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action

**Type:** Work / Task completion
**Task:** project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action
**Summary:** Made a Project's Obsidian note link fully optional (Project.obsidianNoteLink: String?, GRDB column made nullable), removed the Add-button non-empty requirement, and replaced the always-visible Vault note row with a conditional Open in Obsidian button driven by a new obsidianOpenURL computed property, per ADR-0014
**Duration:** ~9m39s
**Verification:** PASS (iteration 2)
**Files changed:** 7
**Tests added:** 6
**ADRs written:** none

---

## 2026-08-21 00:26 -- Verification failed: project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action

**Type:** Work / Verification failure
**Task:** project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action
**Iteration:** 1 of 3
**Reasons:** acceptance criterion 1 (name-only registration succeeds) has no covering test — the schema's NOT NULL removal on `obsidianNoteLink` is untested through the repository layer, criterion 2 (Obsidian link stored/read back unchanged) has no covering test — the modified RepositoryTests call site never asserts the stored link value
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-08-21 00:16 -- Batch started: [project-registry-vnk4t]

**Type:** Work / Batch start
**Tasks:** project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action
**Parallel:** no (1 worker — only one task ready this batch)
**Planning advisory:** whats-next (current): promote project-registry-vnk4t — unblocked by the styleguide shipping, continues the AddProjectSheet/token-restyle thread

---

## 2026-08-21 00:15 -- Modeling / Promoted: project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action

**Type:** Modeling / Promote
**BC:** project-registry
**From → To:** backlog → todo

---

## 2026-08-15 03:31 -- Work session ended

**Type:** Work / Session end
**Duration:** 21m (03:10 first batch start -> 03:31)
**Completed:** 2 (first-try PASS: 2, re-dispatched: 0, skipped: 0)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Dispatches:** design-system-q9vhm: 1, design-system-g3nxt: 1
**Commits:** 6
**Vision-conformance:** none — batch aligns with vision (both tasks round out the shared design-system component set and apply it to app screens, in service of "Widgets rendering Project/Integration data" and the general glanceable-cockpit polish; touches no non-goal)
**Batch mix:** 100% product-facing / 0% harness / 0% bookkeeping (2 tasks)
**Carry-over:** `.agentheim/state/in-flight.json`: left behind (owner: `work` skill's own Stop-hook heartbeat artifact, ADR-0043 — advisory, meant to be git-ignored, not this session's to commit or remove); `.agentheim/.dashboard/` (runtime.json, last-port.json): left behind (owner: the `/agentheim:dashboard` launcher run earlier this session — advisory runtime state, not project bookkeeping); left behind (user WIP, 1 file: `MissionControl/.DS_Store`, macOS Finder metadata, non-`.agentheim`)

---

## 2026-08-15 03:30 -- Task verified and completed: design-system-g3nxt - Apply design-system tokens to AddProjectSheet and ConnectIntegrationSheet

**Type:** Work / Task completion
**Task:** design-system-g3nxt - Apply design-system tokens to AddProjectSheet and ConnectIntegrationSheet
**Summary:** Restyled AddProjectSheet and ConnectIntegrationSheet to consume MCColor/MCFont/MCSpacing/MCRadius design-system tokens, matching ProjectDetailView's visual rhythm; split each into an AppEnvironment-independent Content view so both gain light/dark #Preview.
**Duration:** ~4m
**Verification:** PASS (iteration 1)
**Files changed:** 3
**Tests added:** 0
**ADRs written:** none

---

## 2026-08-15 03:22 -- Batch started: [design-system-g3nxt]

**Type:** Work / Batch start
**Tasks:** design-system-g3nxt - Apply design-system tokens to AddProjectSheet and ConnectIntegrationSheet
**Parallel:** no (1 worker — user requested sequential execution, one task at a time)

---

## 2026-08-15 03:22 -- Task verified and completed: design-system-q9vhm - Build the design draft's remaining components — usage tile, usage graph, event row, project card

**Type:** Work / Task completion
**Task:** design-system-q9vhm - Build the design draft's remaining components — usage tile, usage graph, event row, project card
**Summary:** Added the four remaining design-draft components (MCUsageMetricTile, MCUsageGraph, MCEventRow/MCEventKind, MCProjectCard) to MCDesignTokens/Components/, each with light/dark #Preview against sample data, plus one new MCColor.merged token; usage-tile 80%-degraded-threshold rule covered by a new unit test suite.
**Duration:** ~7m
**Verification:** PASS (iteration 1)
**Files changed:** 8
**Tests added:** 5
**ADRs written:** none

---

## 2026-08-15 03:10 -- Batch started: [design-system-q9vhm]

**Type:** Work / Batch start
**Tasks:** design-system-q9vhm - Build the design draft's remaining components — usage tile, usage graph, event row, project card
**Parallel:** no (1 worker — user requested sequential execution, one task at a time)

---

## 2026-08-15 03:07 -- Modeling / Promoted: design-system-g3nxt - Apply design-system tokens to AddProjectSheet and ConnectIntegrationSheet

**Type:** Modeling / Promote
**BC:** design-system
**From → To:** backlog → todo

---

## 2026-08-15 03:06 -- Modeling / Promoted: design-system-q9vhm - Build the design draft's remaining components — usage tile, usage graph, event row, project card

**Type:** Modeling / Promote
**BC:** design-system
**From → To:** backlog → todo

---

## 2026-08-15 03:10 -- Modeling / Refined: design-system-d7fk2 - Bring the app's actual look in line with the claude.ai/design draft

**Type:** Modeling / Refine
**BC:** design-system
**Status after:** split (parent removed)
**Summary:** Resolved the color-fidelity question (keep dynamic system colors, don't hardcode the draft's hex pairs) and split into two independently-workable tasks: building the draft's 4 remaining components, and restyling the two screens that still use zero design-system tokens.
**Split into:** design-system-q9vhm, design-system-g3nxt
**ADRs written:** none

---

## 2026-08-15 03:00 -- Capture / Captured: widgets-w4tqx - Real-data graph widgets for every provider, authored once and reused app+desktop

**Type:** Capture
**BC:** widgets
**Filed to:** backlog
**Summary:** User wants live widgets for every provider (Supabase/Firebase/Vercel, not just GitHub) with graphs, and wants a graph built once in-app to be reusable as a desktop widget cheaply.

---

## 2026-08-15 03:00 -- Capture / Captured: design-system-d7fk2 - Bring the app's actual look in line with the claude.ai/design draft

**Type:** Capture
**BC:** design-system
**Filed to:** backlog
**Summary:** User says the shipped app doesn't resemble their claude.ai/design draft — remaining draft components (usage tile, sparkline graph, event row, project card) never built, and two screens use zero design-system tokens.

---

## 2026-08-15 02:33 -- Task completed (verification skipped): design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend

**Type:** Work / Task completion
**Task:** design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
**Summary:** Human sign-off recorded on the v1 design-system token/component set; the styleguide gate is now released.
**Duration:** n/a (interactive sign-off, not a work-skill batch)
**Verification:** SKIPPED — human-in-the-loop checkpoint recorded interactively, not a worker/verifier run
**Files changed:** 1

---

## 2026-08-15 02:29 -- Work session ended

**Type:** Work / Session end
**Duration:** 36m
**Completed:** 1 (first-try PASS: 0, re-dispatched: 1, skipped: 0)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Dispatches:** design-system-001-styleguide: 3
**Commits:** 4
**Vision-conformance:** none — batch aligns with vision (design-system-001-styleguide ships the shared token/component vocabulary as a generic BC upstream of every frontend-bearing context, not mise_pwa-specific; touches no non-goal)
**Batch mix:** 100% product-facing / 0% harness / 0% bookkeeping (1 task)
**Carry-over:** `.agentheim/state/in-flight.json`: left behind (owner: `work` skill's own Stop-hook heartbeat artifact, ADR-0043 — advisory, meant to be git-ignored though this repo has no `.gitignore` yet to enforce it; not this session's to commit or remove); left behind (user WIP, 1 file: `MissionControl/.DS_Store`, macOS Finder metadata, non-`.agentheim`)

---

## 2026-08-15 02:27 -- Task verified, held pending human sign-off: design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend

**Type:** Work / Task completion (partial — human gate pending)
**Task:** design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
**Summary:** Defined the design-system v1 token set (`MCColor`/`MCSpacing`/`MCRadius`/`MCFont`/`MCStaleness`) and two components (`MCStatusPill`, `MCStalenessIndicator`) in `MCDesignTokens`; wired both into the in-app dashboard and the Desktop Widget with light/dark SwiftUI previews; resolved the staleness-threshold conflict as ADR-0015 (15min/60min). Acceptance criteria 1 and 2 are met and verified. Iteration 1's `xcodegen generate` regenerated `project.pbxproj` and silently dropped `infrastructure-w4dg3`'s App Groups provisioning fix — caught by the verifier, fixed in iteration 2 by adding the missing settings to `project.yml` (the xcodegen source of truth) so regeneration is now lossless, and independently re-confirmed genuine. Iteration 3 fixed a dangling `ADR-0016` citation left in that fix's own comment (re-pointed to the real, applicable ADR-0013) and a `LastUpgradeCheck` hand-patch that contradicted it.
**Duration:** 34m (01:53 batch start -> 02:27 final PASS)
**Verification:** PASS (iteration 3) — two prior FAILs, both on scope/documentation defects in the fix itself, never on the design-system substance
**Files changed:** 15
**Tests added:** 11
**ADRs written:** 0015
**Criterion 3 (human sign-off) intentionally NOT met** — this is the task's designed shape, not an incomplete run. The task file stays in `doing/` (not moved to `done/`) with a `## Ready for human review` section naming exactly what to look at and sign off on: `.agentheim/contexts/design-system/doing/design-system-001-styleguide.md`. Once sign-off is recorded there, a follow-up `modeling` or `work` pass should move it to `done/` and this becomes the styleguide gate's release, auto-promoting `project-registry-vnk4t` (and any other frontend-bearing backlog blocked on this gate) from `backlog/` to `todo/`.

---

## 2026-08-15 02:10 -- Verification failed: design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend

**Type:** Work / Verification failure
**Task:** design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
**Iteration:** 1 of 3
**Reasons:** `xcodegen generate` silently dropped provisioning settings (`REGISTER_APP_GROUPS` and others) from `project.pbxproj` that a prior session (infrastructure-w4dg3) specifically added to fix the widget's "No data yet" bug — a real regression, not a false positive; `CODE_SIGNING_ALLOWED=NO` builds can't detect it since that's the only place the setting has effect
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-08-15 02:20 -- Verification failed: design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend

**Type:** Work / Verification failure
**Task:** design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
**Iteration:** 2 of 3
**Reasons:** the iteration-1 provisioning regression is genuinely fixed (independently re-verified against the pre-regression commit) — but the fix's own `project.yml` comment cites "ADR-0016 (regeneration-losslessness)", an ADR that was never written; the task file explicitly says no new ADR was needed, so the comment asserts a decision record that doesn't exist. Secondary: a `LastUpgradeCheck` hand-patch in `project.pbxproj` contradicts the same comment's stated policy that the field should be left to drift.
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker (final iteration, 3 of 3)

---

## 2026-08-15 01:53 -- Batch started: [design-system-001-styleguide]

**Type:** Work / Batch start
**Tasks:** design-system-001-styleguide - Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
**Parallel:** no (1 worker)

---

## 2026-08-15 01:50 -- Modeling / Captured: project-registry-vnk4t - Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action

**Type:** Modeling / Capture (with decision)
**BC:** project-registry
**Filed to:** backlog (blocked from todo by the styleguide gate — auto-promotable once
`design-system-001-styleguide` ships)
**Summary:** Following the user's hands-on experience with the walking skeleton, decided the
Obsidian vault link should never be a registration requirement — it becomes a fully optional,
unparsed per-Project pointer driving exactly one behavior, an "Open in Obsidian" action via the
`obsidian://` URL scheme. No filesystem access to the vault, no security-scoped bookmark for it
(narrows ADR-0009's bookmark requirement to Source Path only). Resolves both of Project
Registry's long-open questions (vault-note parsing, vault-based Project discovery) at once.
**ADRs written:** 0014 (new); ADR-0009's `superseded_by` frontmatter updated to point here for
the vault-bookmark claim specifically (body left untouched as historical record).
**Also updated:** `vision.md` ("What success looks like" registration bullet, ubiquitous
language, one open question resolved), `context-map.md` (Project Registry purpose/core
language), `project-registry/README.md` (purpose, ubiquitous language, aggregate invariant, both
open questions resolved), `knowledge/index.md` (BC one-liner).

---

## 2026-08-15 01:10 -- Bug resolved: infrastructure-w4dg3 - widget "No data yet" root-caused

**Type:** Manual verification / interactive bugfix (resolution)
**Task:** infrastructure-w4dg3 - Desktop widget still renders "No data yet" after fixing the
.atomic cross-process read bug
**Summary:** Continued the previous session's open bug. Ruled out two more hypotheses by direct
testing — `com.apple.quarantine` (fully quit the app, stripped the xattr, verified clean, widget
still failed identically) and stale files/inodes — before finding the real root cause: xcodegen
writes `com.apple.security.application-groups` directly into the `.entitlements` files, bypassing
Xcode's Signing & Capabilities UI, which is what actually registers the capability with the Apple
Developer Portal. Automatic Signing had silently fallen back to a generic wildcard `Mac Team
Provisioning Profile: *` that cannot carry App Groups (confirmed by decoding the profile via
`security cms -D -i`). Visiting each target's Signing & Capabilities tab in Xcode triggered proper
re-provisioning; two new app-ID-specific profiles were generated, both carrying the capability,
and the widget started reading real data immediately — with quarantine still present, confirming
it was never the blocker.
**Fixed:** `SnapshotStore`'s doc comment corrected to record the true root cause (the quarantine
explanation from the prior session was wrong); `clearQuarantine` kept as harmless hygiene, not
removed. Infrastructure BC README gained a second "Provisioning caveat" entry generalizing this
finding for any future xcodegen-authored capability needing portal registration.
**Task closed:** `infrastructure-w4dg3` moved backlog → done, both acceptance criteria met.

---

## 2026-08-14 12:35 -- Manual verification: 3 real bugs found and fixed, 1 flagged unresolved

**Type:** Manual verification / interactive bugfix
**Task:** infrastructure-001-walking-skeleton (post-merge manual verification pass)
**Summary:** User worked through the walking-skeleton spike's manual verification checklist.
Found and fixed three real bugs interactively (not through the `work` worker/verifier pipeline —
direct fixes, verified via `swift test` and system-log inspection):
1. `AddProjectSheet` never called `startAccessingSecurityScopedResource()` before creating the
   source-path bookmark, deferring bookmark creation past the `.fileImporter` access window —
   fixed by creating the bookmark immediately in the completion handler via
   `BookmarkHelper.withAccess`.
2. `ConnectIntegrationSheet` used a macOS `Form`, whose automatic label/control column layout
   compressed/overflowed unlabeled rows (the instructions paragraph, the Firebase hint text) —
   replaced with an explicit leading-aligned `VStack` in a fixed-size sheet.
3. `KeychainSecretStore` passed the bare (non-Team-ID-prefixed) access group string as
   `kSecAttrAccessGroup`, never matching the entitlements' `$(AppIdentifierPrefix)`-resolved
   value — fixed by resolving the real Team ID prefix at runtime via a throwaway-keychain-item
   probe.
Also fixed, but did NOT resolve the reported symptom: `SnapshotStore` wrote Tier B files with
`Data.write(options: .atomic)`, which — confirmed via new `.error`-level `os.Logger` output added
to `readManifest()`/`readSnapshot()` — left files unreadable by the widget extension process
(`NSPOSIXErrorDomain Code=1 "Operation not permitted"`), a documented App Sandbox quirk with
atomic writes in shared App Group containers. Switched to non-atomic writes; confirmed via
`swift test` (22/22 passing) that nothing regressed. The desktop widget still shows "No data yet"
after this fix — root cause not fully found before the user asked to stop.
**Discovered, not fixed:** two backlog items from the original walking-skeleton worker session
(`infrastructure-pht7k`, `infrastructure-b92mn`) were never inserted into this BC's `INDEX.md`
backlog list during that session's end-of-run reporting — a bookkeeping gap, corrected now
alongside filing the widget bug.
**Filed:** `infrastructure-w4dg3` (bug, backlog) — desktop widget renders no data despite a
confirmed-correct write/reload pipeline; investigation notes and next steps recorded on the task.
**Not part of `work`'s worktree/verifier pipeline** — these are direct commits reviewed and
tested inline during the session, per the user's explicit "commit all the correct code" request.

---

## 2026-08-14 01:30 -- Work session ended

**Type:** Work / Session end
**Duration:** 1h48m
**Completed:** 1 (first-try PASS: 0, re-dispatched: 1, skipped: 0)
**Bounced:** 0
**Failed:** 0
**Escalated after verification:** 0
**Dispatches:** infrastructure-001-walking-skeleton: 2
**Commits:** 4 (batch start, verification-failure log, session commits) + 1 squash-merge completion commit
**Vision-conformance:** none — batch aligns with vision (delivers exactly the "mise_pwa onboarded end-to-end" success criterion; no non-goal touched — architecture stays per-Integration/per-Project generic, not mise_pwa-hardcoded)
**Batch mix:** 0% product-facing / 100% harness / 0% bookkeeping (1 task) — `type: spike` classifies as harness unconditionally under the batch-mix heuristic regardless of subject matter
**Carry-over:** .agentheim/state/in-flight.json: left behind (owner: work skill's own Stop-hook heartbeat, ADR-0027 advisory artifact — meant to stay git-ignored, not project bookkeeping to commit)

---

## 2026-08-14 01:22 -- Task verified and completed: infrastructure-001-walking-skeleton - Walking skeleton — onboard mise_pwa end-to-end through the full stack

**Type:** Work / Task completion
**Task:** infrastructure-001-walking-skeleton - Walking skeleton — onboard mise_pwa end-to-end through the full stack
**Summary:** Scaffolded the full walking-skeleton stack (Xcode app + widget extension + MissionControlKit package) implementing ADR-0004..0012 end-to-end for mise_pwa, with two verifier-driven fix iterations
**Duration:** 1h48m
**Verification:** PASS (iteration 2)
**Files changed:** 57
**Tests added:** 22
**ADRs written:** 0013

---

## 2026-08-14 01:10 -- Verification failed: infrastructure-001-walking-skeleton - Walking skeleton — onboard mise_pwa end-to-end through the full stack

**Type:** Work / Verification failure
**Task:** infrastructure-001-walking-skeleton - Walking skeleton — onboard mise_pwa end-to-end through the full stack
**Iteration:** 1 of 3
**Reasons:** RetryPolicy built and unit-tested but never wired into PollingCoordinator.pollOne (ADR-0008 backoff not actually applied), Retry-After parsed by adapters but discarded (no hard-floor honoured), BC README and PollingCoordinator doc comment overclaim both as shipped, NSBackgroundActivityScheduler (ADR-0006's named scheduling mechanism) silently replaced by a bare Task/Task.sleep loop with no recorded deviation
**Iteration hint:** likely-fixable
**Next:** re-dispatched worker

---

## 2026-08-14 00:30 -- Batch started: [infrastructure-001-walking-skeleton]

**Type:** Work / Batch start
**Tasks:** infrastructure-001-walking-skeleton - Walking skeleton — onboard mise_pwa end-to-end through the full stack
**Parallel:** no (1 worker)

---

## 2026-08-13 23:30 -- Decisions: closed all 9 architecture-foundation decision tasks

**Type:** Decision review
**Outcome:** 9 ADRs committed (ADR-0004 through ADR-0012), all 9 decision tasks moved todo → done
**BCs affected:** infrastructure (8 decisions), service-integrations (1 decision)
**Summary:** Walked the user through every decision task the 2026-08-07 architecture foundation
pass had drafted, one at a time, with amendments where the user pushed back. 8 committed
essentially as drafted: app architecture (ADR-0004), two-tier persistence (ADR-0005), resident-app
polling topology (ADR-0006), Keychain credential storage (ADR-0007), failure/staleness policy
(ADR-0008), App Sandbox + security-scoped bookmarks (ADR-0009), no-backend deployment (ADR-0011),
and the service-integrations credential model (ADR-0012, GitHub PAT / Firebase service account /
Supabase Management API PAT, OAuth deferred). One was materially amended: observability
(ADR-0010) — the original "unified logging only, no telemetry" draft was changed to a hybrid: the
user wants to standardize on PostHog for structured event/error tracking across their future
personal apps, starting here, so `os.Logger` stays for local tracing (including inside the widget
extension, which stays PostHog-free per ADR-0004's "extension links nothing heavy" rule) while
PostHog is added in the main app only for a narrow set of structured domain events
(crashes, credential-expired, deploy start/end).
**Discovery surfaced, not resolved:** reviewing `infrastructure-pcmqh` (vault/sandbox access)
surfaced a real, previously-undocumented gap — Project Registry has no defined answer for how the
app should interpret a Vault Note's freeform prose content. Logged as an open question on
`project-registry/README.md` rather than resolved on the spot; needs a proper modeling pass
before the registration flow is built.
**ADRs written:** 0004 (app architecture), 0005 (two-tier persistence), 0006 (refresh topology),
0007 (Keychain storage), 0008 (failure/staleness policy), 0009 (sandbox/bookmarks), 0010
(logging + PostHog, amended), 0011 (no backend), 0012 (service-integrations credential model)
**Unblocked:** `infrastructure-001-walking-skeleton` — all 9 of its dependencies are now done.

---

## 2026-08-07 20:45 -- Brainstorm: macOS personal cockpit dashboard

**Type:** Brainstorm
**Outcome:** vision created
**BCs identified:** project-registry, service-integrations, widgets, notifications, infrastructure, design-system
**Summary:** Socratic session established a permanent single-user macOS "cockpit" app: registers Projects from the Obsidian vault's `Progetti` folder, attaches Service Integrations (GitHub, Firebase Hosting, Supabase, Vercel, ...) per Project, and renders their status as configurable Widgets — critically including native macOS desktop widgets (WidgetKit) that work with the app closed. Observe-first with narrow Quick Actions, never a replacement for vendor dashboards. Walking-skeleton scope: onboard the real project mise_pwa end-to-end (GitHub + Firebase Hosting + Supabase, one working desktop widget). Architecture foundation pass (architect via orchestrator) recommended a native Swift/SwiftUI app + WidgetKit extension sharing an App Group and Swift package, two-tier persistence (GRDB/SQLite + JSON snapshots), Keychain credential storage, resident-app polling (webhooks/helper daemon deferred), no backend, unified logging only, sandboxed with security-scoped bookmarks for vault access, and a last-good-data-wins failure policy. User confirmed a paid Apple Developer Program membership will be used strictly for local, unsigned-for-distribution builds (no App Store submission).
**ADRs written:** 0001 (permanent single-user scope), 0002 (observe-first, not a control plane), 0003 (native desktop widgets are core)
**Foundation tasks emitted:** infrastructure-x23a8, infrastructure-fskyk, infrastructure-hv013, infrastructure-zznqh, infrastructure-wv33x, infrastructure-rxd87, infrastructure-pcmqh, infrastructure-mam0r (decision tasks, infrastructure), service-integrations-n7s2k (decision task, service-integrations), infrastructure-001-walking-skeleton (spike), design-system-001-styleguide (feature, styleguide gate)

---
