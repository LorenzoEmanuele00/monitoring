# Index

Top-level catalog of this project's bounded contexts, global decisions, and research.
For BC-scoped artifacts, see each BC's `INDEX.md`.

> Updated by: `modeling` (BC creation), `work` (global ADRs), `research` (reports tagged global / cross-BC), backfill script.
> Hand-edits are fine but the skills will append at the section markers below.

---

## Bounded contexts

<!-- bc-list:start -->
- **design-system** — the macOS app's and widgets' shared visual language, tokens, components, and the review gate before any BC builds frontend — `contexts/design-system/INDEX.md`
- **infrastructure** — globally-true tech concerns: runtime/platform, secrets, scheduling, shared persistence, WidgetKit scaffolding — `contexts/infrastructure/INDEX.md`
- **notifications** — watches Events from Service Integrations and Project Registry, raises macOS Notification Center alerts — `contexts/notifications/INDEX.md`
- **widgets** — configurable views of Project/Integration data, in-app and as native macOS desktop widgets — `contexts/widgets/INDEX.md`
- **service-integrations** — connects to GitHub, Firebase Hosting, Supabase, Vercel and future providers; normalizes status/usage/events — `contexts/service-integrations/INDEX.md`
- **project-registry** — registers Projects by name, optionally linked to a source folder and/or an Obsidian note, and owns their attached Service Integrations — `contexts/project-registry/INDEX.md`
<!-- bc-list:end -->

## Global ADRs (scope: global)

<!-- adr-global:start -->
- **0017** — PostHog Project API Key stored via gitignored build-time `.env`, not `MCSecrets`/Keychain — amends ADR-0010's storage clause — 2026-08-23 — `knowledge/decisions/0017-posthog-key-via-gitignored-env-not-mcsecrets.md`
- **0015** — Staleness thresholds resolved at 15 min (subdued) / 60 min (flagged), overriding ADR-0008's placeholder — 2026-08-15 — `knowledge/decisions/0015-staleness-thresholds-15-60-minutes.md`
- **0011** — No backend — single locally-built signed macOS app bundle — 2026-08-13 — `knowledge/decisions/0011-no-backend-local-signed-app-bundle.md`
- **0010** — Unified logging + PostHog for structured domain events (amended) — 2026-08-13 — `knowledge/decisions/0010-unified-logging-plus-posthog-for-structured-events.md`
- **0009** — App Sandbox stays on; vault/source access via security-scoped bookmarks — 2026-08-13 — `knowledge/decisions/0009-sandbox-security-scoped-bookmarks.md`
- **0008** — Failure policy: last-good-data-wins, visible staleness, rate-limit/backoff — 2026-08-13 — `knowledge/decisions/0008-failure-staleness-backoff-policy.md`
- **0007** — Credentials in the macOS keychain behind a shared access group — 2026-08-13 — `knowledge/decisions/0007-keychain-secret-storage-shared-access-group.md`
- **0006** — v1 refresh is polling from a single resident menu-bar app process — 2026-08-13 — `knowledge/decisions/0006-resident-app-polling-refresh-topology.md`
- **0005** — Two-tier persistence: GRDB/SQLite + JSON snapshot files — 2026-08-13 — `knowledge/decisions/0005-two-tier-persistence-grdb-snapshot-files.md`
- **0004** — Native Swift/SwiftUI app + WidgetKit extension sharing an App Group — 2026-08-13 — `knowledge/decisions/0004-native-swiftui-app-widgetkit-extension-app-group.md`
- **0003** — Native macOS desktop widgets are a core product requirement — 2026-08-07 — `knowledge/decisions/0003-native-macos-desktop-widgets-are-core.md`
- **0002** — Observe-first cockpit with narrow quick actions, not a control plane — 2026-08-07 — `knowledge/decisions/0002-observe-first-cockpit-not-a-control-plane.md`
- **0001** — Permanent single-user, personal-tool scope — 2026-08-07 — `knowledge/decisions/0001-permanent-single-user-personal-tool.md`
<!-- adr-global:end -->

## Cross-BC research

Research reports relevant to more than one BC (or to the project as a whole). BC-specific
reports are listed in each BC's `INDEX.md`.

<!-- research-global:start -->
<!-- research-global:end -->

## Pointers

- Vision: `vision.md`
- Context map: `context-map.md`
- Protocol (chronological log): `knowledge/protocol.md` — newest entries on top
- All ADRs: `knowledge/decisions/`
- All research: `knowledge/research/`
