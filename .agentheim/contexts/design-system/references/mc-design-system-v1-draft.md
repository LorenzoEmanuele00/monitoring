# MC Design System — v1 draft (external input, not sign-off)

**Status: draft input to `design-system-001-styleguide`, not a finalized styleguide.**
Produced 2026-08-07 via claude.ai/design, while waiting on the Apple Developer Program
enrollment that gates the walking skeleton. Per that task's acceptance criteria, formal
sign-off is deliberately deferred until these tokens/components can be validated against a
real WidgetKit render surface (actual widget families, actual macOS light/dark switching) —
this page is the raw material for that pass, not a substitute for it.

Raw exported source (literal token data, React/HTML mockup) kept alongside this summary at
`mc-design-system-v1-source.dc.html` for full fidelity if exact figures are needed later.

## Direction

Semantic system colors, not a brand palette — every color token maps to a real AppKit
semantic color (`controlAccentColor`, `systemGreen`, etc.) with explicit light/dark hex pairs,
so the app follows the user's own accent-color and appearance choices rather than imposing a
brand look. Stated design principles from the export: *state is communicated as color + word
together (never color alone)*, *if a component doesn't survive a 170pt-wide small widget, it
doesn't enter the set*, *numeric values are always tabular figures*.

## Fonts

- **UI text:** `-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif`
- **Numeric / data / code:** `ui-monospace, 'SF Mono', Menlo, monospace`

No custom typeface — pure system stack. (An earlier draft in the same export batch used
Google Fonts Inter Tight / JetBrains Mono; this v1 correctly moved to real system fonts for
the native-macOS direction we agreed on.)

## Color tokens

Semantic tokens, each with a light/dark hex pair:

| Token | AppKit mapping | Light | Dark |
|---|---|---|---|
| `accent` | `controlAccentColor` | `#0A6CFF` | `#0A84FF` |
| `connected` | `systemGreen` | `#248A3D` | `#30D158` |
| `degraded` | `systemOrange` | `#C93400` | `#FF9F0A` |
| `error` | `systemRed` | `#D70015` | `#FF453A` |
| `running` | `systemBlue` | `#0040DD` | `#0A84FF` |
| `idle` | `systemGray` | `#8A8A8E` | `#8E8E93` |

Surface/label swatches (dark / light):

| Name | Dark hex | Light hex | Maps to |
|---|---|---|---|
| window | `#1E1E1E` | `#ECECEE` | `windowBackground` |
| content | `#2A2A2C` | `#FFFFFF` | `controlBackground` |
| raised | `#323234` | `#F7F7F8` | `underPageBackground` |
| separator | `#3A3A3C` | `#D8D8DA` | `separatorColor` |
| label | `#F5F5F7` | `#000000` | `labelColor · 100%` |
| secondaryLabel | `#8E8E93` | `#8A8A8E` | `labelColor · 55%` |
| tertiaryLabel | `#636366` | `#B0B0B4` | `labelColor · 25%` |
| accent | `#0A84FF` | `#0A6CFF` | `controlAccentColor` |

## Type scale

| Token | Size | Weight | Family | Sample |
|---|---|---|---|---|
| title1 | 22px | 700 | SANS | "mise_pwa" |
| title3 | 15px | 600 | SANS | "Integrazioni attive" |
| headline | 13px | 600 | SANS | "Firebase Hosting" |
| body | 13px | 400 | SANS | full sentence copy |
| subheadline | 11px | 400 | SANS | "aggiornato 2 minuti fa" |
| caption (widget) | 10px | 400 | SANS | "Hosting 6,2 / 10 GB" |
| mono-numeric | 20px | 400 | MONO | "1.284" |
| mono-data | 11px | 400 | MONO | "a3f9c21 · master · 99,98%" |
| mono-label | 10px | 500 | MONO | "ULTIMO DEPLOY" (0.08em tracking) |

## Spacing scale

`s-1` 2px · `s-2` 4px · `s-3` 8px · `s-4` 12px · `s-5` 16px · `s-6` 24px · `s-7` 32px

## Corner radii

4px (pill) · 6px (control) · 8px (tile) · 10px (card) · 18px (widget)

## Components specced

- **Status pill** — 5 states (Connesso/OK, Degradato, Errore, Deploy in corso, Non
  configurato), each with dot + foreground + background color, light and dark variants.
- **Staleness indicator** — 3 states driven by two thresholds, exposed as configurable props
  in the export: `warnMinutes` (default 15) and `staleMinutes` (default 60).
  - **Fresco** (0–warn): relative time in secondaryLabel, green dot, no emphasis.
  - **In ritardo** (warn–stale): orange pill labeled "in ritardo", value keeps a step of
    contrast.
  - **Stale** (>stale): empty ring dot, gray pill, value drops to tertiaryLabel — last known
    value is always shown, never an empty placeholder.
  - Note: `infrastructure-mam0r`'s failure-policy ADR draft suggested ~30min/~2h as
    placeholder thresholds; this export's 15min/60min is a tighter, competing guess —
    reconcile the two when the styleguide task actually runs.
- **Usage metric tile** — label, value, limit, percentage, a contextual note (e.g. "reset fra
  12 giorni", "soglia 80% superata"), bar color switches to degraded past 80%.
- **Traffic/usage graph** — small sparkline-style area chart with an hour-tick axis and a
  visible threshold line.
- **Event row** — glyph + text + relative time, glyph color keyed to event type (deploy ok,
  PR merged, PR opened, build failed).
- **Project summary card** — name, subtitle, health pill, updated-time, and a row of
  per-integration status dots — directly matches the `Project` × `Service Integration`
  shape from `project-registry`/`service-integrations`.

## Open questions carried forward

- Reconcile the staleness thresholds here (15/60 min) against `infrastructure-mam0r`'s
  30min/2h placeholder — pick one during the styleguide task, not before.
- None of this has been checked against actual WidgetKit family constraints yet (small/medium
  widget canvas, system-imposed padding) — that validation is exactly what
  `design-system-001-styleguide` exists to do.

## See also

- `.agentheim/contexts/design-system/todo/design-system-001-styleguide.md`
- `.agentheim/contexts/infrastructure/todo/infrastructure-mam0r-failure-staleness-backoff-policy.md`
- `mc-design-system-v1-source.dc.html` (raw exported source, same directory)
