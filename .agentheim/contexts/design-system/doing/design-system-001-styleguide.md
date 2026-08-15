---
id: design-system-001-styleguide
title: Styleguide — tokens and components for the app and its widgets, human-reviewed before any BC builds frontend
status: doing
type: feature
context: design-system
created: 2026-08-07
completed:
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [captured, architecture-foundation, styleguide-gate]
related_adrs: [0015]
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

- [x] Token set (color, spacing, type) and initial component set defined in `MCDesignTokens`
      (the target already scaffolded per `infrastructure-x23a8`, linked by both the app and the
      widget extension).
- [x] At least the staleness-indicator and status-pill components render correctly in both the
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

**Resolved 2026-08-15:** kept the draft's tighter 15min/60min thresholds (ADR-0015) — full
rationale there and in the BC README's "Resolved decision" section.

## Ready for human review

Everything buildable is done; acceptance criteria 1 and 2 are met. Criterion 3 (human sign-off)
is intentionally left unchecked — only the user can satisfy it. This task stays in `doing/`
until that happens.

**What was built** (`MissionControl/MissionControlKit/Sources/MCDesignTokens/`):
- `DesignTokens.swift` — `MCColor` (state + surface/label tones, all AppKit-semantic-color
  backed for automatic light/dark), `MCSpacing` (s1-s7), `MCRadius` (pill/control/tile/card/
  widget), `MCFont` (SF Pro/SF Mono system stack, sans + monospaced scales), `MCStaleness`
  (freshness classification, thresholds resolved to 15min/60min — ADR-0015).
- `Components/MCStatusPill.swift` — colored dot + word status pill, `MCStatusTone` vocabulary
  (positive/warning/negative/running/neutral).
- `Components/MCStalenessIndicator.swift` — relative-time label + freshness-level dot.

**Where both components render** (both targets build clean via `xcodebuild`):
- In-app dashboard: `MissionControl/MissionControl/Views/ContentView.swift`
  (`MenuBarContentView` — status pill per Integration) and
  `MissionControl/MissionControl/Views/ProjectDetailView.swift` (`IntegrationRow` — status pill
  + staleness indicator from `lastSuccessAt`).
- Desktop Widget: `MissionControl/MissionControlWidgets/IntegrationStatusWidget.swift`
  (`IntegrationStatusWidgetView` — status pill + staleness indicator from `snapshot.generatedAt`).

**How to look at it in Xcode** (open `MissionControl/MissionControl.xcodeproj`, or regenerate
via `xcodegen generate` from `MissionControl/` first if the project file is stale — safe to do:
as of iteration 2 of this task, `MissionControl/project.yml` carries every hand-added build
setting `xcodegen generate` used to silently drop on regeneration, so the round-trip is now
lossless; see `## Fixed (iteration 2)` below for what that fixed and why):
- `MCStatusPill.swift` and `MCStalenessIndicator.swift` each carry two `#Preview`s (light/dark)
  showing every tone/level side by side — open either file and use the Canvas (Editor > Canvas).
- `ContentView.swift` — "Menu bar — light/dark" previews, all four `IntegrationStatus` states.
- `ProjectDetailView.swift` — "Integration row — light/dark" previews (connected/fresh,
  degraded/subdued, disconnected/flagged-with-error).
- `IntegrationStatusWidget.swift` — six previews spanning `.systemSmall`/`.systemMedium`/
  `.systemLarge` canvas sizes (approximate) x light/dark, plus a "no data yet" small-widget
  state in both appearances. Note: only `.systemSmall`/`.systemMedium` are in the widget's
  actual `supportedFamilies` (a Widgets-BC decision, unchanged here) — the `.systemLarge`
  preview validates that the components themselves scale, not that the widget ships that size.

**What the user should sign off on:**
1. The token set — do the color/spacing/type choices look right for a native macOS "glanceable
   cockpit," and does the light/dark story actually look correct (not just present)?
2. `MCStatusPill` and `MCStalenessIndicator` — do they read clearly at the small-widget size
   (170pt-ish canvas), and does "color + word together" actually avoid ambiguity?
3. The resolved staleness thresholds (15min subdued / 60min flagged, ADR-0015) — reasonable, or
   should they be loosened/tightened before other BCs start building against them?
4. Whether this v1 set (tokens + two components) is enough to unblock other frontend-bearing BCs,
   or whether more components (e.g. the usage metric tile, event row, project card from the
   draft) should be added before sign-off.

**Tests:** `MissionControl/MissionControlKit/Tests/MCDesignTokensTests/` — `MCStalenessTests`
(6 tests, pins the resolved threshold boundaries) and `MCStatusToneTests` (5 tests, pins the
tone-to-color mapping). Full suite: `swift test` from `MissionControl/MissionControlKit/`, 33/33
passing. App/widget targets: `xcodebuild -project MissionControl.xcodeproj -scheme
MissionControl build` and `-scheme MissionControlWidgets build`, both `BUILD SUCCEEDED`.

## Verifier note (iteration 1)

VERDICT: FAIL

REASONS:
- Scope discipline (check 3): `MissionControl/MissionControl.xcodeproj/project.pbxproj` carries
  large, unrelated config churn beyond the one change the task needed (registering the new
  `IntegrationStatus+Presentation.swift` in the app target). The worker regenerated the project
  with `xcodegen generate`, and since none of these settings exist in `MissionControl/project.yml`,
  regeneration silently discarded them: `REGISTER_APP_GROUPS = YES` (all four configurations),
  `DEVELOPMENT_TEAM = 2C553PK57P` on the widget target's Debug/Release buildSettings,
  `DEAD_CODE_STRIPPING`, `ENABLE_USER_SCRIPT_SANDBOXING`, `STRING_CATALOG_GENERATE_SYMBOLS`, and
  the widget's `ENABLE_INCOMING_NETWORK_CONNECTIONS` / `ENABLE_OUTGOING_NETWORK_CONNECTIONS` /
  `ENABLE_RESOURCE_ACCESS_*` entries, plus `LastUpgradeCheck` rolled back 2660 → 1430.
- That churn is not cosmetic: it reverts the root-cause fix landed one commit earlier by
  `infrastructure-w4dg3` (commit 76e5b7f, "widget 'No data yet' root-caused to a wildcard
  provisioning profile missing App Groups"), whose commit message names the fix as "visible in the
  pbxproj diff as newly-added `REGISTER_APP_GROUPS = YES` on both targets". The infrastructure BC
  README's "Second provisioning caveat" documents exactly this failure mode — an App Groups
  entitlement declared only in the xcodegen-authored `.entitlements` file is necessary but not
  sufficient without portal registration. Removing `REGISTER_APP_GROUPS` reinstates the
  wildcard-profile condition that made the Desktop Widget show "No data yet".
- The worker's build evidence cannot detect this regression: both targets do build clean
  (`xcodebuild -scheme MissionControl build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` →
  `** BUILD SUCCEEDED **`), but `CODE_SIGNING_ALLOWED=NO` bypasses provisioning entirely, which is
  the only place the removed setting has effect.
- The task file's own review instructions propagate the hazard: telling the user to "regenerate
  via `xcodegen generate` from `MissionControl/` first if the project file is stale" would
  re-inflict the same loss every time it is followed.

Checks that passed (for the next worker's benefit): acceptance criterion 1 is genuinely met;
criterion 2 is met in substance (both components wired into `MenuBarContentView`,
`IntegrationRow`, and `IntegrationStatusWidgetView`, each with light/dark previews, app+widget
build succeeding); `swift test` exits 0, "Test run with 33 tests in 8 suites passed"; ADR-0015 is
well-formed and consistent with ADR-0008's delegation; the BC README is genuinely in sync; the
"Ready for human review" section is accurate apart from the regeneration advice above; the
`doing/` state and unchecked criterion 3 were correctly NOT treated as defects.

SUGGESTED_FIX: Restore the settings `xcodegen generate` dropped from `project.pbxproj` — at
minimum `REGISTER_APP_GROUPS = YES` on both targets in all four configurations — preferably by
adding them to `MissionControl/project.yml` so regeneration is lossless rather than by
hand-patching the generated file, and reword the task's "regenerate via `xcodegen generate`"
review instruction so it no longer tells the user to re-trigger the loss.

ITERATION_HINT: likely-fixable

## Fixed (iteration 2)

Root cause: `MissionControl/project.yml` (xcodegen's source of truth) never carried the
hand-added `project.pbxproj` settings that iteration-1's `xcodegen generate` silently dropped.
Verified the exact drop set by diffing against the commit immediately before this task's batch
start (`76e5b7f`, `infrastructure-w4dg3`'s App Groups fix) — confirmed every item the verifier
enumerated and nothing else.

**Added to `MissionControl/project.yml`** (so future `xcodegen generate` runs are lossless):
- Top-level `settings.base`: `DEAD_CODE_STRIPPING: YES`, `ENABLE_USER_SCRIPT_SANDBOXING: YES`,
  `STRING_CATALOG_GENERATE_SYMBOLS: YES` (project-wide Debug/Release configs).
- `MissionControl` target `settings.base`: `DEAD_CODE_STRIPPING: YES`,
  `REGISTER_APP_GROUPS: YES` (the infrastructure-w4dg3 fix for the widget's "No data yet" bug).
- `MissionControlWidgets` target `settings.base`: `DEAD_CODE_STRIPPING: YES`,
  `DEVELOPMENT_TEAM: "2C553PK57P"`, `REGISTER_APP_GROUPS: YES`, and the ten App-Sandbox mirror
  settings (`ENABLE_INCOMING_NETWORK_CONNECTIONS`, `ENABLE_OUTGOING_NETWORK_CONNECTIONS`, all
  eight `ENABLE_RESOURCE_ACCESS_*` flags) — all set to `NO`, matching the pre-regression file.
- Re-ran `xcodegen generate`; the widget's `TargetAttributes.<id>.DevelopmentTeam` attribute
  regenerated automatically once `DEVELOPMENT_TEAM` was present in that target's own settings
  (no separate project.yml key needed for that one).

**One item project.yml genuinely cannot express**: `LastUpgradeCheck` (PBXProject attribute).
Tested empirically — adding a top-level `attributes: {LastUpgradeCheck: 2660}` block to
project.yml round-tripped through `xcodegen generate` with zero effect on the output (confirmed
by diffing before/after; the value stayed at whatever the local Xcode/xcodegen combo computes,
1430 in this environment). xcodegen writes this value unconditionally from the installed
toolchain at generation time — it isn't a project.yml-configurable setting in this xcodegen
version (2.46.0). Removed the ineffective `attributes:` block from project.yml (dead
configuration would be misleading) and instead hand-patched `project.pbxproj`'s
`LastUpgradeCheck` back to `2660` directly, with a comment in project.yml explaining why this
one field will legitimately drift on any machine with a different Xcode and is not a regression
if it does — it's purely cosmetic (Xcode's "recommended settings" banner) and has no effect on
build or provisioning behavior, unlike every other setting on the drop list.

**Confirmation of the fix** — diffed the regenerated `project.pbxproj` against the pre-regression
commit `76e5b7f`: the only remaining differences are the task's own intended change (registering
`IntegrationStatus+Presentation.swift` in the app target's sources) and one harmless addition
(`name = MissionControlKit;` on the SPM package file reference, a benign xcodegen-version
artifact, not a drop). Grep counts against the current file: `REGISTER_APP_GROUPS = YES` x4,
`DEAD_CODE_STRIPPING = YES` x6, `ENABLE_USER_SCRIPT_SANDBOXING = YES` x2,
`STRING_CATALOG_GENERATE_SYMBOLS = YES` x2, widget `DEVELOPMENT_TEAM = 2C553PK57P` x4 (2
target-level + 2 TargetAttributes — this went from 1 TargetAttributes occurrence in the
pre-regression file to 2, an additive, benign change: the widget target's TargetAttributes
entry now also carries `DevelopmentTeam` once `DEVELOPMENT_TEAM` was present in that target's
own settings), 16 `ENABLE_RESOURCE_ACCESS_*` lines, 4 `ENABLE_*_NETWORK_CONNECTIONS = NO` lines,
and `LastUpgradeCheck = 2660`.

**Evidence re-run**: `swift test` from `MissionControl/MissionControlKit` — 33/33 tests passing,
unchanged from iteration 1. `xcodebuild -scheme MissionControl -project
MissionControl.xcodeproj build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` — BUILD
SUCCEEDED. `xcodebuild -scheme MissionControlWidgets -project MissionControl.xcodeproj build
CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` — BUILD SUCCEEDED. As the verifier noted, the
`CODE_SIGNING_ALLOWED=NO` builds can't exercise `REGISTER_APP_GROUPS` themselves — the grep/diff
confirmation above against the pre-regression file is the actual evidence for this fix.

Reworded the "Ready for human review" section's regeneration instruction: it now tells the
reviewer regeneration is safe because `project.yml` was made lossless this iteration, pointing
here for why.

Files touched this iteration: `MissionControl/project.yml`,
`MissionControl/MissionControl.xcodeproj/project.pbxproj`. No source code, no BC README changes
(no new ubiquitous language), no new ADR (this is a bugfix restoring prior intent per the
verifier's suggested fix, not a new design decision).

## Verifier note (iteration 2)

VERDICT: FAIL

REASONS:
- **The iteration-1 regression IS genuinely fixed — verified independently, this is not the
  failure reason.** `git diff 76e5b7f -- MissionControl/MissionControl.xcodeproj/project.pbxproj`
  is now 6 insertions / 1 deletion, all legitimate. Direct grep against the pre-regression file
  matches on every family (`REGISTER_APP_GROUPS`, `DEAD_CODE_STRIPPING`,
  `ENABLE_USER_SCRIPT_SANDBOXING`, `STRING_CATALOG_GENERATE_SYMBOLS`, `DEVELOPMENT_TEAM`,
  `ENABLE_RESOURCE_ACCESS_*`, the network-connection flags, `LastUpgradeCheck`). `project.yml`
  genuinely declares all of these, so regeneration is structurally lossless, not hand-patched.
- **Blocking defect (check 6):** `MissionControl/project.yml:8` opens the new guidance block with
  `# ADR-0016 (regeneration-losslessness): ...`. **ADR-0016 does not exist** —
  `.agentheim/knowledge/decisions/` stops at `0015`. The task file's own `## Fixed (iteration 2)`
  above states "no new ADR ... not a new design decision" — so committed source-of-truth config
  asserts a durable decision record that was consciously never written. The cited rule is not
  trivial: this exact gap silently dropped `REGISTER_APP_GROUPS` and reinstated the
  wildcard-profile "No data yet" bug, costing a full verification iteration.
  `.agentheim/knowledge/decisions/0013-xcodegen-generated-xcodeproj.md` even anticipates it under
  Consequences > Negative ("Two files must stay in sync ... worth a pre-commit hook if this
  becomes a recurring mistake"). It has now recurred. A phantom citation is worse than no citation
  here, because the comment block is itself the only guardrail against recurrence.
- Secondary: the worker hand-patched `LastUpgradeCheck = 2660` back into the generated
  `project.pbxproj`, while the same file's own comment (`project.yml:14-23`) states the field
  "will legitimately drift ... expected xcodegen behavior, not a regression to fix here." Those
  two acts contradict — the hand-patch re-creates the "setting that only lives hand-added in the
  committed pbxproj" pattern the comment forbids six lines above, and the next `xcodegen generate`
  will silently revert it. The cosmetic-only claim itself is plausible and consistent (drives
  Xcode's "recommended settings" banner only, no build/provisioning effect).
- Minor record inaccuracies in `## Fixed (iteration 2)` above, worth correcting: "all **nine**
  `ENABLE_RESOURCE_ACCESS_*` flags" should read **eight** (8 x 2 configs = 16 observed lines); the
  claim that `DevelopmentTeam` TargetAttributes count "match[es] the pre-regression file exactly"
  is wrong — it went 1 → 2 (additive, benign, visible in the diff).
- Everything else re-checked clean: this iteration's commit touches only 3 files (task md,
  `project.pbxproj`, `project.yml`) — no token/component source touched, criteria 1 and 2 stand
  exactly as the iteration-1 verifier approved them. `swift test` 33/33 passing. Both `xcodebuild`
  targets `BUILD SUCCEEDED`. `doing/` status and unchecked criterion 3 correctly not treated as
  defects.

SUGGESTED_FIX: Resolve the dangling citation at `project.yml:8` one of two ways — either write
`.agentheim/knowledge/decisions/0016-*.md` recording the regeneration-losslessness rule, or
re-point the comment at the existing ADR-0013 (which already establishes `project.yml` as
authoritative). While there, make the `LastUpgradeCheck` handling self-consistent (preferably
drop the hand-patch and let it drift as the comment says it will), and fix the "nine flags" /
`DevelopmentTeam`-count wording in `## Fixed (iteration 2)`. Do not redo or re-touch the settings
restoration or any token/component source — both are verified correct and any regeneration risk
is unnecessary.

ITERATION_HINT: likely-fixable

## Fixed (iteration 3)

Three narrow fixes, per the iteration-2 verifier's two blocking/secondary reasons plus its noted
wording nits. No settings-restoration or token/component work re-touched.

1. **Phantom citation** — `MissionControl/project.yml`'s comment block previously cited a
   nonexistent `ADR-0016`. Re-pointed it at the existing `ADR-0013`
   (`.agentheim/knowledge/decisions/0013-xcodegen-generated-xcodeproj.md`), which already
   establishes `project.yml` as authoritative and, under Consequences > Negative, anticipates
   this exact sync-gap failure mode ("Two files must stay in sync ... a project.yml edit
   without a re-generate silently does nothing"). The reworded comment quotes that line and
   points to this task's iteration-1 verifier note as the concrete instance of the gap.
2. **`LastUpgradeCheck` self-contradiction** — dropped the iteration-2 hand-patch. Re-ran
   `xcodegen generate` (same toolchain, xcodegen 2.46.0) and confirmed the only resulting diff
   in `project.pbxproj` is `LastUpgradeCheck = 2660` → `1430` (the value this environment's
   `xcodegen generate` actually produces). The comment's "will legitimately drift, not a
   regression to fix here" claim is now true in practice, not just in prose — nothing about
   this field is hand-overridden anymore.
3. **Wording fixes** in `## Fixed (iteration 2)` above: "nine `ENABLE_RESOURCE_ACCESS_*` flags"
   → "eight" (matches the 16 observed lines at 8 x 2 configs); the `DevelopmentTeam`
   `TargetAttributes` count description corrected to say it went from 1 → 2 occurrences
   (additive/benign — the widget's `TargetAttributes` entry now also carries `DevelopmentTeam`),
   not "matches exactly."

Files touched: `MissionControl/project.yml` (comment reworded), `MissionControl/MissionControl.
xcodeproj/project.pbxproj` (`LastUpgradeCheck` reverted to the un-patched regenerated value, via
`xcodegen generate` — no other lines changed, confirmed by diff). No new ADR needed (Option A).
`swift test` re-run: 33/33 passing, unchanged.
