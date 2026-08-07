# Vision: Mission Control (working title)

## Purpose
A personal, macOS-native command center that gives Lorenzo a single point of glanceable
visibility and light control over every project he builds — its documentation (Obsidian), its
source, and the external services it depends on (GitHub, hosting, database/auth, etc.) —
surfaced both inside an app and as native desktop widgets that keep working even when the app
itself is closed. Built to stay useful as the number of active projects grows without bound.

## Users
Solo actor: Lorenzo, permanently the only user. No team, multi-tenant, or shared-account
scenario is in scope, now or later.

## The problem
Today, knowing "what's going on" with any given project means separately checking Obsidian
notes, the GitHub repo, and each service's own dashboard (Vercel, Supabase, Firebase, etc.) — a
chronic, growing tax as the number of active projects increases. There is no single place that
answers "here's the state of everything I'm running" at a glance, and no way to see that state
without deliberately opening several different tools.

## What success looks like
- A Project can be registered from the `Progetti` folder of the Obsidian vault, optionally
  linked to a local source-code folder on disk.
- One or more Service Integrations (GitHub, Firebase Hosting, Supabase, Vercel, ...) can be
  attached to a Project.
- Widgets rendering Project/Integration data are configurable from the app, and at least a
  subset can be placed as native macOS desktop widgets that remain useful when the app is closed.
- mise_pwa (Gestione Mezzi) is onboarded end-to-end: its GitHub repo, Firebase Hosting, and
  Supabase integrations each surface through a widget — this is the walking skeleton, not the
  finish line.
- Notifications fire for meaningful events (deploy started/ended, PR opened/closed, a PR into
  master implying an upcoming production deploy) via macOS Notification Center.
- Registering a second, third, Nth project follows the same flow with no new code per project —
  the architecture is genuinely reusable, not mise_pwa-specific.

## Non-goals
- Not a multi-user or team product — permanently single-user, single-Mac.
- Not a replacement for any vendor's own dashboard (GitHub, Vercel, Supabase, Firebase, ...) —
  it links out to them for anything beyond a quick glance or a small Quick Action.
- Not an operations console: no SSH/terminal-style server management, no PR merging, no full
  CI/CD control from inside the app. Quick Actions stay narrow (e.g., re-run a failed GitHub
  Action, jump to a deploy) — big operations always happen on the vendor's own platform.
- Not a CLI tool.
- Not scoped to any fixed number of projects — must not hardcode assumptions that only hold for
  one project (mise_pwa) or a small fixed set.

## Ubiquitous language (seed)
- **Project** — a unit of work registered in the app, rooted in a note/folder inside the
  Obsidian vault's `Progetti` folder; optionally linked to a local source-code folder on disk;
  owns a set of attached Service Integrations.
- **Vault** — the user's Obsidian vault on this Mac; `Progetti` is the folder within it where
  Projects are documented.
- **Service Integration** — a typed connection from a Project to an external platform (GitHub,
  Firebase Hosting, Supabase, Vercel, ...) that exposes status, usage metrics, and events
  through that platform's API.
- **Widget** — a configurable, glanceable view of a Project or Service Integration's data;
  rendered either inside the app's own dashboard or as a native macOS desktop widget.
- **Desktop Widget** — a Widget instance placed on the macOS desktop / Notification Center via
  WidgetKit, visible and refreshing even when the app itself is not open.
- **Quick Action** — a narrow, one-click operation triggered from a Widget against a Service
  Integration (e.g., re-run a GitHub Action, restart a broken deploy) — deliberately not a
  replacement for the vendor's own console.
- **Event** — a notable happening on a Service Integration (PR opened/closed, deploy
  started/ended, a usage threshold approaching) that can drive a Notification.
- **Notification** — a macOS Notification Center alert raised in response to an Event.

## Open questions
- Which Service Integration providers beyond GitHub, Firebase Hosting, Supabase, and Vercel are
  actually needed, and how many will a typical Project realistically attach? (open since
  2026-08-07)
- What credential storage / auth flow will each provider integration use (personal access
  tokens vs OAuth), and where are secrets kept? (open since 2026-08-07)
- How does the app detect new/changed Projects in the Obsidian vault — a one-time import, a
  watched folder, or manual "add project" only? (open since 2026-08-07)
- What's the refresh/polling cadence for each integration, given WidgetKit's OS-managed
  timeline budget versus the desire for near-real-time notifications? (open since 2026-08-07)
