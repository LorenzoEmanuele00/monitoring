# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

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
