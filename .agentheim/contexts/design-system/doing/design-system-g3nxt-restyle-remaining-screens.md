---
id: design-system-g3nxt
title: Apply design-system tokens to AddProjectSheet and ConnectIntegrationSheet
status: doing
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
`design-system-001-styleguide` wired `MCStatusPill`/`MCStalenessIndicator` into only 3 views
(`ContentView.swift`'s menu bar, `ProjectDetailView.swift`'s integration rows, the desktop
widget). `AddProjectSheet.swift` and `ConnectIntegrationSheet.swift` still render with plain
default SwiftUI styling — stock `.textFieldStyle(.roundedBorder)`, `.font(.callout)`,
`.foregroundStyle(.secondary)` — no `MCColor`/`MCFont`/`MCSpacing`/`MCRadius` anywhere in either
file. That's part of why the app doesn't read as "the design" the user provided: two of its most
commonly-seen screens (adding a project, connecting an integration) never got restyled at all.

## What
Restyle `MissionControl/MissionControl/Views/AddProjectSheet.swift` and
`MissionControl/MissionControl/Views/ConnectIntegrationSheet.swift` to use the design-system's
existing tokens (`MCColor`, `MCFont`, `MCSpacing`, `MCRadius`) in place of default SwiftUI
styling, matching the visual rhythm already established in `ProjectDetailView.swift` and
`ContentView.swift`. No new components needed — this is applying what already exists in
`MCDesignTokens`, not building anything new (contrast with sibling task `design-system-q9vhm`).

## Acceptance criteria
- [ ] `AddProjectSheet.swift` uses `MCColor`/`MCFont`/`MCSpacing` (and `MCRadius` where a corner
      radius is styled) instead of default SwiftUI font/color/spacing modifiers.
- [ ] `ConnectIntegrationSheet.swift` same treatment.
- [ ] Both files gain light and dark `#Preview`s, mirroring the pattern already present in
      `ProjectDetailView.swift` and `IntegrationStatusWidget.swift`.
- [ ] Visually consistent with the rest of the app (spacing rhythm, type scale, corner radii) when
      compared side by side in Xcode Canvas against `ProjectDetailView`. [human-eye]
- [ ] `MissionControl` target still builds clean (`xcodebuild -scheme MissionControl build`).

## Notes
Split out of `design-system-d7fk2` during `modeling` REFINE (2026-08-15), along with sibling
task `design-system-q9vhm` (build the draft's remaining components) — the two are independently
workable and don't depend on each other.
