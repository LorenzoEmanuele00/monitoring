---
id: infrastructure-x23a8
title: Native Swift/SwiftUI macOS app with a WidgetKit extension sharing an App Group and a local Swift package
status: done
type: decision
context: infrastructure
created: 2026-08-07
completed: 2026-08-13
depends_on: []
blocks: []
tags: [captured, architecture-foundation]
related_adrs: [0004]
related_research: []
prior_art: []
---

## Why

ADR-0003 makes native macOS desktop widgets a hard requirement, which fixes the platform as a
native macOS app with a WidgetKit extension. What remains open is how the main app and the
widget extension share code and data. Widget extensions are separate, always-sandboxed
processes with a tight memory/CPU budget, launched and killed by the OS independently of the
main app, and cannot read the app's container directly.

## What

One Xcode project, two bundle targets — `MissionControl.app` (SwiftUI) and
`MissionControlWidgets.appex` (WidgetKit) — plus one in-repo Swift package,
`MissionControlKit`, holding non-UI code as narrow library targets (`MCDomain`, `MCSnapshot`,
`MCPersistence`, `MCSecrets`, `MCProviders`, `MCDesignTokens`). Data is shared through a single
App Group container. The widget extension links only `MCSnapshot` and `MCDesignTokens` — no
network, no database, no credentials inside the extension; it renders exclusively from snapshot
files written by the app. Quick Actions are `AppIntent`s that hand execution to the main app.

Full ADR draft, ready to commit as-is or amended, is in Notes below.

## Acceptance criteria

- [x] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: global`, matching the draft in Notes (or a user-amended version, amendments noted
      in the commit) — committed as ADR-0004, as drafted.
- [x] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07. Blocking prerequisite for the whole App Group / Keychain access group approach:
requires a paid Apple Developer Program membership (confirmed available — local-only use, no
App Store submission needed).

```markdown
---
id: TBD
title: Native Swift/SwiftUI macOS app with a WidgetKit extension sharing an App Group and a local Swift package
scope: global
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [infrastructure-x23a8]
related_research: []
---

# ADR TBD: Native Swift/SwiftUI macOS app with a WidgetKit extension sharing an App Group and a local Swift package

## Context
ADR-0003 makes native macOS desktop widgets a hard requirement, which fixes the platform as a
native macOS app with a WidgetKit extension. What remains open is how the main app and the
widget extension share code and data. Widget extensions on macOS are separate, always-sandboxed
processes with a tight memory and CPU budget, launched and killed by the OS independently of the
main app. They cannot read the app's container directly, and any heavy dependency they link is
paid for on every render.

## Decision
Ship one Xcode project with two bundle targets — `MissionControl.app` (Swift 6, SwiftUI) and
`MissionControlWidgets.appex` (WidgetKit) — plus one in-repo Swift package, `MissionControlKit`,
holding all non-UI code as narrow library targets: `MCDomain`, `MCSnapshot`, `MCPersistence`,
`MCSecrets`, `MCProviders`, `MCDesignTokens`.

Data is shared through a single App Group container
(`$(TeamIdentifierPrefix)group.<reverse-dns>.missioncontrol`), resolved via
`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`.

The widget extension links **only** `MCSnapshot` and `MCDesignTokens`. It performs no network
requests, opens no database, reads no credentials, and loads no remote images. It renders
exclusively from snapshot files written by the app (see the snapshot-cache ADR). Interactive
widget Quick Actions are implemented as `AppIntent`s that hand execution to the main app rather
than executing inside the extension.

## Consequences
### Positive
- The extension's render path is a file read plus a `Codable` decode — comfortably inside its
  memory and CPU budget, and impossible to break by changing a provider adapter.
- Provider, persistence and credential code exists once, is unit-testable outside any app
  target, and cannot accidentally leak into the extension.
- Adding a second extension later (Notification Center, Control Center, a Shortcuts provider)
  reuses the same package and container with no restructuring.

### Negative
- Requires a paid Apple Developer Program membership: App Groups are not provisionable with a
  free personal team, and there is no supported alternative channel to a sandboxed extension.
  This is a hard prerequisite for ADR-0003, not a nicety.
- Every widget-visible datum must be explicitly projected into a snapshot by the app. Data the
  app has but never snapshots is invisible to widgets — an intentional but real constraint.
- Swift-only: no reuse of any existing web/JS UI work.

### Neutral
- Target boundaries inside `MissionControlKit` are cheap to redraw; the app-group boundary and
  the "extension links nothing heavy" rule are the parts that must hold.

## Alternatives considered
- **Electron/Tauri app plus a thin native widget shim** — rejected: the shim needs its own
  native data pipeline and rendering regardless, so this pays for two stacks and delivers the
  widget path (the differentiator, per ADR-0003) as the least-invested part of the system.
- **One monolithic app target, no Swift package** — rejected: the extension would link the whole
  binary's dependency graph, and there would be no compiler-enforced way to keep networking and
  credentials out of the extension.
- **Extension fetches its own data at render time** — rejected: multiplies rate-limit pressure,
  blows the render budget on network latency, and forces credentials into the extension.

## References
- `.agentheim/knowledge/decisions/0003-native-macos-desktop-widgets-are-core.md`
- `.agentheim/contexts/widgets/README.md`
- Apple: App Groups entitlement; WidgetKit; App Extension Programming Guide.
```
