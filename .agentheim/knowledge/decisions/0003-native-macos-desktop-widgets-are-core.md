---
id: 0003
title: Native macOS desktop widgets are a core product requirement
scope: global
status: accepted
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: []
related_research: []
---

# ADR 0003: Native macOS desktop widgets are a core product requirement

## Context
"Widget" was initially ambiguous between an in-app dashboard card and a literal macOS
system widget (WidgetKit) placed on the desktop or in Notification Center. This distinction
is architecturally significant: an in-app-only dashboard could plausibly be built as a web app,
while genuine desktop widgets that render without the app open require a native macOS app with
a widget extension. The user confirmed the requirement is the latter: a brief view available
even when the app itself is closed.

## Decision
Native macOS desktop widgets (rendering via the OS's own widget mechanism, visible without the
main app open) are a hard, core requirement of this product — not a stretch goal or a delivery
detail. This directly drives the Widgets bounded context's classification as core, and
constrains the technology foundation to a stack capable of shipping a real macOS widget
extension (finalized by the architecture foundation pass, not by this ADR).

## Consequences
### Positive
- Forces an early, honest platform decision (native macOS app) rather than drifting toward a
  web app that later can't deliver the promised "glance without opening anything" experience.
- Widgets becomes a clearly core bounded context with a concrete, testable success criterion:
  a desktop widget must render and refresh with the app closed.

### Negative
- Rules out pure web/PWA approaches for the primary delivery surface, even though some
  Service Integrations (Vercel, Supabase, Firebase) are themselves web-native — those must be
  reached via their APIs from a native app/background process, not by embedding their web UIs.
- OS-managed widget refresh budgets (WidgetKit timelines) constrain how "live" desktop widgets
  can be, which interacts with the near-real-time notification goal — tracked as an open
  question until the architecture foundation pass resolves it.

### Neutral
- The in-app dashboard and the desktop widgets share the same underlying Widget Kind concept
  (per `contexts/widgets/README.md`) — this ADR doesn't mandate two separate implementations,
  only that at least the desktop delivery path must genuinely work standalone.

## Alternatives considered
- **In-app-only dashboard (web or native), no OS widgets** — rejected: doesn't meet the
  explicit "brief view even when the app isn't opened" requirement.
- **Notification-only glances (no persistent widget)** — rejected: notifications communicate
  events, not standing at-a-glance state; the user asked for both.

## References
- `.agentheim/vision.md` — Ubiquitous language (Desktop Widget), What success looks like.
- `.agentheim/contexts/widgets/README.md`.
