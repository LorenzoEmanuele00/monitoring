# Service Integrations

## Purpose
Connects to each external platform's API (GitHub, Firebase Hosting, Supabase, Vercel, and
future providers), normalizes its status/usage/event data behind one shape, and exposes narrow
Quick Actions. This is where the product's provider-specific complexity is isolated so it
doesn't leak into Widgets, Notifications, or Project Registry.

## Classification
core — most of the product's differentiated complexity and value live here: pluggable provider
adapters that must keep working as new providers are added without rearchitecting the rest of
the app.

## Actors
None directly human. Consumed by Widgets (for display) and Notifications (for Events). The
user interacts with it indirectly, via Widgets and Quick Actions.

## Ubiquitous language
- **Integration** — a live, configured connection from a Project to one Provider.
- **Provider** — a supported external platform type (GitHub, Firebase Hosting, Supabase,
  Vercel, ...). Adding a Provider should not require changes outside this context.
- **Credential** — the auth material (token/OAuth grant) an Integration needs to call its
  Provider's API.
- **Usage Metric** — a quantitative reading from a Provider (e.g. Vercel bandwidth against a
  free-plan limit, Supabase usage).
- **Event** — a notable happening reported by a Provider (PR opened/closed, deploy
  started/ended, a usage threshold approaching).
- **Quick Action** — a narrow, one-click operation this context can perform against a Provider
  on the user's behalf (e.g. re-run a GitHub Action, restart a broken deploy) — never a
  replacement for the Provider's own console.

## Aggregates
- **Integration** — protects the invariant that an Integration always has exactly one Provider
  type, valid Credentials, and a normalized status shape regardless of which Provider it wraps.

## Key events
- **Integration connected** / **Integration credential expired**
- **Usage threshold approached**
- **Provider event received** (PR opened, PR closed, deploy started, deploy ended)

## Key commands
- **Connect integration** (attach Credentials for a Provider)
- **Refresh integration status**
- **Run quick action**

## Relationships with other contexts
- **Upstream (open host) of Widgets and Notifications:** both consume this context's
  normalized Integration/Event data without knowing provider-specific details.
- **Supplier to Project Registry:** Project Registry's Integration Bindings reference this
  context's Integration identities.
- **Conformist to each external platform's API:** this context absorbs each Provider's own
  data shape and rate limits behind its own published language.
- See `context-map.md` for the full picture.

## Open questions
- Which Providers beyond GitHub, Firebase Hosting, Supabase, and Vercel are actually needed?
- What credential storage / auth flow will each Provider integration use (PAT vs OAuth), and
  where are secrets kept? (Likely an Infrastructure-context decision — see that BC's README.)
- What refresh/polling cadence balances WidgetKit's OS-managed timeline budget against
  near-real-time notification needs?
