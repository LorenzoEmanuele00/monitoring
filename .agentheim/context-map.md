# Context map

## Contexts

### Project Registry
- **Purpose:** register Projects sourced from the Obsidian vault's `Progetti` folder (and an
  optional local source path), and own which Service Integrations are attached to each Project.
- **Core language:** Project, Vault Note, Progetti Folder, Source Path, Integration Binding.
- **Classification:** core — this is the aggregate root the rest of the product organizes
  around.
- **Key actors:** the user (registering and configuring Projects).

### Service Integrations
- **Purpose:** connect to each external platform's API (GitHub, Firebase Hosting, Supabase,
  Vercel, ...), normalize its status/usage/event data behind one shape, and expose narrow
  Quick Actions.
- **Core language:** Integration, Provider, Credential, Usage Metric, Event, Quick Action.
- **Classification:** core — most of the product's differentiated complexity and value live
  here (pluggable provider adapters that must keep working as new providers are added).
- **Key actors:** none directly human; consumed by Widgets and Notifications.

### Widgets
- **Purpose:** render configurable views of Project and Integration data, both inside the app's
  dashboard and as native macOS desktop widgets that keep working when the app is closed.
- **Core language:** Widget, Widget Kind, Widget Configuration, Desktop Widget, In-App Panel.
- **Classification:** core — native desktop widgets are the product's key differentiator, not a
  delivery detail.
- **Key actors:** the user (arranging and configuring widgets).

### Notifications
- **Purpose:** watch Events raised by Service Integrations and Projects, decide what's worth
  surfacing, and push macOS Notification Center alerts.
- **Core language:** Notification Rule, Event Trigger, Alert.
- **Classification:** supporting — enhances the core experience but isn't the reason the
  product exists.
- **Key actors:** the user (recipient).

### Infrastructure
- **Purpose:** globally-true technical concerns shared across every other context — app
  runtime/platform choice, secrets/credential storage, background scheduling/polling, shared
  persistence, and the WidgetKit extension scaffolding shared by all widget kinds.
- **Core language:** generic ops vocabulary (secret, credential store, scheduler, persistence).
- **Classification:** generic.
- **Key actors:** none directly; every other BC depends on it.

### Design System
- **Purpose:** the macOS app's and widgets' shared visual language — tokens, components,
  layout patterns — reviewed once before any BC builds its own frontend.
- **Core language:** token, component, style, review gate.
- **Classification:** supporting.
- **Key actors:** the user (sole reviewer/approver of the styleguide).

## Relationships
- **Widgets** is downstream (customer) of **Project Registry** and **Service Integrations**
  (open host / published language): it reads Project and Integration data but never writes it.
- **Notifications** is downstream (customer) of **Service Integrations** (subscribes to Events)
  and **Project Registry** (needs to know which Project an Event belongs to).
- **Project Registry** is a customer of **Service Integrations**: a Project's "attached
  integrations" reference Integration types/identities owned by Service Integrations, but
  Project Registry never reaches into Integration internals.
- **Infrastructure** is upstream (open host) of every other context: persistence, secrets, and
  scheduling are consumed, not re-implemented, by Project Registry, Service Integrations,
  Widgets, and Notifications.
- **Design System** is upstream (open host / published language) of every frontend-bearing
  context (Project Registry's in-app UI, Widgets): both conform to its tokens/components rather
  than styling independently.
