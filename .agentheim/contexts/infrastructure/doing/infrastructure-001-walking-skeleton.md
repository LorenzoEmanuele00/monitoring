---
id: infrastructure-001-walking-skeleton
title: Walking skeleton — onboard mise_pwa end-to-end through the full stack
status: doing
type: spike
context: infrastructure
created: 2026-08-07
completed:
depends_on: [infrastructure-x23a8, infrastructure-fskyk, infrastructure-hv013, infrastructure-zznqh, infrastructure-wv33x, infrastructure-rxd87, infrastructure-pcmqh, infrastructure-mam0r, service-integrations-n7s2k]
blocks: []
tags: [captured, architecture-foundation, walking-skeleton]
related_adrs: []
related_research: []
prior_art: []
---

## Why

The vision's shape of success is a single reusable pipeline — register a Project, attach
Service Integrations, get working Widgets — proven once on a real project before any second
project is onboarded. Without a thin end-to-end slice, `modeling`/`work` risk making foundation
calls piecemeal under feature pressure. This spike is the project's first prototype.

## What

Feature-thin, architecture-thick: prove the whole stack runs, not that any feature is complete.

1. **Gate: paid Apple Developer Program membership active** (confirmed available; enrollment,
   if not already done, is literally step one — see Notes).
2. Xcode project scaffolded per `infrastructure-x23a8`: `MissionControl.app` +
   `MissionControlWidgets.appex` + `MissionControlKit` package, App Group entitled on both
   targets.
3. Tier A (GRDB/SQLite) and Tier B (JSON snapshot files) wired per `infrastructure-fskyk`,
   inside the App Group container.
4. `SecretStore` (Keychain, shared access group) wired per `infrastructure-hv013`.
5. Register **one real Project**: mise_pwa, rooted at `Progetti/Gestione Mezzi` in the Obsidian
   vault, source path pointed at its local folder on this Mac (manual "add project" flow is
   enough for this spike — Project Registry's discovery-mode open question stays open).
6. Attach mise_pwa's three real Service Integrations, each authenticated per
   `service-integrations-n7s2k` (GitHub fine-grained PAT for
   `github.com/LorenzoEmanuele00/mise_pwa`, Firebase service-account key, Supabase Management
   API PAT).
7. Resident menu-bar app polls all three per `infrastructure-zznqh`'s baseline cadence, applying
   the failure/staleness policy from `infrastructure-mam0r` (last-good-wins, visible staleness,
   backoff on transient failures).
8. At least one Desktop Widget (WidgetKit) renders live data for at least one of the three
   integrations, visible on the desktop with the main app closed, refreshing via
   `WidgetCenter.reloadTimelines` when the resident app polls.
9. Unified logging wired per `infrastructure-rxd87` for the poll pipeline.

## Acceptance criteria

- [ ] The app boots, the widget extension is discoverable in the macOS widget gallery, and a
      Desktop Widget for mise_pwa can be added to the desktop.
- [ ] mise_pwa is registered as a Project with all three Integrations (GitHub, Firebase Hosting,
      Supabase) attached and authenticated.
- [ ] With the main app closed, the placed Desktop Widget still renders the last-polled data
      (not empty, not a crash) — proves the App Group + Tier B snapshot path works standalone.
- [ ] With the main app running, a real change on at least one provider (e.g. a new commit's
      Actions run, or a manual poll trigger) results in the widget's displayed data updating
      within one baseline poll interval.
- [ ] Killing network access mid-poll does not corrupt the widget's last-good data — it keeps
      showing the last successful snapshot with a visibly stale indicator.
- [ ] `git log` shows this spike's changes scoped to the app/package/extension targets only —
      no unrelated BC work folded in.

## Notes

**Stop-loss (ADR-0065):** if, mid-spike, the mitigation for a blocker is already known and
cheap, record it and stop — don't use the spike to gold-plate a fix. This is a prove-the-plumbing
exercise, not a place to perfect provider adapters, UI polish, or notification rules.

**First concrete step, before any code:** confirm the paid Apple Developer Program membership
is active on the account this will be signed with (per the user: paid enrollment is fine, no
App Store submission or review needed — local builds signed with a real Team ID work for
App Groups and Keychain Access Groups without ever leaving this Mac).

**Deliberately out of scope for this spike** (belongs to later feature tasks in the owning BC):
Notification Rules UI, more than one Widget Kind, more than one Project, OAuth for any provider,
the deferred background-helper/webhook mechanisms named in `infrastructure-zznqh`.
