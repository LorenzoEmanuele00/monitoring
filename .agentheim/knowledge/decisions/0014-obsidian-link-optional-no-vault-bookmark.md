---
id: 0014
title: A Project's Obsidian link is a fully optional, unparsed pointer — no vault security-scoped bookmark, no rooting requirement
scope: project-registry
status: accepted
date: 2026-08-15
supersedes: []
superseded_by: []
related_tasks: [project-registry-vnk4t]
related_research: []
---

# ADR 0014: A Project's Obsidian link is a fully optional, unparsed pointer — no vault security-scoped bookmark, no rooting requirement

## Context

`infrastructure-001-walking-skeleton` shipped `Project.vaultNoteRelativePath` as a required
plain-text field: registering a Project meant typing a path like `Progetti/Gestione Mezzi.md`,
even though nothing in the app ever reads or parses that file — it exists purely as a label.
Project Registry's README carried this as an unresolved open question since 2026-08-13: freeform
Obsidian prose has no guaranteed structure, so the app can never reliably extract project
metadata from it, and the working assumption ("identity/handle only, no parsing") was never
formally decided. A second open question — how the app detects new/changed Projects in the vault
— was really downstream of the same unresolved rooting assumption.

Separately, ADR-0009 justified `com.apple.security.files.bookmarks.app-scope` and the whole
security-scoped-bookmark dance partly on the grounds that the app needs to *reach* the vault.
That justification assumed the app would eventually read Vault Note content. It doesn't, and per
this ADR, never will.

The user's own framing, reviewing this after using the walking skeleton hands-on: requiring a
vault link to register a Project is a blocker for no real benefit — some projects won't have one,
and the field currently does nothing but sit there as a string. The actual value worth keeping is
narrow and concrete: a one-click way to jump to a Project's Obsidian note, when one exists.

## Decision

The Obsidian link becomes a fully optional, per-Project pointer — never a registration
requirement, never a root a Project is "in":

- Registering a Project requires only a name. A Source Path (local source-code folder) and an
  Obsidian link are both independently optional.
- The Obsidian link is stored as an opaque string (a vault-relative note path, or a full
  `obsidian://` URI, or a plain filesystem path — Project Registry does not validate its shape
  beyond "non-empty"). It is never read, parsed, or interpreted as structured data. This is now
  the accepted answer, not a working assumption.
- The only behavior it drives is a single **"Open in Obsidian"** action that hands off to the
  Obsidian app via `NSWorkspace.shared.open(url:)` using the `obsidian://` URL scheme
  (`obsidian://open?path=<url-encoded-absolute-or-vault-relative-path>`). This is a URL-scheme
  handoff, not a file read — the app never opens, lists, or accesses anything inside the vault
  directory itself.
- Because of the above, **the Obsidian link needs no security-scoped bookmark and no vault-root
  access of any kind.** ADR-0009's bookmark machinery (`NSOpenPanel` selection, persisted
  security-scoped bookmark, balanced start/stop-accessing calls) still applies to the **Source
  Path** field — that one is a real, read-accessed local folder — but no longer applies to
  anything vault-related. ADR-0009's own text already treats the vault and Source Path
  identically for bookmark purposes; this ADR narrows that scope to Source Path only. ADR-0009's
  `superseded_by` frontmatter is updated to point here for that one claim; its body is left
  untouched as the historical record of the original (broader) reasoning.
- "How does the app detect new/changed Projects in the vault" is resolved as: it doesn't. There
  is no vault-scanning or discovery mechanism, now or planned. Registration is always the
  manual "Add Project" flow; the vault is never a source of truth for which Projects exist.

## Consequences

### Positive
- Registering a Project is never blocked by not having (or not wanting to link) an Obsidian
  note — directly fixes the friction the user identified.
- Removes an entire class of complexity that was bought for zero present value: vault-root
  security-scoped bookmark provisioning, resolution-failure handling, and re-prompting UX for a
  field nothing ever reads.
- Both of Project Registry's long-open questions are resolved at once, with no remaining
  ambiguity for the registration flow to be built against.
- The "jump to my documentation" value the vision's problem statement names is still delivered,
  at a fraction of the cost — one `NSWorkspace.open` call, no filesystem access, no parsing.

### Negative
- The app can never surface anything *from* a Project's Obsidian note (a summary, a status line,
  linked metadata) without a future, separately-decided capability — this ADR forecloses
  automatic extraction, not just defers it. A future decision to add structured frontmatter
  parsing would need its own ADR superseding this one's "never parsed" clause.
- The stored path/URI is unvalidated free text; a stale or malformed value simply fails to open
  in Obsidian (`NSWorkspace.open` returns `false`/no-ops) rather than being caught at entry time.
  Acceptable: the failure mode is "the button does nothing," not data corruption or a crash.

### Neutral
- Project Registry's aggregate invariant changes from "a Project always resolves to exactly one
  vault location" to "a Project always resolves to a unique name, at most one Source Path, and
  at most one Obsidian link" — reflected in the BC README.
- This does not reopen ADR-0009's core call (App Sandbox stays on) — Source Path access still
  needs it. Only the vault-specific portion of that ADR's justification is narrowed.

## Alternatives considered

- **Keep the vault link required, defer only the parsing question** — rejected: this was the
  status quo the user pushed back on directly; the field already provides no value beyond a
  label, so requiring it buys nothing while still blocking registration.
- **Support structured YAML frontmatter parsing as an opt-in** (raised as a "maybe later" in the
  original open question) — rejected for now, not permanently foreclosed by architecture: the
  user's explicit ask was "nothing more than this" (a link, not extraction). Revisit only if a
  concrete need for structured metadata emerges — it would be a new decision, not a reopening of
  this one.
- **Keep a security-scoped bookmark for the vault "just in case"** — rejected: provisioning
  access the app structurally can never use is pure cost (bookmark resolution failure states,
  re-prompt UX, an extra entitlement to reason about) with no corresponding benefit under a
  URL-scheme-only design.

## References

- `.agentheim/knowledge/decisions/0009-sandbox-security-scoped-bookmarks.md` — narrowed by this
  ADR to Source Path only; vault access no longer needs the bookmark machinery described there.
- `.agentheim/vision.md` — "What success looks like," registration bullet updated to match.
- `.agentheim/contexts/project-registry/README.md` — both open questions resolved; aggregate
  invariant and ubiquitous language updated.
- Apple: `obsidian://` URI scheme (third-party, Obsidian's own published URI spec); `NSWorkspace
  .open(_:)`.
