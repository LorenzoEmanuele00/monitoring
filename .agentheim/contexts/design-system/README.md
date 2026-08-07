# Design System

## Purpose
Owns the macOS app's and its widgets' shared visual language — tokens, components, layout
patterns — and the review process that signs off on them before any bounded context builds its
own frontend. Frontend infrastructure with its own vocabulary and review cadence, kept separate
from the technical `infrastructure` BC.

## Classification
supporting — enables consistent, fast frontend work across every BC but isn't itself the
product's core value.

## Actors
The user, as the sole reviewer and approver of the styleguide.

## Ubiquitous language
- **Token** — a named design value (color, spacing, type scale) other BCs reference instead of
  hardcoding.
- **Component** — a reusable, styled UI building block built from tokens.
- **Style** — the overall visual language tokens and components compose into.
- **Review gate** — the human-in-the-loop checkpoint (`design-system-001-styleguide`) that must
  be signed off before any frontend feature task in any BC is promoted to work.

## Aggregates
None yet — this BC holds design tokens/components, not domain aggregates.

## Key events
- **Styleguide reviewed and approved**

## Key commands
- **Propose token/component**
- **Review styleguide**

## Relationships with other contexts
- **Upstream (open host / published language) of every frontend-bearing context:** Project
  Registry (in-app UI) and Widgets both conform to tokens/components defined here rather than
  styling independently.
- See `context-map.md` for the full picture.

## Open questions
- None yet — populated once the styleguide task (`design-system-001-styleguide`) is underway.
