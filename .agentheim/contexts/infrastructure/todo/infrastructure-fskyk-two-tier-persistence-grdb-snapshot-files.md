---
id: infrastructure-fskyk
title: Two-tier local persistence — GRDB/SQLite for domain state, JSON snapshot files for widgets
status: todo
type: decision
context: infrastructure
created: 2026-08-07
completed:
depends_on: [infrastructure-x23a8]
blocks: []
tags: [captured, architecture-foundation]
related_adrs: []
related_research: []
prior_art: []
---

## Why

Two very different readers need local data: the main app needs queryable, durable, migratable
domain state; the widget extension needs to render in a few milliseconds inside a tight memory
budget, in a separate process, possibly while the main app isn't running. Serving both from one
database risks booting a persistence stack — and a schema migration — inside the extension,
which is the fragile part of every app-plus-widget design.

## What

Split persistence into two tiers, both inside the App Group container. Tier A: SQLite via GRDB
(WAL mode) for durable domain state (Projects, Integration Bindings, Widget Configurations,
Notification Rules, event dedupe keys, cached provider responses with ETag/Last-Modified
validators) — written exclusively by the main app, behind per-BC repository protocols. Tier B:
render-ready JSON snapshot files (plus a manifest) for widget consumption, written atomically by
the app, read-only by the extension. The extension never opens the Tier A database — enforced
structurally by not linking GRDB/`MCPersistence` into it.

Full ADR draft is in Notes below.

## Acceptance criteria

- [ ] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: global`, matching the draft in Notes (or a user-amended version, amendments noted
      in the commit).
- [ ] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07. Note the follow-on, BC-local decision this creates for `widgets`: the exact
snapshot DTO payload contracts per Widget Kind are a consumer-driven contract owned by
`widgets`, not decided here.

```markdown
---
id: TBD
title: Two-tier local persistence — GRDB/SQLite for domain state, JSON snapshot files for widgets
scope: global
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [infrastructure-fskyk]
related_research: []
---

# ADR TBD: Two-tier local persistence — GRDB/SQLite for domain state, JSON snapshot files for widgets

## Context
The dataset is small and permanently single-user (ADR-0001): tens of Projects, low hundreds of
Integrations, plus bounded event history. Two very different readers need it. The main app needs
queryable, durable, migratable domain state. The widget extension needs to render in a few
milliseconds inside a tight memory budget, in a separate process, at times the app does not
control — and may be doing so while the app is not running at all.

Serving both from one database means booting a persistence stack, and risking a schema
migration, inside the extension. That is the fragile part of every app-plus-widget design.

## Decision
Split persistence into two tiers, both inside the App Group container.

**Tier A — domain state.** SQLite via GRDB, WAL journal mode, file
`<group>/Library/Application Support/missioncontrol.sqlite`. Holds Projects, Integration
Bindings, Widget Configurations, Notification Rules, event dedupe keys, and cached provider
responses with their ETag/Last-Modified validators. Written exclusively by the main app process.
All access is behind per-BC repository protocols defined in `MCDomain` and implemented in
`MCPersistence`; no BC constructs SQL outside its own repository. Schema changes go through
GRDB's `DatabaseMigrator` with a test that migrates a fixture from every prior version.

**Tier B — widget snapshots.** Render-ready `Codable` DTOs serialised as JSON files under
`<group>/Snapshots/`, one per widget-relevant entity plus a `manifest.json` listing available
snapshots and their `generatedAt` timestamps. Written atomically by the app whenever a poll
changes anything; read by the extension via `MCSnapshot`. Snapshots carry only what a widget
renders — including a `generatedAt` so the widget can display staleness — and contain no images
and no secrets.

The widget extension MUST NOT open the Tier A database. This is enforced structurally: the
extension does not link `MCPersistence` or GRDB.

## Consequences
### Positive
- The extension's data path has no schema, no migration, no DB stack, and no failure mode worse
  than "file missing" (rendered as an empty/stale state).
- Tier A survives the deferred move to a separate background helper process unchanged: SQLite in
  WAL mode is multi-process safe by design.
- The store is inspectable with any SQLite tool, which materially shortens debugging for a solo
  developer.
- Snapshot files are human-readable, making "why does the widget show this?" a `cat` away.

### Negative
- One third-party dependency (GRDB) rather than a first-party framework.
- No SwiftUI `@Query`; the in-app dashboard needs an observation layer (GRDB `ValueObservation`
  bridged to `@Observable`, or the GRDBQuery package).
- Data is written twice — once normalised in Tier A, once projected into Tier B. Snapshot
  regeneration must be triggered on every relevant write, or widgets silently go stale.

### Neutral
- Tier B is a cache, not a source of truth: deleting `<group>/Snapshots/` must be safe and
  self-healing on the next poll. This should be an explicit test.
- No cross-device sync (ADR-0001 permits one Mac). If a second Mac ever appears, Tier A is the
  thing that would need a sync story; Tier B is always locally regenerable.

## Alternatives considered
- **SwiftData for everything, read from the extension via `ModelConfiguration(groupContainer:)`**
  — rejected: puts a migration-capable stack in the extension's budget, has a weaker
  multi-process story than raw SQLite/WAL, and is materially harder to inspect when something
  goes wrong.
- **Core Data with `NSPersistentStoreRemoteChange`** — rejected: solves the same multi-process
  problem as WAL with substantially more ceremony and no compensating benefit at this scale.
- **JSON files for everything, no database** — rejected: event dedupe, ETag caches and
  cross-entity queries push toward relational access quickly, and hand-rolled file locking
  across processes is exactly the wrong thing to hand-roll.
- **`UserDefaults(suiteName:)` as the widget channel** — rejected: a plist cache with awkward
  semantics for structured payloads and no atomic multi-key update.

## References
- `.agentheim/knowledge/decisions/0001-permanent-single-user-personal-tool.md`
- `.agentheim/contexts/widgets/README.md`
- GRDB documentation — Concurrency, DatabaseMigrator.
```
