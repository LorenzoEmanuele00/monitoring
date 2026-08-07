# Notifications

## Purpose
Watches Events raised by Service Integrations (and state changes in Project Registry), decides
what's worth surfacing, and pushes macOS Notification Center alerts. This is the context that
owns "what interrupts the user versus what just sits in a widget."

## Classification
supporting — enhances the core experience (you don't have to go looking) but isn't the reason
the product exists; the dashboard and widgets remain useful with notifications entirely off.

## Actors
The user, as the sole recipient of Notifications.

## Ubiquitous language
- **Notification Rule** — a standing decision about which Events for which Project/Integration
  should raise a Notification (e.g. "notify on deploy started/ended", "notify on PR opened
  against master").
- **Event Trigger** — the specific Event instance from Service Integrations that a Notification
  Rule matched against.
- **Alert** — the actual macOS Notification Center notification raised as a result.

## Aggregates
- **Notification Rule** — protects the invariant that a Rule always references a real
  Project/Integration/Event type combination and doesn't fire duplicate Alerts for the same
  Event Trigger.

## Key events
- **Alert raised**
- **Notification rule enabled/disabled**

## Key commands
- **Configure notification rule**
- **Raise alert** (internal, triggered by a matching Event from Service Integrations)

## Relationships with other contexts
- **Customer of Service Integrations:** subscribes to its Events.
- **Customer of Project Registry:** resolves which Project an Event belongs to, for Alert
  content.
- See `context-map.md` for the full picture.

## Open questions
- Do Notification Rules need per-Project overrides from day one, or is a single global rule set
  (e.g. "always notify on deploy start/end and PR-to-master") enough for v1?
