---
id: design-system-d7fk2
title: Bring the app's actual look in line with the claude.ai/design draft
status: backlog
type: feature
context: design-system
created: 2026-08-15
completed:
depends_on: []
blocks: []
tags: [captured]
related_adrs: []
related_research: []
prior_art: []
---

## Why
The user is explicit that the shipped app does not resemble the claude.ai/design draft they
provided ("style apart, that is not what I expect, and should resemble the data I give you as
design"). `design-system-001-styleguide` (done, signed off 2026-08-15) only shipped tokens plus
two components (`MCStatusPill`, `MCStalenessIndicator`), applied to only 3 of the app's views —
the rest of the draft's component set and screen coverage never landed.

## What
Close the gap between the claude.ai/design draft (`../references/mc-design-system-v1-draft.md`
+ `mc-design-system-v1-source.dc.html`) and what's actually built/applied:
- Build the remaining components the draft specced but the styleguide task never built: usage
  metric tile, traffic/usage graph (sparkline), event row, project summary card.
- Apply design-system tokens/components to the screens that currently use zero of them —
  `AddProjectSheet.swift` and `ConnectIntegrationSheet.swift` render with plain default SwiftUI
  styling today (no `MCColor`/`MCFont`/`MCSpacing`/`MCRadius`, no design-system components).
- Standing constraint going forward: any future widget/app frontend work (see
  `widgets-w4tqx`) should visually match this draft, not just reuse the token names.

## Acceptance criteria
- [ ] To be defined during refinement.

## Notes
Captured via `quick-capture` on 2026-08-15 — raw, unrefined. Needs a `modeling` refine pass
before it can be promoted. Companion capture in `widgets`: `widgets-w4tqx` (multi-provider
graph widgets + app/widget component reuse) shares this same visual-fidelity constraint —
refine together if it turns out to be one piece of work rather than two.
