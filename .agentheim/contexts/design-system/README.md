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

## Shipped tokens and components (v1, pending human sign-off)

Built in `MissionControlKit/Sources/MCDesignTokens` (linked by both the app and the widget
extension, per `infrastructure-x23a8`). Validated against the real WidgetKit render surface:
`MissionControl` (in-app dashboard: `MenuBarContentView`, `IntegrationRow` in
`ProjectDetailView.swift`) and `MissionControlWidgets` (`IntegrationStatusWidgetView`), both
built successfully via `xcodebuild`, both carrying light/dark SwiftUI previews.

- **`MCColor`** — state tones (`connected`/`degraded`/`error`/`running`/`idle`/`accent`) and
  surface/label tones (`windowBackground`/`contentBackground`/`raisedBackground`/`separator`/
  `label`/`secondaryLabel`/`tertiaryLabel`), every one mapped to a real AppKit semantic
  `NSColor` (never a hand-maintained hex pair) so light/dark and the user's own accent-color
  choice come for free from macOS.
- **`MCSpacing`** — `s1`…`s7` (2/4/8/12/16/24/32 pt).
- **`MCRadius`** — `pill`/`control`/`tile`/`card`/`widget` (4/6/8/10/18 pt); pill-shaped
  components use `Capsule()` directly rather than this fixed radius.
- **`MCFont`** — SF Pro / SF Mono system stack only (no custom typeface):
  `title1`/`title3`/`headline`/`body`/`subheadline`/`caption` (sans) and
  `monoNumeric`/`monoData`/`monoLabel` (monospaced, tabular figures for numeric data).
- **`MCStaleness`** — freshness-level classification (`fresh`/`subdued`/`flagged`) driving every
  staleness indicator; thresholds resolved at **15 min / 60 min** (see "Resolved decision"
  below), overridable per call site.
- **`MCStatusPill`** (Component) — colored dot + word (state is never color alone, per the
  design draft's principle), tone driven by the design system's own `MCStatusTone` vocabulary
  (`positive`/`warning`/`negative`/`running`/`neutral`) — deliberately not tied to any BC's
  domain enum; call sites (`IntegrationStatus+Presentation.swift` in the app target, a local
  extension in the widget target) map their own domain state to a tone + label.
- **`MCStalenessIndicator`** (Component) — relative-time label + a dot whose shape/color encodes
  `MCStaleness.Level`; always renders alongside the last-known value, never an empty placeholder.

## Resolved decision — staleness thresholds

`infrastructure-mam0r`'s ADR-0008 left staleness thresholds as a placeholder ("suggested: ~30
min / ~2 h") and explicitly delegated the concrete figures to Widgets/Design System. The design
draft (`references/mc-design-system-v1-draft.md`) proposed a tighter, competing guess (15
min/60 min) and flagged the conflict for this task to resolve. **Resolved: 15 min (subdued) / 60
min (flagged)** — the tighter figure, favoring visibility over a calmer-looking but more
permissive default, matching the glanceable-cockpit vision (ADR-0002). Full rationale in
ADR-0015.

## Open questions
- None outstanding — the one concrete conflict (staleness thresholds) is resolved above.
- Human sign-off on this v1 token/component set is still pending
  (`design-system-001-styleguide`'s third acceptance criterion) — until recorded, no
  frontend-bearing BC promotes a UI feature task to `todo`.
- A draft token/component direction exists at `references/mc-design-system-v1-draft.md`
  (external input from claude.ai/design, 2026-08-07) — superseded as raw material now that this
  task has validated and adopted (with adjustments) its direction; kept for historical reference.
