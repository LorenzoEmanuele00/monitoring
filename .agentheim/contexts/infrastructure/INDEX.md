# Infrastructure — Index

Catalog of everything in this bounded context: tasks by status, ADRs scoped to this BC,
research touching this BC, and concept synthesis pages.

> Updated by: `modeling` (tasks), `work` (BC-scoped ADRs, concept page links), `research` (BC-scoped reports).

---

## Tasks by status

<!-- task-counts:start -->
- **Backlog:** 0
- **Todo:** 0
- **Doing:** 1
- **Done:** 11
<!-- task-counts:end -->

### Todo
<!-- todo-list:start -->
<!-- todo-list:end -->

### Doing
<!-- doing-list:start -->
- **infrastructure-pht7k** — Wire the real PostHog SDK for the ADR-0010 structured event set (task) — `doing/infrastructure-pht7k-wire-real-posthog-sdk.md`
<!-- doing-list:end -->

### Done (most recent first; older entries kept for prior-art search)
<!-- done-list:start -->
- **infrastructure-b92mn** — Implement ADR-0006's burst polling mode (work-in-flight detection -> ~30s cadence, capped ~20min) (task) — `done/infrastructure-b92mn-burst-polling-mode.md`
- **infrastructure-w4dg3** — Desktop widget "No data yet" root-caused to a wildcard provisioning profile missing App Groups — `done/infrastructure-w4dg3-widget-shows-no-data-after-fix.md`
- **infrastructure-001-walking-skeleton** — Walking skeleton — onboard mise_pwa end-to-end through the full stack (spike) — `done/infrastructure-001-walking-skeleton.md`
- **infrastructure-wv33x** — No backend — single locally-built signed macOS app bundle — ADR-0011 — `done/infrastructure-wv33x-no-backend-local-signed-app-bundle.md`
- **infrastructure-rxd87** — Observability: unified logging + PostHog for structured events (amended) — ADR-0010 — `done/infrastructure-rxd87-unified-logging-only-no-telemetry.md`
- **infrastructure-pcmqh** — Keep the App Sandbox on; vault/source access via security-scoped bookmarks — ADR-0009 — `done/infrastructure-pcmqh-sandbox-security-scoped-bookmarks.md`
- **infrastructure-mam0r** — Failure policy — last-good data wins, staleness visible, rate-limited/flaky providers — ADR-0008 — `done/infrastructure-mam0r-failure-staleness-backoff-policy.md`
- **infrastructure-hv013** — Credentials in the macOS keychain behind a shared access group — ADR-0007 — `done/infrastructure-hv013-keychain-secret-storage-shared-access-group.md`
- **infrastructure-zznqh** — v1 refresh is polling from a single resident menu-bar app; webhooks/helper daemon deferred — ADR-0006 — `done/infrastructure-zznqh-resident-app-polling-refresh-topology.md`
- **infrastructure-fskyk** — Two-tier persistence: GRDB/SQLite + JSON snapshot files — ADR-0005 — `done/infrastructure-fskyk-two-tier-persistence-grdb-snapshot-files.md`
- **infrastructure-x23a8** — Native Swift/SwiftUI app + WidgetKit extension sharing an App Group — ADR-0004 — `done/infrastructure-x23a8-native-swiftui-app-widgetkit-extension-app-group.md`
<!-- done-list:end -->

### Backlog
<!-- backlog-list:start -->
<!-- backlog-list:end -->

## ADRs scoped to this BC

Note: ADRs 0004–0011 are `scope: global` (they live in `.agentheim/knowledge/decisions/`, not
BC-local) but originated from infrastructure's decision tasks — listed here for discoverability.

<!-- adr-local:start -->
- **0004** — Native Swift/SwiftUI app + WidgetKit extension sharing an App Group — `../../knowledge/decisions/0004-native-swiftui-app-widgetkit-extension-app-group.md`
- **0005** — Two-tier persistence: GRDB/SQLite + JSON snapshot files — `../../knowledge/decisions/0005-two-tier-persistence-grdb-snapshot-files.md`
- **0006** — v1 refresh is polling from a single resident menu-bar app process — `../../knowledge/decisions/0006-resident-app-polling-refresh-topology.md`
- **0007** — Credentials in the macOS keychain behind a shared access group — `../../knowledge/decisions/0007-keychain-secret-storage-shared-access-group.md`
- **0008** — Failure policy: last-good-data-wins, visible staleness, rate-limit/backoff — `../../knowledge/decisions/0008-failure-staleness-backoff-policy.md`
- **0009** — App Sandbox stays on; vault/source access via security-scoped bookmarks — `../../knowledge/decisions/0009-sandbox-security-scoped-bookmarks.md`
- **0010** — Unified logging + PostHog for structured domain events (amended from no-telemetry draft) — `../../knowledge/decisions/0010-unified-logging-plus-posthog-for-structured-events.md`
- **0011** — No backend — single locally-built signed macOS app bundle — `../../knowledge/decisions/0011-no-backend-local-signed-app-bundle.md`
- **0016** — Burst-mode enter/exit is a pure, package-testable decision function (`BurstPolling.decide`); Firebase Hosting burst detection deferred until the adapter models release status — `../../knowledge/decisions/0016-burst-mode-decision-logic-and-firebase-scope.md`
<!-- adr-local:end -->

## Research touching this BC

<!-- research-local:start -->
<!-- research-local:end -->

## Concepts (opt-in synthesis pages)

<!-- concepts:start -->
<!-- concepts:end -->

## Pointers

- BC README (ubiquitous language, invariants): `README.md`
