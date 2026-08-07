# Infrastructure — Index

Catalog of everything in this bounded context: tasks by status, ADRs scoped to this BC,
research touching this BC, and concept synthesis pages.

> Updated by: `modeling` (tasks), `work` (BC-scoped ADRs, concept page links), `research` (BC-scoped reports).

---

## Tasks by status

<!-- task-counts:start -->
- **Backlog:** 0
- **Todo:** 9
- **Doing:** 0
- **Done:** 0
<!-- task-counts:end -->

### Todo
<!-- todo-list:start -->
- **infrastructure-001-walking-skeleton** — Walking skeleton — onboard mise_pwa end-to-end through the full stack — depends_on: [infrastructure-x23a8, infrastructure-fskyk, infrastructure-hv013, infrastructure-zznqh, infrastructure-wv33x, infrastructure-rxd87, infrastructure-pcmqh, infrastructure-mam0r, service-integrations-n7s2k] — `todo/infrastructure-001-walking-skeleton.md`
- **infrastructure-mam0r** — Failure policy — last-good data wins, staleness visible, rate-limited/flaky providers — depends_on: [infrastructure-zznqh] — `todo/infrastructure-mam0r-failure-staleness-backoff-policy.md`
- **infrastructure-pcmqh** — Keep the App Sandbox on; vault/source access via security-scoped bookmarks — depends_on: [infrastructure-x23a8] — `todo/infrastructure-pcmqh-sandbox-security-scoped-bookmarks.md`
- **infrastructure-rxd87** — Observability is Apple unified logging only — depends_on: [infrastructure-x23a8] — `todo/infrastructure-rxd87-unified-logging-only-no-telemetry.md`
- **infrastructure-wv33x** — No backend — single locally-built signed macOS app bundle — depends_on: [infrastructure-zznqh] — `todo/infrastructure-wv33x-no-backend-local-signed-app-bundle.md`
- **infrastructure-zznqh** — v1 refresh is polling from a single resident menu-bar app; webhooks/helper daemon deferred — depends_on: [infrastructure-x23a8, infrastructure-fskyk, infrastructure-hv013] — `todo/infrastructure-zznqh-resident-app-polling-refresh-topology.md`
- **infrastructure-hv013** — Credentials in the macOS keychain behind a shared access group — depends_on: [infrastructure-x23a8] — `todo/infrastructure-hv013-keychain-secret-storage-shared-access-group.md`
- **infrastructure-fskyk** — Two-tier persistence: GRDB/SQLite + JSON snapshot files — depends_on: [infrastructure-x23a8] — `todo/infrastructure-fskyk-two-tier-persistence-grdb-snapshot-files.md`
- **infrastructure-x23a8** — Native Swift/SwiftUI app + WidgetKit extension sharing an App Group — depends_on: [] — `todo/infrastructure-x23a8-native-swiftui-app-widgetkit-extension-app-group.md`
<!-- todo-list:end -->

### Doing
<!-- doing-list:start -->
<!-- doing-list:end -->

### Done (most recent first; older entries kept for prior-art search)
<!-- done-list:start -->
<!-- done-list:end -->

### Backlog
<!-- backlog-list:start -->
<!-- backlog-list:end -->

## ADRs scoped to this BC

<!-- adr-local:start -->
<!-- adr-local:end -->

## Research touching this BC

<!-- research-local:start -->
<!-- research-local:end -->

## Concepts (opt-in synthesis pages)

<!-- concepts:start -->
<!-- concepts:end -->

## Pointers

- BC README (ubiquitous language, invariants): `README.md`
