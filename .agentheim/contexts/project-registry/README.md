# Project Registry

## Purpose
Registers Projects sourced from the Obsidian vault's `Progetti` folder, optionally links each
one to a local source-code folder on disk, and owns which Service Integrations are attached to
each Project. This is where "what projects exist and what do they consist of" lives.

## Classification
core — the aggregate root the rest of the product organizes around. Every Widget and
Notification ultimately traces back to a Project registered here.

## Actors
The user, in the role of registering and configuring Projects (which vault folder is a
project, which local source path it maps to, which Service Integrations are attached).

## Ubiquitous language
- **Project** — a unit of work registered in the app, rooted in a note/folder inside the
  vault's `Progetti` folder; optionally linked to a local source-code folder; owns a set of
  attached Service Integrations.
- **Vault** — the user's Obsidian vault on this Mac.
- **Progetti Folder** — the folder inside the vault where each Project's documentation lives
  (e.g. `Progetti/Gestione Mezzi` for mise_pwa).
- **Source Path** — the optional local filesystem folder holding a Project's source code,
  separate from its documentation in the vault.
- **Integration Binding** — the association between a Project and one of its attached Service
  Integrations (identity/type only — the integration's own data and behavior live in
  Service Integrations).

## Aggregates
- **Project** — protects the invariant that a Project always resolves to exactly one vault
  location, at most one Source Path, and a de-duplicated set of Integration Bindings.

## Key events
- **Project registered**
- **Project updated** (source path changed, integration attached/detached)
- **Project removed**

## Key commands
- **Register project** (from a vault folder)
- **Link source path**
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
- How does the app detect new/changed Projects in the vault — one-time import, watched folder,
  or manual "add project" only?
