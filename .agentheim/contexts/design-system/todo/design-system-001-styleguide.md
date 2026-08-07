---
id: design-system-001-styleguide
title: Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
status: todo
type: feature
context: design-system
created: 2026-08-07
completed:
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [captured, architecture-foundation, styleguide-gate]
related_adrs: []
related_research: []
prior_art: []
---

## Why

Two bounded contexts build frontend — Project Registry's in-app UI and Widgets' in-app panels
and desktop widgets — and both need a shared visual language rather than styling independently.
Building this on top of the running walking skeleton (rather than in a vacuum) means the tokens
and components get proven against a real widget render surface, including the small-size
constraints WidgetKit families impose.

## What

Define the initial Design System: color tokens (including a light/dark story — macOS respects
system appearance by default), spacing/type scale tokens, and a small set of core components
(e.g. a status pill for Integration health, a staleness indicator per
`infrastructure-mam0r`'s failure policy, a compact metric tile for usage graphs). Validate the
tokens/components render correctly at the actual WidgetKit family sizes (small/medium/large) used
by the walking skeleton's Desktop Widget, not just in the main app window.

## Acceptance criteria

- [ ] Token set (color, spacing, type) and initial component set defined in `MCDesignTokens`
      (the target already scaffolded per `infrastructure-x23a8`, linked by both the app and the
      widget extension).
- [ ] At least the staleness-indicator and status-pill components render correctly in both the
      in-app dashboard and the walking skeleton's Desktop Widget, in both light and dark
      appearance.
- [ ] **Human-in-the-loop checkpoint:** the user has reviewed and signed off on the design system
      before any frontend feature task in any BC is promoted to `todo`. This is a gate, not just
      a deliverable — do not treat the component set as done until sign-off is recorded.

## Notes

Every frontend-bearing BC's README must note this gate: no BC implements its UI before this task
is done and signed off. `project-registry/README.md` and `widgets/README.md` already carry the
"conformist to Design System" relationship note pointing back here.

**Draft input captured 2026-08-07** (while waiting on the Apple Developer Program enrollment
that gates the walking skeleton): a token/component direction produced via claude.ai/design is
saved at `../references/mc-design-system-v1-draft.md` (plus the raw exported source alongside
it). It covers semantic system colors, an SF Pro/SF Mono type scale, spacing/radii scales, and
specs for the status pill, staleness indicator, usage tile, event row, and project card. Treat
it as a starting point to validate against the real WidgetKit surface when this task actually
runs — not a pre-approved final answer. One concrete conflict to resolve: its staleness
thresholds (15min warn / 60min stale) differ from `infrastructure-mam0r`'s placeholder
30min/2h guess.
