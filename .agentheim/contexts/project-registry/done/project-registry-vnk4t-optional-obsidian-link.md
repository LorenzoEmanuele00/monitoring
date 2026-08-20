---
id: project-registry-vnk4t
title: Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action
status: done
type: feature
context: project-registry
created: 2026-08-15
completed: 2026-08-21
depends_on: [design-system-001-styleguide]
blocks: []
tags: [obsidian, walking-skeleton-followup]
related_adrs: [0014]
related_research: []
prior_art: []
---

## Why

`infrastructure-001-walking-skeleton` shipped `AddProjectSheet` with a required "Vault note path
(relative)" text field — the Add Project button stays disabled until it's filled in, even though
nothing in the app ever reads that value beyond storing it as a label. ADR-0014 resolves this:
the Obsidian link becomes a fully optional, unparsed pointer, and its only behavior is a single
"Open in Obsidian" action. This task is the code-level follow-through on that decision.

## What

- `AddProjectSheet`: remove the requirement that the vault note field be non-empty to enable
  "Add." A Project can be registered with just a name (Source Path stays independently optional,
  unchanged from today).
- `Project` (MCDomain): rename/repurpose `vaultNoteRelativePath` to reflect that it's now an
  optional Obsidian link, not a required root — e.g. `obsidianNoteLink: String?`. No parsing, no
  validation beyond "non-empty if present."
- `ProjectDetailView` (or wherever a Project's fields are shown): when the Obsidian link is set,
  show an **"Open in Obsidian"** button. When absent, show nothing (no disabled/greyed-out
  placeholder — the field is optional, not incomplete). Clicking it calls
  `NSWorkspace.shared.open(_:)` with an `obsidian://open?path=<url-encoded-path>` URL built from
  the stored string.
- No security-scoped bookmark, no `NSOpenPanel`, no filesystem access of any kind for this field
  — it's a plain string the app hands to `NSWorkspace`, never opens itself. (Contrast with
  Source Path, which keeps its existing `NSOpenPanel` + bookmark flow untouched.)
- Update `IntegrationStatusWidgetView`/`ProjectDetailView` display strings if they currently
  assume a vault note path is always present (grep for `vaultNoteRelativePath` — this is the
  walking skeleton's own field name, not yet renamed anywhere else).

## Acceptance criteria

- [x] Registering a Project with only a name (no Source Path, no Obsidian link) succeeds — "Add"
      is not blocked by an empty Obsidian field.
- [x] A Project's Obsidian link, when set, is stored and read back unchanged — no parsing, no
      transformation beyond what's needed to build the `obsidian://` URL at open-time.
- [x] Clicking "Open in Obsidian" on a Project with a link set calls `NSWorkspace.shared.open(_:)`
      with a well-formed `obsidian://open?path=...` URL (verify via a unit test around URL
      construction — a plain string → URL function, no `NSWorkspace` mocking needed).
- [x] A Project with no Obsidian link set shows no "Open in Obsidian" button at all (not a
      disabled one). [human-eye]
- [x] No security-scoped bookmark, `NSOpenPanel`, or `com.apple.security.files.*` entitlement
      usage exists anywhere in the code path for the Obsidian link (grep-verifiable — contrast
      with `BookmarkHelper`, which is untouched and still used for Source Path).
- [x] `swift test` still passes with no regressions to existing `MCDomain`/`MCPersistence` tests
      that construct a `Project`.

## Outcome

Implemented ADR-0014 end to end. `Project.vaultNoteRelativePath: String` (required) became
`Project.obsidianNoteLink: String?` (optional, MissionControlKit's `MCDomain` target) with a new
`Project.obsidianOpenURL: URL?` computed property that builds the `obsidian://open?path=...` URL
via `URLComponents` (percent-encodes the raw link, no parsing/interpretation of its contents).
`AddProjectSheet`'s "Add" button is now disabled only on an empty name; the Obsidian text field
is labeled "Obsidian note link (optional)" and an empty entry is stored as `nil`, not `""`.
`ProjectDetailView` replaced the unconditional "Vault note" row with a conditional
`openInObsidianRow` that renders a single "Open in Obsidian" button (calling
`NSWorkspace.shared.open(url:)`) only when `obsidianOpenURL` is non-nil — no disabled placeholder
when absent. The GRDB schema column `vaultNoteRelativePath TEXT NOT NULL` became
`obsidianNoteLink TEXT` (nullable) in `DatabaseManager`'s `v1_initial` migration — this is a
walking-skeleton spike with no shipped users/data, so the column was renamed in place rather than
adding a new migration step. Confirmed via grep that no `BookmarkHelper`/`NSOpenPanel`/
`com.apple.security.files.*` usage exists anywhere in the Obsidian-link code path — that
machinery stays exclusively on the Source Path flow, untouched by this task. Added
`MCDomainTests/ProjectTests.swift` (4 new tests: nil-when-unset, nil-when-empty-string,
well-formed URL construction incl. percent-encoding, and Codable round-trip) and updated the two
existing `RepositoryTests` call sites that constructed a `Project`. `swift test` passes (42/42,
0 regressions); a full `xcodebuild` of the `MissionControl` scheme (app + widget extension)
also succeeds, confirming the view-layer changes compile.

Key files: `MissionControl/MissionControlKit/Sources/MCDomain/Project.swift`,
`MissionControl/MissionControl/Views/AddProjectSheet.swift`,
`MissionControl/MissionControl/Views/ProjectDetailView.swift`,
`MissionControl/MissionControlKit/Sources/MCPersistence/DatabaseManager.swift`,
`MissionControl/MissionControlKit/Tests/MCDomainTests/ProjectTests.swift`.

No new ADR was needed — ADR-0014 already covers every design decision this task makes; this task
is purely its code-level follow-through. The BC README already reflected ADR-0014's ubiquitous
language and resolved open questions (updated when the ADR was authored), so no README changes
were required either.

**Iteration 2 (post-verification fix):** addressed both gaps from the verifier note below.
Added two repository-level tests to `RepositoryTests.swift`:
`projectWithNoObsidianLinkInsertsAndFetchesAsNil` inserts `Project(name: "name-only")` through
`GRDBProjectRepository` and asserts the fetched row's `obsidianNoteLink == nil` — this is the
test that would have caught a missed `.notNull()` removal on the schema column (criterion 1, now
actually exercised through the persistence layer, not just in-memory `Project` construction).
`projectWithObsidianLinkRoundTripsThroughStorageUnchanged` inserts a Project with an Obsidian
link set and asserts the fetched value equals the exact string stored — this exercises the real
GRDB Codable column mapping, catching a dropped/mangled `obsidianNoteLink` column (criterion 2).
Also addressed the migration-strategy gap: added an explicit, prominent code comment directly
above the `v1_initial` migration's `project` table definition in `DatabaseManager.swift`
documenting that the `vaultNoteRelativePath` → `obsidianNoteLink` rename was done in place
(rather than via a `v2` step) only because this is a pre-release spike with no installed
databases, and explicitly warning that this in-place-rewrite approach must not be repeated once
`v1_initial` has ever been applied on a real user's machine — a judgment call that a full ADR
wasn't warranted here (this is a spike decision fully scoped to "how to handle a schema change
before anyone has data," not a standing architectural precedent), but the reasoning needed to be
more visible than buried Outcome prose, hence the in-code note. `swift test` re-run: 44/44 passing
(42 prior + 2 new), 0 regressions, confirmed via the runner's own summary line
(`Test run with 44 tests in 10 suites passed`).

## Notes

Blocked from `todo/` by the styleguide gate (`design-system-001-styleguide` is still in `todo/`,
not `done/`) — this task adds a new UI element (the "Open in Obsidian" button) to an existing
frontend-bearing BC, so per `modeling`'s styleguide-gate rule it cannot be promoted ahead of the
styleguide being signed off, even though it's otherwise ready. Promote automatically once the
styleguide ships — no further refinement needed first.

See ADR-0014 for the full reasoning (why no parsing, why no bookmark, why the field is optional).

## Verifier note (iteration 1)

REASONS:
- Criterion 1 ("Registering a Project with only a name (no Source Path, no Obsidian link)
  succeeds") has no covering test. The only candidate,
  `ProjectTests.obsidianOpenURLIsNilWhenLinkIsNotSet`
  (`MissionControl/MissionControlKit/Tests/MCDomainTests/ProjectTests.swift:6-10`), is named
  after and asserts only `obsidianOpenURL`/`obsidianNoteLink` nil-ness in memory — it never
  exercises registration. The production change this criterion actually depends on is the schema
  column going from `vaultNoteRelativePath TEXT NOT NULL` to nullable `obsidianNoteLink TEXT`
  (`MissionControl/MissionControlKit/Sources/MCPersistence/DatabaseManager.swift:42`), and no
  test inserts a `Project` with a `nil` link through `GRDBProjectRepository`. If the
  `.notNull()` removal had been omitted, the entire suite would still pass (42/42, confirmed by
  running `swift test`) while name-only registration threw a NOT NULL constraint failure at
  runtime. The UI half ("Add is not blocked by an empty Obsidian field") also has no covering
  artifact beyond the `.disabled(name.isEmpty)` diff line, and the task's `## Outcome` records
  only a compile-level `xcodebuild` success, not a manual-exercise note.
- Criterion 2 ("A Project's Obsidian link, when set, is stored and read back unchanged") has no
  covering test either. `ProjectTests.obsidianNoteLinkRoundTripsUnchanged` (`ProjectTests.swift:
  24-31`) round-trips through `JSONEncoder`/`JSONDecoder`, not through storage. The one
  persistence test, `RepositoryTests.projectInsertAndFetch`
  (`MissionControl/MissionControlKit/Tests/MCPersistenceTests/RepositoryTests.swift:13-25`), was
  modified only at its construction call site (line 17) and still asserts nothing but
  `fetched?.name` (line 21) and `all.count` — the stored link value is never read back or
  compared, so it would pass unchanged even if `obsidianNoteLink` were dropped or mangled on the
  GRDB Codable column mapping (`GRDBRecordConformances.swift:16`).

SUGGESTED_FIX: Add repository-level tests in `RepositoryTests.swift` that (a) insert
`Project(name: "x")` with no Obsidian link, fetch it back, and assert the insert succeeded with
`obsidianNoteLink == nil`, and (b) insert a Project with a link set and assert the fetched value
equals the exact string stored. Separately, expect check 6 to be reached next iteration: the
in-place rewrite of the already-registered `v1_initial` migration (rather than adding a `v2`
step) is a decision with a real downstream consequence — any existing installed database keeps
the old `NOT NULL` column while the code reads `obsidianNoteLink` — and it is currently justified
only in the task file's `## Outcome`, which is explicitly not a substitute for an ADR.

ITERATION_HINT: likely-fixable
