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

## Remaining draft components (v1.1, `design-system-q9vhm`)

Four more components from the claude.ai/design draft, built against sample/placeholder data
(`#Preview` only — not wired into any screen/widget yet, that's `widgets-w4tqx` and a future
task once real provider data exists). All four use only the existing token set, extended with
one new color:

- **`MCColor.merged`** (`systemPurple`) — added because none of the existing state tones fit a
  "PR merged" event; same dynamic-system-color rule as every other `MCColor` token.
- **`MCUsageMetricTile`** (Component) — label/value/limit/percentage/contextual-note tile. The
  bar switches from `MCStatusTone.positive` to `.warning` once consumption exceeds 80% of the
  limit — pure logic exposed as `MCUsageMetricTile.barTone(forFraction:)` /
  `.degradedThreshold` so it's unit-testable without rendering (see `MCUsageMetricTileTests`).
- **`MCUsageGraph`** (Component) — small sparkline area chart (normalized `0...1` samples) with
  an optional dashed threshold line and an hour-tick axis; only the draft's area-chart variant,
  not its column/stacked-bar siblings (out of this task's scope).
- **`MCEventKind`** (design-system vocabulary, like `MCStatusTone`) + **`MCEventRow`**
  (Component) — glyph + text + relative time, one row. Four kinds (`deployOK`/`prMerged`/
  `prOpened`/`buildFailed`), each with a color and an SF Symbol; the draft left the exact SF
  Symbols "to be confirmed" — this task's choice (`arrow.up.circle.fill` /
  `arrow.triangle.merge` / `plus.circle.fill` / `exclamationmark.triangle.fill`) is this v1's
  resolved answer, revisit if it reads wrong in the Xcode Canvas review.
- **`MCProjectCard`** (Component) — name, subtitle, health pill (via `MCStatusPill`), a row of
  per-integration status dots (`MCProjectCard.Integration`), and updated-time — matches the
  `Project` x `Service Integration` shape.

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
