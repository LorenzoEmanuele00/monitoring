---
id: design-system-q9vhm
title: Build the design draft's remaining components — usage tile, usage graph, event row, project card
status: todo
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
`design-system-001-styleguide` (done) only built 2 of the 6 components specced in the
claude.ai/design draft (`MCStatusPill`, `MCStalenessIndicator`). The remaining 4 — usage metric
tile, traffic/usage graph (sparkline), event row, project summary card — are exactly the
components that will carry real per-provider data once `widgets-w4tqx` (Supabase/Firebase/Vercel
widgets) is worked, and are also what made the draft mockup look like "a product" rather than
two small status atoms. Building them now, against sample data, means they're ready the moment
real provider data exists rather than needing a second design pass later.

## What
Add four new components to `MCDesignTokens/Components/`, following their specs in
`../references/mc-design-system-v1-draft.md`:
- **Usage metric tile** — label, value, limit, percentage, contextual note (e.g. "reset fra 12
  giorni", "soglia 80% superata"); bar color switches to the `degraded` tone past 80% of limit.
- **Traffic/usage graph** — small sparkline-style area chart with an hour-tick axis and a visible
  threshold line.
- **Event row** — glyph + text + relative time; glyph color keyed to event type (deploy ok, PR
  merged, PR opened, build failed).
- **Project summary card** — name, subtitle, health pill, updated-time, row of per-integration
  status dots (matches the `Project` x `Service Integration` shape).

**Color-fidelity call (resolved this refinement, 2026-08-15):** keep mapping every color token
to macOS's dynamic system colors (`systemGreen`, `controlAccentColor`, etc.), as
`design-system-001-styleguide` already established — do **not** hardcode the draft's literal hex
pairs. These new components use only existing `MCColor`/`MCSpacing`/`MCRadius`/`MCFont` tokens
(extending them if a genuinely new token is needed), never a new hand-maintained hex value.

Build with sample/placeholder data via SwiftUI `#Preview`, same pattern
`IntegrationStatusWidget.swift`'s `IntegrationStatusEntry.sample(...)` already uses — no live
Supabase/Firebase/Vercel data is available yet (that's `widgets-w4tqx`), and this task doesn't
wait on it.

## Acceptance criteria
- [ ] `MCUsageMetricTile`, `MCUsageGraph`, `MCEventRow`, `MCProjectCard` added to
      `MissionControl/MissionControlKit/Sources/MCDesignTokens/Components/`.
- [ ] `MCUsageMetricTile`'s bar switches to the `degraded` tone once value/limit exceeds 80% —
      covered by a unit test (mirrors `MCStalenessTests`/`MCStatusToneTests`).
- [ ] Each component has at least one light and one dark `#Preview` using sample data.
- [ ] Each component visually matches its spec in `mc-design-system-v1-draft.md` (layout, states,
      iconography) when viewed in Xcode Canvas. [human-eye]
- [ ] `MissionControl` and `MissionControlWidgets` targets still build clean
      (`xcodebuild -scheme <target> build`) — these components aren't wired into any screen or
      widget yet, so this only confirms the new Swift compiles cleanly alongside existing code.

## Notes
Split out of `design-system-d7fk2` during `modeling` REFINE (2026-08-15), along with sibling
task `design-system-g3nxt` (apply tokens/components to the two under-styled screens) — the two
are independently workable and don't depend on each other. Not wiring these components into any
actual screen/widget is deliberate scope: that's `widgets-w4tqx`'s job once real provider data
exists, and (for existing screens) a possible future task once these components exist to apply.
