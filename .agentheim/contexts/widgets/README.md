# Widgets

## Purpose
Renders configurable views of Project and Service Integration data, both inside the app's own
dashboard and as native macOS desktop widgets (via WidgetKit) that keep working when the app
itself is closed. This is the context that owns "what the user actually looks at."

## Classification
core — native desktop widgets that work without the app open are the product's key
differentiator, not a delivery detail bolted onto a normal dashboard.

## Actors
The user, in the role of arranging, configuring, and placing Widgets (both in-app panels and
OS-level desktop widgets).

## Ubiquitous language
- **Widget** — a configurable, glanceable view of a Project or a Service Integration's data.
- **Widget Kind** — a specific type of Widget (e.g. "GitHub PR status", "Vercel usage graph",
  "deploy timeline") that knows how to render one shape of Integration data.
- **Widget Configuration** — the user's choices for one Widget instance (which Project, which
  Integration, which display options).
- **Desktop Widget** — a Widget instance placed on the macOS desktop or Notification Center via
  WidgetKit; refreshes on an OS-managed schedule and renders even when the app is not open.
- **In-App Panel** — a Widget instance rendered inside the app's own dashboard window, with no
  OS refresh-budget constraint.

## Aggregates
- **Widget** — protects the invariant that a Widget Configuration always resolves to exactly
  one Widget Kind and references only Projects/Integrations that actually exist.

## Key events
- **Widget added** / **Widget reconfigured** / **Widget removed**
- **Widget placed as desktop widget**

## Key commands
- **Add widget**
- **Configure widget**
- **Place on desktop**

## Relationships with other contexts
- **Customer of Project Registry and Service Integrations:** reads their data as an open host;
  never writes back to either.
- **Conformist to Design System:** all Widget visuals (in-app and desktop) use Design System
  tokens/components rather than styling independently — this context ships no frontend feature
  before `design-system-001-styleguide` is signed off.
- See `context-map.md` for the full picture.

## Open questions
- Which Widget Kinds ship for mise_pwa's onboarding (GitHub, Firebase Hosting, Supabase), and
  which are generic enough to reuse unchanged for the next Project?
