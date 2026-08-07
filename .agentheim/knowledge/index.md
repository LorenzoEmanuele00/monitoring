# Index

Top-level catalog of this project's bounded contexts, global decisions, and research.
For BC-scoped artifacts, see each BC's `INDEX.md`.

> Updated by: `modeling` (BC creation), `work` (global ADRs), `research` (reports tagged global / cross-BC), backfill script.
> Hand-edits are fine but the skills will append at the section markers below.

---

## Bounded contexts

<!-- bc-list:start -->
- **design-system** — the macOS app's and widgets' shared visual language, tokens, components, and the review gate before any BC builds frontend — `contexts/design-system/INDEX.md`
- **infrastructure** — globally-true tech concerns: runtime/platform, secrets, scheduling, shared persistence, WidgetKit scaffolding — `contexts/infrastructure/INDEX.md`
- **notifications** — watches Events from Service Integrations and Project Registry, raises macOS Notification Center alerts — `contexts/notifications/INDEX.md`
- **widgets** — configurable views of Project/Integration data, in-app and as native macOS desktop widgets — `contexts/widgets/INDEX.md`
- **service-integrations** — connects to GitHub, Firebase Hosting, Supabase, Vercel and future providers; normalizes status/usage/events — `contexts/service-integrations/INDEX.md`
- **project-registry** — registers Projects from the Obsidian vault's `Progetti` folder and owns their attached Service Integrations — `contexts/project-registry/INDEX.md`
<!-- bc-list:end -->

## Global ADRs (scope: global)

<!-- adr-global:start -->
- **0003** — Native macOS desktop widgets are a core product requirement — 2026-08-07 — `knowledge/decisions/0003-native-macos-desktop-widgets-are-core.md`
- **0002** — Observe-first cockpit with narrow quick actions, not a control plane — 2026-08-07 — `knowledge/decisions/0002-observe-first-cockpit-not-a-control-plane.md`
- **0001** — Permanent single-user, personal-tool scope — 2026-08-07 — `knowledge/decisions/0001-permanent-single-user-personal-tool.md`
<!-- adr-global:end -->

## Cross-BC research

Research reports relevant to more than one BC (or to the project as a whole). BC-specific
reports are listed in each BC's `INDEX.md`.

<!-- research-global:start -->
<!-- research-global:end -->

## Pointers

- Vision: `vision.md`
- Context map: `context-map.md`
- Protocol (chronological log): `knowledge/protocol.md` — newest entries on top
- All ADRs: `knowledge/decisions/`
- All research: `knowledge/research/`
