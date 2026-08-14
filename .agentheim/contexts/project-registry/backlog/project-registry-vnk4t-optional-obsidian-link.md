---
id: project-registry-vnk4t
title: Make the Obsidian note link fully optional; replace it with a single "Open in Obsidian" action
status: backlog
type: feature
context: project-registry
created: 2026-08-15
completed:
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

- [ ] Registering a Project with only a name (no Source Path, no Obsidian link) succeeds — "Add"
      is not blocked by an empty Obsidian field.
- [ ] A Project's Obsidian link, when set, is stored and read back unchanged — no parsing, no
      transformation beyond what's needed to build the `obsidian://` URL at open-time.
- [ ] Clicking "Open in Obsidian" on a Project with a link set calls `NSWorkspace.shared.open(_:)`
      with a well-formed `obsidian://open?path=...` URL (verify via a unit test around URL
      construction — a plain string → URL function, no `NSWorkspace` mocking needed).
- [ ] A Project with no Obsidian link set shows no "Open in Obsidian" button at all (not a
      disabled one). [human-eye]
- [ ] No security-scoped bookmark, `NSOpenPanel`, or `com.apple.security.files.*` entitlement
      usage exists anywhere in the code path for the Obsidian link (grep-verifiable — contrast
      with `BookmarkHelper`, which is untouched and still used for Source Path).
- [ ] `swift test` still passes with no regressions to existing `MCDomain`/`MCPersistence` tests
      that construct a `Project`.

## Notes

Blocked from `todo/` by the styleguide gate (`design-system-001-styleguide` is still in `todo/`,
not `done/`) — this task adds a new UI element (the "Open in Obsidian" button) to an existing
frontend-bearing BC, so per `modeling`'s styleguide-gate rule it cannot be promoted ahead of the
styleguide being signed off, even though it's otherwise ready. Promote automatically once the
styleguide ships — no further refinement needed first.

See ADR-0014 for the full reasoning (why no parsing, why no bookmark, why the field is optional).
