---
id: infrastructure-pcmqh
title: Keep the App Sandbox on; reach the Obsidian vault and source folders via security-scoped bookmarks
status: done
type: decision
context: infrastructure
created: 2026-08-07
completed: 2026-08-13
depends_on: [infrastructure-x23a8]
blocks: []
tags: [captured, architecture-foundation]
related_adrs: [0009]
related_research: []
prior_art: []
---

## Why

Project Registry roots every Project in a folder inside the Obsidian vault, and optionally links
a local source-code folder — both arbitrary locations outside the app's own container. The
widget extension is sandboxed unconditionally regardless of what the main app chooses.

## What

Keep the App Sandbox on for the main app. Out-of-container access uses `NSOpenPanel` plus
persisted security-scoped bookmarks, resolved on each launch with balanced start/stop access
calls. Bookmark resolution failure is a first-class, user-visible state (prompt re-selection),
never a silently empty project list. Explicitly marked reversible: disabling the sandbox later
is a single entitlement flip if bookmark friction (e.g. shelling out to `git`) proves real, and
does not affect the App Group data path.

Full ADR draft is in Notes below.

## Acceptance criteria

- [x] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: global`, matching the draft in Notes (or a user-amended version, amendments noted
      in the commit) — committed as ADR-0009, as drafted.
- [x] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07. Bookmark lifecycle specifics (stale-vault re-prompt UX, one-time-import vs.
watched-folder discovery) are a `project-registry`-local follow-on decision, not fixed here.

```markdown
---
id: TBD
title: Keep the App Sandbox on; reach the Obsidian vault and source folders via security-scoped bookmarks
scope: global
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [infrastructure-pcmqh]
related_research: []
---

# ADR TBD: Keep the App Sandbox on; reach the Obsidian vault and source folders via security-scoped bookmarks

## Context
Project Registry roots every Project in a folder inside the user's Obsidian vault, and optionally
links a local source-code folder — both arbitrary locations outside the app's own container. The
widget extension is sandboxed unconditionally (macOS app extensions always are), so sandbox
semantics are part of this system regardless of what the main app chooses. The main app could
nonetheless disable its own sandbox for unrestricted filesystem access, which is a legitimate
option for a tool that will never be distributed through the App Store (ADR-0001).

## Decision
Keep the App Sandbox enabled on the main app. Out-of-container folder access uses the standard
mechanism: the user selects the vault root (and, per Project, an optional Source Path) through
`NSOpenPanel`; the app persists a security-scoped bookmark and resolves it on each launch,
wrapping access in balanced `startAccessingSecurityScopedResource()` / `stopAccessingSecurity
ScopedResource()` calls.

Required entitlements: `com.apple.security.app-sandbox`,
`com.apple.security.files.user-selected.read-write`,
`com.apple.security.files.bookmarks.app-scope`, `com.apple.security.network.client`, plus the
App Group and keychain access group. The vault is opened read-only in practice — this product
never writes to the Obsidian vault.

Bookmark blobs are stored in Tier A. Resolution failure (the vault moved or was renamed) is a
first-class, user-visible state that prompts re-selection; it must never present as an empty
project list.

This decision is explicitly marked reversible. If sandbox restrictions become a genuine blocker —
the most likely trigger being a future feature that shells out to `git` against a Source Path —
disabling the sandbox is a single entitlement change. A non-sandboxed app that is still signed
with the team-ID-prefixed App Group entitlement retains access to the group container, so the
widget data path is unaffected. The only thing forfeited is App Store distribution, which
ADR-0001 already rules out.

## Consequences
### Positive
- One security model across the app and the extension, rather than two.
- Filesystem access is explicit and auditable; a bug cannot wander outside granted scopes.
- Distribution options (App Store, TestFlight) stay open at no ongoing cost.

### Negative
- Bookmark lifecycle is real work: resolution, staleness handling, re-prompting, and balanced
  start/stop calls that leak scopes if mismatched.
- Subprocess execution (e.g. `git`) is constrained, since children inherit the sandbox.
- Vault folders synced by iCloud or a third-party client can produce placeholder/eviction
  behaviour that the resolution path must tolerate.

### Neutral
- Whether Project discovery is a one-time import, a manual add, or an `FSEvents`-watched folder
  remains Project Registry's open question. All three work inside a held security scope; this
  ADR does not decide it.

## Alternatives considered
- **Disable the App Sandbox for the main app** — not rejected on principle, only deferred: it is
  simpler today but forfeits distribution options and diverges from the extension's mandatory
  sandbox. Explicitly available as a one-flip fallback if bookmark friction proves real.
- **Copy vault content into the app container** — rejected: duplicates the user's source of
  truth, and immediately creates a sync/staleness problem that did not previously exist.
- **Full Disk Access (TCC) instead of bookmarks** — rejected: vastly broader privilege than
  needed, requires manual System Settings steps, and does not apply to a sandboxed app anyway.

## References
- `.agentheim/contexts/project-registry/README.md` — Vault, Progetti Folder, Source Path.
- Apple: App Sandbox, Security-Scoped Bookmarks and Persistent Resource Access.
```
