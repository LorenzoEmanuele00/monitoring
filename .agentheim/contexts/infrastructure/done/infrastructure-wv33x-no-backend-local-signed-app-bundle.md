---
id: infrastructure-wv33x
title: No backend — the only deployable artifact is a locally-built signed macOS app bundle
status: done
type: decision
context: infrastructure
created: 2026-08-07
completed: 2026-08-13
depends_on: [infrastructure-zznqh]
blocks: []
tags: [captured, architecture-foundation]
related_adrs: [0011]
related_research: []
prior_art: []
---

## Why

Worth stating explicitly and early whether this system has a server-side component. Under
ADR-0001 there's one permanent user on one Mac; persistence is local; every provider API is
reachable via outbound HTTPS from that Mac. The only force that would require a server is
inbound traffic (provider webhooks) — and the refresh decision (`infrastructure-zznqh`) defers
those.

## What

No backend, no cloud resources, no deployment pipeline. The single deployable artifact is
`MissionControl.app` (containing the widget extension), built locally in Xcode, signed with the
user's paid Developer ID, run directly on this Mac — no App Store, no notarization needed for
purely local use. If the deferred webhook relay is ever built, it's explicitly a *named second
deploy target* with its own hosting/ADR, not something assumed into this one.

Full ADR draft is in Notes below.

## Acceptance criteria

- [x] ADR committed to `.agentheim/knowledge/decisions/` with the next real sequential number,
      `scope: global`, matching the draft in Notes (or a user-amended version, amendments noted
      in the commit) — committed as ADR-0011, as drafted (with a note added clarifying PostHog,
      per ADR-0010, doesn't count as a backend under this decision).
- [x] No code change required for this task itself.

## Notes

Produced by the architecture foundation pass (architect specialist via orchestrator),
2026-08-07.

```markdown
---
id: TBD
title: No backend — the only deployable artifact is a locally-built signed macOS app bundle
scope: global
status: proposed
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: [infrastructure-wv33x]
related_research: []
---

# ADR TBD: No backend — the only deployable artifact is a locally-built signed macOS app bundle

## Context
It is worth stating explicitly, and early, whether this system has a server-side component. Under
ADR-0001 there is one permanent user on one Mac; all persistence is local; every provider API
(GitHub, Firebase Hosting, Supabase, Vercel) is reachable with an outbound HTTPS call from that
Mac. The only architectural force that would require a server is inbound traffic — provider
webhooks — and the refresh ADR defers those.

## Decision
This project has no backend, no cloud resources, no container, no database server and no
deployment pipeline. The single deployable artifact is `MissionControl.app`, containing the
`MissionControlWidgets` extension, built locally in Xcode, signed with the user's Developer ID
(paid Apple Developer Program membership, required regardless for App Groups and keychain access
groups), and copied to `/Applications`. Notarisation is optional and only relevant if the bundle
is ever moved to another machine.

Should the webhook option in the refresh ADR ever be taken up, it introduces a **named second
deploy target**: a minimal always-on public HTTPS endpoint (a single serverless function is
sufficient) that receives provider webhooks and forwards them to the Mac over an outbound-
initiated channel. That component would need its own hosting, its own webhook shared secrets,
its own uptime story and its own ADR. It is deferred, not assumed.

## Consequences
### Positive
- Nothing to operate, nothing to pay for, nothing to keep patched, no third party holding
  credentials or project data.
- The build/run loop is Cmd-R; there is no environment drift and no staging concept.
- All provider tokens stay on one machine in one keychain.

### Negative
- No off-machine backup of Tier A beyond whatever Time Machine or iCloud covers; a disk loss
  means re-registering Projects and re-pasting credentials.
- No remote observability — if the poller misbehaves the evidence exists only in the local
  unified log.
- Nothing runs when the Mac is asleep or off; combined with the refresh ADR, events in those
  windows are simply missed.

### Neutral
- CI is unnecessary for v1 but harmless to add later (a GitHub Action building and archiving the
  app) — that would be build tooling, not a deploy target, and does not change this decision.

## Alternatives considered
- **A small always-on cloud service (VPS or serverless) for polling and webhooks from day one** —
  rejected: creates hosting cost, an uptime obligation, and off-machine credential storage, to
  solve a latency problem the user has not yet reported having.
- **Building the webhook relay now, before it is needed** — rejected: it is a genuinely new
  distributed system with its own failure modes; the refresh ADR's polling design deliberately
  buys the time to find out whether it is ever warranted.

## References
- `.agentheim/knowledge/decisions/0001-permanent-single-user-personal-tool.md`
- The background refresh ADR (deferred webhook option).
```
