---
id: 0015
title: Staleness thresholds resolved at 15 min (subdued) / 60 min (flagged), overriding ADR-0008's placeholder
scope: global
status: accepted
date: 2026-08-15
supersedes: []
superseded_by: []
related_tasks: [design-system-001-styleguide]
related_research: []
---

# ADR 0015: Staleness thresholds resolved at 15 min (subdued) / 60 min (flagged), overriding ADR-0008's placeholder

## Context

ADR-0008 (`infrastructure-mam0r`) fixed the *policy* that every rendering surface must show
staleness and degrade visibly past a threshold, but explicitly left the concrete figures open:
"suggested: subdued past ~30 min, explicitly flagged past ~2 h" — a placeholder, with the ADR's
own Consequences section noting "the visual treatment of staleness is Widgets' and Design
System's to specify."

Independently, a design draft produced via claude.ai/design (`mc-design-system-v1-draft.md`,
2026-08-07) specced the staleness indicator component with tighter, configurable defaults —
`warnMinutes: 15`, `staleMinutes: 60` — and flagged the conflict against ADR-0008's numbers as an
open question to resolve when `design-system-001-styleguide` actually ran.

This task is where that resolution belongs: `MCStaleness` (`MCDesignTokens`) is the single
source of truth both the in-app dashboard and the Desktop Widget read for staleness
classification, so the two artifacts could not both be followed literally — one set of numbers
had to be chosen.

## Decision

Adopt the design draft's tighter thresholds: **subdued past 15 minutes, flagged past 60
minutes** (`MCStaleness.subduedThreshold` / `MCStaleness.flaggedThreshold` in
`MissionControlKit/Sources/MCDesignTokens/DesignTokens.swift`), superseding ADR-0008's ~30
min/~2 h placeholder for this specific figure. ADR-0008's other rules (last-good-data-wins,
conditional requests, retry/backoff, circuit breaker) are untouched — only the staleness-display
thresholds change. ADR-0008's `superseded_by` frontmatter is not modified project-wide (it has no
single "vault-bookmark"-style narrow clause to redirect); this ADR is simply the authoritative
answer to the "concrete figures" question ADR-0008 deferred, referenced from
`MCStaleness`'s doc comment and the design-system README.

Rationale for picking the tighter figure over the placeholder:
- The product's own framing (ADR-0002: "observe-first cockpit") is glanceability — a cockpit
  whose staleness indicator only starts degrading at 30 minutes risks under-alerting during an
  active incident (a failed deploy or broken CI run sitting "fresh-looking" for half an hour is
  exactly the misleading-confidence failure mode ADR-0008 itself was written to avoid).
- The draft's numbers came from a pass that was already reasoning about the small-widget render
  surface and the two-tier subdued/flagged visual language: 15/60 gives a wider "in ritardo"
  (subdued) window (15-60 min) than 30/120 would, which is arguably more useful — most poll
  cycles that are merely running a little behind land in that window and should look
  "attention, not alarmed," rather than either flavor of ADR-0008's more binary
  fresh-until-30-then-jump.
- ADR-0008 itself marks 30 min/2 h as a *suggestion*, not a fixed decision, and names Design
  System as the owner of the final call — adopting the draft's number is exercising that
  delegated authority, not overriding a settled decision.

Thresholds stay overridable per call site
(`MCStaleness.level(generatedAt:now:subduedThreshold:flaggedThreshold:)`,
`MCStalenessIndicator`'s initializer) since the draft itself exposed them as configurable props
rather than fixed constants — a future BC with different freshness needs (e.g. a provider polled
far less often) can pass its own thresholds without forking the component.

## Consequences

### Positive
- One concrete, testable answer instead of two competing guesses; `MCStalenessTests` pins the
  exact boundary behavior (20-min-old data is `.subdued`, 65-min-old data is `.flagged` — both
  would have been classified differently under ADR-0008's placeholder).
- Removes the last open item blocking `design-system-001-styleguide`'s component set from being
  "done" pending only human sign-off.

### Negative
- Tighter thresholds mean the staleness indicator changes color/state more often during normal
  operation (e.g. the app being quit for 20 minutes now shows "subdued" where the old 30-min
  placeholder wouldn't have) — a deliberate trade favoring visibility over a calmer-looking but
  more permissive default. Revisit if this proves noisy in real use once the human review happens.

### Neutral
- `infrastructure-mam0r`'s own ADR-0008 text is left as the historical record of the original
  placeholder reasoning, per this project's established pattern (ADR-0009/ADR-0014) of not
  rewriting accepted ADRs after the fact.

## Alternatives considered

- **Keep ADR-0008's 30 min/2 h placeholder** — rejected: it was explicitly marked as a
  suggestion pending this task, and the tighter figure better serves the glanceable-cockpit
  vision (see rationale above).
- **Split the difference (e.g. 20 min/90 min)** — rejected: no evidence either number is
  better-reasoned than the draft's, and inventing a third figure not backed by either prior
  artifact adds ambiguity without benefit.
- **Make thresholds a user-configurable setting from day one** — rejected as scope creep for this
  task; the API already supports per-call-site overrides, which is enough headroom without
  building settings UI nothing currently needs.

## References

- `.agentheim/knowledge/decisions/0008-failure-staleness-backoff-policy.md` — origin of the
  policy this ADR narrows to concrete figures.
- `.agentheim/contexts/design-system/references/mc-design-system-v1-draft.md` — source of the
  15/60 figures adopted here.
- `MissionControl/MissionControlKit/Sources/MCDesignTokens/DesignTokens.swift` — `MCStaleness`.
- `MissionControl/MissionControlKit/Tests/MCDesignTokensTests/MCStalenessTests.swift` — boundary
  tests pinning this decision's concrete behavior.
