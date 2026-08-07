# Infrastructure

## Purpose
Owns globally-true technical concerns that every other context depends on: app
runtime/platform choice, secrets/credential storage, background scheduling and polling, shared
persistence, and the WidgetKit extension scaffolding shared by all Widget Kinds. A decision
lands here only if it would still need to be made even if any single domain BC didn't exist —
BC-local infra (a provider-specific adapter quirk, a widget-kind-specific cache) stays inside
the BC that owns it.

## Classification
generic — necessary and shared, but not where the product's differentiated value lives.

## Actors
None directly; every other bounded context depends on what's decided and built here.

## Ubiquitous language
Generic ops vocabulary — secret, credential store, scheduler, persistence, background refresh,
widget extension. Not yet project-specific; expect this to stay thin.

## Aggregates
None yet — this BC currently holds cross-cutting decisions, not domain aggregates.

## Key events
None yet.

## Key commands
None yet.

## Relationships with other contexts
- **Upstream (open host) of every other context:** Project Registry, Service Integrations,
  Widgets, and Notifications all consume persistence, secrets, and scheduling from here rather
  than re-implementing their own.
- See `context-map.md` for the full picture.

## Open questions
- Final stack choice (native Swift/SwiftUI + WidgetKit vs. an alternative), local persistence
  approach, and credential storage mechanism — tracked as `type: decision` tasks in this BC's
  `todo/`, pending the architecture foundation pass.
