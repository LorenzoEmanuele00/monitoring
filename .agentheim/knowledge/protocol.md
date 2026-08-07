# Protocol

Chronological log of everything that happens in this project.
Newest entries on top.

---

## 2026-08-07 20:45 -- Brainstorm: macOS personal cockpit dashboard

**Type:** Brainstorm
**Outcome:** vision created
**BCs identified:** project-registry, service-integrations, widgets, notifications, infrastructure, design-system
**Summary:** Socratic session established a permanent single-user macOS "cockpit" app: registers Projects from the Obsidian vault's `Progetti` folder, attaches Service Integrations (GitHub, Firebase Hosting, Supabase, Vercel, ...) per Project, and renders their status as configurable Widgets — critically including native macOS desktop widgets (WidgetKit) that work with the app closed. Observe-first with narrow Quick Actions, never a replacement for vendor dashboards. Walking-skeleton scope: onboard the real project mise_pwa end-to-end (GitHub + Firebase Hosting + Supabase, one working desktop widget). Architecture foundation pass (architect via orchestrator) recommended a native Swift/SwiftUI app + WidgetKit extension sharing an App Group and Swift package, two-tier persistence (GRDB/SQLite + JSON snapshots), Keychain credential storage, resident-app polling (webhooks/helper daemon deferred), no backend, unified logging only, sandboxed with security-scoped bookmarks for vault access, and a last-good-data-wins failure policy. User confirmed a paid Apple Developer Program membership will be used strictly for local, unsigned-for-distribution builds (no App Store submission).
**ADRs written:** 0001 (permanent single-user scope), 0002 (observe-first, not a control plane), 0003 (native desktop widgets are core)
**Foundation tasks emitted:** infrastructure-x23a8, infrastructure-fskyk, infrastructure-hv013, infrastructure-zznqh, infrastructure-wv33x, infrastructure-rxd87, infrastructure-pcmqh, infrastructure-mam0r (decision tasks, infrastructure), service-integrations-n7s2k (decision task, service-integrations), infrastructure-001-walking-skeleton (spike), design-system-001-styleguide (feature, styleguide gate)

---
