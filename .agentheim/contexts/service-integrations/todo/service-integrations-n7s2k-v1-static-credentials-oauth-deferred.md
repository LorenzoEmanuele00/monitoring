---
id: service-integrations-n7s2k
title: v1 uses manually-provisioned long-lived provider credentials; OAuth is deferred per provider
status: todo
type: decision
context: service-integrations
created: 2026-08-07
completed:
depends_on: [infrastructure-hv013]
blocks: []
tags: [captured, architecture-foundation]
related_adrs: []
related_research: []
prior_art: []
---

## Why

The walking skeleton needs GitHub, Firebase Hosting, and Supabase working end to end for
mise_pwa. Each provider offers OAuth and a long-lived token; OAuth exists mainly to manage
consent for many users and revoke per-user access — neither applies under ADR-0001, where
there's exactly one permanent user who owns every account involved.

## What

Every Provider authenticates with a long-lived credential provisioned by hand in the provider's
own console: a GitHub fine-grained PAT (repo-scoped, read-only until a write Quick Action
ships), a Firebase service-account key (Hosting viewer role), and a Supabase Management API PAT
(explicitly not the `service_role` key — too high-privilege for observe-first per ADR-0002).
Modeled as a `CredentialKind` enum so a future single-provider OAuth path doesn't reshape the
Integration aggregate. Every adapter validates its credential on connect and each poll, raising
**Integration credential expired** on auth failure — silent auth failure is a defect.

Full ADR draft is in Notes below.

## Acceptance criteria

- [ ] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: service-integrations`, matching the draft in Notes (or a user-amended version,
      amendments noted in the commit).
- [ ] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07. The architect flagged that Supabase's Management API alone may or may not carry
enough for a genuinely useful usage widget — a short research spike may be warranted before this
lands in code, to confirm before committing to "no `service_role` in v1."

```markdown
---
id: TBD
title: v1 uses manually-provisioned long-lived provider credentials; OAuth is deferred per provider
scope: service-integrations
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [service-integrations-n7s2k]
related_research: []
---

# ADR TBD: v1 uses manually-provisioned long-lived provider credentials; OAuth is deferred per provider

## Context
The walking skeleton needs GitHub, Firebase Hosting and Supabase working end to end for one
project (mise_pwa). Each provider offers both an OAuth-style flow and a long-lived token, and
their token models differ substantially. OAuth exists primarily to avoid shipping client secrets
to many users and to obtain scoped, revocable, per-user consent — none of which has value under
ADR-0001, where there is exactly one permanent user on one Mac who owns every account involved.

## Decision
For v1, every Provider authenticates with a long-lived credential the user provisions by hand in
the provider's own console and pastes into a "Connect integration" sheet. No OAuth flow ships in
v1.

- **GitHub** — a fine-grained personal access token scoped to the specific repositories, with
  read on Contents, Metadata, Pull requests and Actions; Actions *write* only if and when the
  "re-run workflow" Quick Action ships (ADR-0002 keeps this list short).
- **Firebase Hosting** — a Google Cloud service account JSON key with a Firebase Hosting viewer
  role on the project. The adapter performs the JWT-bearer → OAuth2 access token exchange and
  caches the short-lived access token in memory only.
- **Supabase** — a Management API personal access token (`api.supabase.com`). The
  `service_role` key is explicitly out of scope for v1: it is far higher privilege than
  observe-first needs (ADR-0002).
- **Vercel** — an account personal access token, when that provider is implemented.

Credentials are modelled as a `CredentialKind` enum — `.staticToken`, `.serviceAccountKey`,
`.oauthRefreshToken` — so that adding an OAuth path for a single provider later does not reshape
the Integration aggregate or the storage layer. Storage is the infrastructure `SecretStore`
(opaque blob keyed by Integration UUID); interpretation is per-adapter.

Every adapter implements a `validateCredential()` check run on connect and on each poll cycle. A
401/403, or a token past its known expiry, raises the existing **Integration credential expired**
event, which Notifications surfaces as an alert. Silent auth failure is a defect.

## Consequences
### Positive
- The walking skeleton's auth work collapses from three OAuth integrations to three paste-a-token
  forms — days of work removed from the critical path.
- No client secrets to embed, no redirect URI handling, no consent screens to register.
- Token scopes are narrow and set by hand, keeping privilege minimal per ADR-0002.

### Negative
- Manual rotation: GitHub fine-grained PATs expire (max one year) and must be re-pasted. Without
  the expiry-detection path above, widgets would quietly go stale — so that path is mandatory,
  not optional.
- Onboarding a new Project means visiting up to three provider consoles by hand. Acceptable at
  personal scale; it is the main thing an OAuth flow would later buy back.

### Neutral
- OAuth remains available per-provider behind `CredentialKind.oauthRefreshToken` (loopback
  redirect + `ASWebAuthenticationSession`). Adding it for one provider does not require adding it
  for all.
- Rate limits attach to the credential, so all Integrations sharing one GitHub PAT share one
  budget — see the error-handling and rate-limit ADR.

## Alternatives considered
- **GitHub OAuth App / GitHub App from day one** — rejected: no distribution and no third-party
  consent to manage; pure cost for the walking skeleton. Reconsider only if PAT rotation becomes
  genuinely annoying in practice.
- **Google user-OAuth (installed app flow) for Firebase instead of a service account** —
  rejected: requires registering an OAuth client and handling a consent screen, to obtain
  strictly less stable credentials than a service account key for a project the user owns.
- **Supabase `service_role` key for richer metrics** — rejected for v1: full database and auth
  admin privilege for glanceable read-only data contradicts ADR-0002's minimal-privilege posture.
  Revisit only with a specific metric that the Management API genuinely cannot provide.

## References
- `.agentheim/knowledge/decisions/0001-permanent-single-user-personal-tool.md`
- `.agentheim/knowledge/decisions/0002-observe-first-cockpit-not-a-control-plane.md`
- `.agentheim/contexts/service-integrations/README.md`
```
