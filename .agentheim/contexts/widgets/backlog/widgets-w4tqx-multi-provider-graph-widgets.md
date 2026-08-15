---
id: widgets-w4tqx
title: Real-data graph widgets for every provider, authored once and reused app+desktop
status: backlog
type: feature
context: widgets
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
Today the only Desktop Widget is the walking skeleton's single hardcoded Widget Kind, showing
GitHub status only (not user-configurable, not reading any other provider). The user wants real
data, for every provider, once those providers are integrated — and wants building a new widget
to be cheap, not a from-scratch effort per provider.

## What
- When Supabase, Firebase Hosting, and Vercel integrations exist (see `service-integrations`),
  give each a real Widget Kind showing live data — not just a status pill, but graphs: the
  design draft's "usage metric tile" and "traffic/usage graph" (sparkline) components
  (`../design-system/references/mc-design-system-v1-draft.md`), which are specced but not yet
  built (tracked in `design-system-d7fk2`).
- Authoring ergonomics the user explicitly asked for: a graph/component built for the in-app
  dashboard should be reusable as a desktop widget with minimal extra work — "this graph in the
  app is cool, copy paste this in the widget and done, now I have a graph widget." Today the app
  target and the widget extension target duplicate some presentation logic by design (see
  `IntegrationStatusWidget.swift`'s note on `WidgetKindIdentifiers` duplication) — this task
  should look at whether/how a shared graph component can live once and render in both places.
- All of the above should visually match the claude.ai/design draft, same as
  `design-system-d7fk2`.

## Acceptance criteria
- [ ] To be defined during refinement.

## Notes
Captured via `quick-capture` on 2026-08-15 — raw, unrefined. Needs a `modeling` refine pass
before it can be promoted. Likely depends on `service-integrations` adding Firebase Hosting and
Vercel adapters (Supabase adapter already exists; Firebase/Vercel do not yet) — leave dependency
wiring to refinement. Companion capture in `design-system`: `design-system-d7fk2`.
