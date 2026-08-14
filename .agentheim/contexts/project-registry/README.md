# Project Registry

## Purpose
Registers Projects by name, optionally links each one to a local source-code folder on disk
and/or an Obsidian note (an unparsed pointer, ADR-0014), and owns which Service Integrations are
attached to each Project. This is where "what projects exist and what do they consist of" lives.

## Classification
core — the aggregate root the rest of the product organizes around. Every Widget and
Notification ultimately traces back to a Project registered here.

## Actors
The user, in the role of registering and configuring Projects (naming them, optionally linking a
local source path and/or an Obsidian note, attaching Service Integrations).

## Ubiquitous language
- **Project** — a unit of work registered in the app by name; optionally linked to a local
  source-code folder and/or an Obsidian note; owns a set of attached Service Integrations.
- **Vault** — the user's Obsidian vault on this Mac. Never scanned, read, or treated as a source
  of truth for which Projects exist (ADR-0014) — purely where a Project's optional Obsidian Note
  Link points to, when one is set.
- **Progetti Folder** — the folder inside the vault where Project documentation is typically
  kept (e.g. `Progetti/Gestione Mezzi` for mise_pwa), when a Project happens to have one.
- **Obsidian Note Link** — a Project's optional, unvalidated pointer (a path or `obsidian://`
  URI) to its Obsidian note. Never read or parsed; drives exactly one behavior, an "Open in
  Obsidian" action via `NSWorkspace.shared.open(url:)` (ADR-0014). Needs no filesystem access to
  the vault and no security-scoped bookmark — narrows ADR-0009's bookmark requirement to
  **Source Path** only.
- **Source Path** — the optional local filesystem folder holding a Project's source code. Unlike
  the Obsidian Note Link, this one *is* actually read by the app (e.g. for future
  source-adjacent features), so it keeps ADR-0009's `NSOpenPanel` + security-scoped bookmark
  flow.
- **Integration Binding** — the association between a Project and one of its attached Service
  Integrations (identity/type only — the integration's own data and behavior live in
  Service Integrations).

## Aggregates
- **Project** — protects the invariant that a Project always resolves to a unique name, at most
  one Source Path, at most one Obsidian Note Link, and a de-duplicated set of Integration
  Bindings.

## Key events
- **Project registered**
- **Project updated** (source path changed, Obsidian link set/cleared, integration
  attached/detached)
- **Project removed**

## Key commands
- **Register project** (by name)
- **Link source path** / **Unlink source path**
- **Set Obsidian note link** / **Clear Obsidian note link**
- **Open in Obsidian** (not a mutation — hands off to the Obsidian app via URL scheme)
- **Attach integration** / **Detach integration**

## Relationships with other contexts
- **Customer of Service Integrations:** Integration Bindings reference Integration
  types/identities owned there; Project Registry never reaches into Integration internals.
- **Upstream of Widgets and Notifications:** both read Project data as an open host.
- **Conformist to Design System:** this context's in-app UI (project registration/config
  screens) uses Design System tokens/components rather than styling independently — no
  frontend feature here is promoted before `design-system-001-styleguide` is signed off.
- See `context-map.md` for the full picture.

## Open questions
- ~~How does the app detect new/changed Projects in the vault — one-time import, watched folder,
  or manual "add project" only?~~ Resolved (ADR-0014, 2026-08-15): it doesn't. No vault-scanning
  or discovery mechanism exists or is planned; registration is always manual "Add Project," and
  the vault is never a source of truth for which Projects exist. (open 2026-08-07 → resolved
  2026-08-15)
- ~~What does the app actually extract from a Vault Note?~~ Resolved (ADR-0014, 2026-08-15): the
  Obsidian link is never read or parsed, full stop — not "not yet," a settled decision. It is an
  optional, opaque pointer driving exactly one behavior ("Open in Obsidian"). Service
  Integrations are attached by hand through the app's own UI regardless of whether a Project has
  an Obsidian link at all. (open 2026-08-13 → resolved 2026-08-15)
