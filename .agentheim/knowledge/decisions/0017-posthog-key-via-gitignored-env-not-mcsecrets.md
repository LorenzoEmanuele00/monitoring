---
id: 0017
title: PostHog Project API Key is stored via a gitignored build-time .env, not MCSecrets/Keychain — amends ADR-0010's storage clause
scope: global
status: accepted
date: 2026-08-23
supersedes: []
superseded_by: []
related_tasks: [infrastructure-pht7k]
related_research: []
---

# ADR 0017: PostHog Project API Key is stored via a gitignored build-time `.env`, not MCSecrets/Keychain — amends ADR-0010's storage clause

## Context

ADR-0010 says: "The PostHog project API key is a single app-level credential stored via
`MCSecrets` (ADR-0007's `SecretStore`), not per-Integration." Wiring the real PostHog SDK
(`infrastructure-pht7k`) is where that clause actually has to be implemented, and doing so
surfaced that `MCSecrets`/Keychain is the wrong mechanism for this specific value — a
builder-approved override discussed and decided 2026-08-23, recorded here per this repo's
precedent for a partial-override ADR (`0015-staleness-thresholds-15-60-minutes.md`: title says
"overriding ADR-0008's placeholder", `supersedes`/`superseded_by` stay `[]` on both sides — one
clause changes, the rest of the parent ADR is untouched).

Two things distinguish the PostHog Project API Key from every other credential ADR-0007
governs:

1. **Trust category.** Every `SecretStore` credential ADR-0007/ADR-0012 were designed around —
   a GitHub PAT, a Firebase service-account key, a Supabase PAT — is a *read/write* credential
   scoped to one `ServiceIntegration` entity, validated against the provider before storage
   (`ProviderAdapter.validateCredential(_:)`), and capable of real damage if it leaked (an
   attacker could act as the integration). PostHog's Project API Key is, by PostHog's own
   design, a **write-only client-side ingestion token**: it can only submit events to one
   project, cannot read anything back, and is routinely shipped inside client binaries
   (PostHog explicitly documents embedding it in mobile/web app bundles). Its worst-case
   exposure is unwanted junk events in the PostHog project, not the loss-of-control ADR-0007's
   threat model was built for.
2. **Cardinality and lifecycle.** `SecretStore` is keyed by `Integration` UUID because
   ADR-0007/ADR-0012's whole shape assumes N per-Integration credentials that come and go as
   Integrations are connected/disconnected through the in-app Connect Integration flow, each
   validated live against its provider before being trusted. The PostHog key is exactly one
   static, app-wide value, known before the app is ever built, with no in-app provisioning flow
   and no validation call — it doesn't fit the entity-scoped shape `SecretStore` exists to
   serve, and forcing it in would mean inventing a fake "Integration" or a special-cased
   singleton key just to reuse a mechanism designed for a different problem.

A gitignored `MissionControl/.env` (`POSTHOG_API_KEY`, `POSTHOG_HOST`) plus a `project.yml`
`postBuildScripts` entry that sources it and writes both values into the *built* Info.plist via
`PlistBuddy` (read back at runtime via `Bundle.main.object(forInfoDictionaryKey:)`) is this
repo's first build-time-secret-injection pattern — future static, app-wide, non-`Integration`
config values (if any arise) should reach for the same convention rather than re-litigating it.

## Decision

The PostHog Project API Key and ingestion host are **not** stored via `MCSecrets`/Keychain.
They live in a gitignored `MissionControl/.env` file the builder populates locally
(`POSTHOG_API_KEY=phc_...`, `POSTHOG_HOST=https://us.i.posthog.com` or the EU equivalent), which
a `project.yml`-defined `postBuildScripts` build phase reads at build time and injects into the
*built* app bundle's `Info.plist` only — never into `Generated/MissionControl-Info.plist` or
`project.yml` themselves, both of which stay committed and free of the actual values.
`AnalyticsEventLoggerFactory` (`MissionControl/PostHogAnalyticsEventLogger.swift`) reads the two
keys back via `Bundle.main.object(forInfoDictionaryKey:)` at runtime; if either is missing or
blank (`.env` absent — CI, or before the builder has populated it — or malformed), it falls back
to `NoOpAnalyticsEventLogger` with a logged warning rather than crashing.

This amends only ADR-0010's storage-mechanism sentence for this one credential. Every other
ADR-0010 decision (the narrow structured-event set, `os.Logger` everywhere including the widget
extension, PostHog linked only in the main app target, the redaction requirement) is untouched.
`MCSecrets`/`SecretStore`/Keychain (ADR-0007) remain exactly as specified for the four
Service Integration provider credentials (ADR-0012) — this ADR does not reopen that.

## Consequences

### Positive
- The mechanism actually matches the credential's trust category and lifecycle instead of
  forcing an entity-scoped store to hold a single static app-wide value.
- No Keychain prompt / access-group plumbing needed for a value that was never meant to be
  read/write-protected the way a provider PAT is.
- Establishes a reusable convention (`.env` + `postBuildScripts` + `PlistBuddy` + Info.plist
  read-back) for any future static, non-per-Integration config value, rather than inventing one
  ad hoc if/when another such value shows up.
- `.gitignore`-based exclusion is simple to audit — anyone can `git log -p .env` and see it was
  never committed, no history to scrub.

### Negative
- A credential the app depends on now lives outside `MCSecrets`, so "how are secrets stored in
  this app" is no longer a single, uniform answer — a future reader has to know this one
  exception exists and why.
- `.env` is a manual, per-machine setup step with no in-app UI (unlike the Connect Integration
  flow's paste-and-validate for provider credentials) — a fresh checkout's PostHog events are
  silently no-op'd until the builder remembers to create it. Mitigated by the factory's logged
  warning and by this being exactly the pre-existing spike behavior (`NoOpAnalyticsEventLogger`),
  not a regression.
- The build-time injection script is new machinery (`postBuildScripts`, `PlistBuddy`) with no
  prior precedent in this codebase to lean on if it needs debugging.

### Neutral
- Rotating the key is a local `.env` edit + rebuild, not a Keychain operation — operationally
  simpler for a value with no revocation/rotation workflow of its own beyond "create a new
  Project API Key in PostHog and swap it in."

## Alternatives considered
- **Store it in `MCSecrets`/Keychain as ADR-0010 originally specified** — rejected per the
  trust-category and cardinality mismatch above: `SecretStore` has no notion of a single
  app-wide (non-Integration) secret, and the Connect Integration flow's validate-then-store
  pattern has nothing to validate against for a write-only ingestion token.
- **Hardcode the key directly in source** — rejected outright: even though the key's worst-case
  exposure is low, committing it to git history is unnecessary and trivially avoidable, and it
  would defeat per-machine/per-environment overrides (e.g. a future staging PostHog project).
- **An `xcconfig` file instead of `.env` + buildScript** — a reasonable alternative (also
  gitignorable, also read at build time), but `.env` was chosen because it's the convention the
  builder already uses across their other personal systems (mise_pwa, mise_web) sharing this
  same PostHog project, keeping the local setup step identical across projects.

## References
- `.agentheim/knowledge/decisions/0010-unified-logging-plus-posthog-for-structured-events.md` —
  the storage clause this amends.
- `.agentheim/knowledge/decisions/0007-keychain-secret-storage-shared-access-group.md` — the
  mechanism this deliberately does not reuse for this credential.
- `.agentheim/knowledge/decisions/0015-staleness-thresholds-15-60-minutes.md` — the precedent
  followed for how a partial-override ADR is written and frontmatter'd.
- `MissionControl/project.yml` — the `postBuildScripts` entry implementing the injection.
- `MissionControl/PostHogAnalyticsEventLogger.swift` — `AnalyticsEventLoggerFactory`, the
  runtime read-back + graceful-fallback logic.
