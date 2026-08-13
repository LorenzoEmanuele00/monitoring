# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

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
