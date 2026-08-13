---
id: 0011
title: No backend — the only deployable artifact is a locally-built signed macOS app bundle
scope: global
status: accepted
date: 2026-08-13
supersedes: []
superseded_by: []
related_tasks: [infrastructure-wv33x]
related_research: []
---

# ADR 0011: No backend — the only deployable artifact is a locally-built signed macOS app bundle

## Context
It is worth stating explicitly, and early, whether this system has a server-side component. Under
ADR-0001 there is one permanent user on one Mac; all persistence is local; every provider API
(GitHub, Firebase Hosting, Supabase, Vercel) is reachable with an outbound HTTPS call from that
Mac. The only architectural force that would require a server is inbound traffic — provider
webhooks — and ADR-0006 (refresh topology) defers those. Separately, ADR-0010 adds PostHog as a
consumed third-party SaaS for structured event tracking; that is a service the app *calls*, not
infrastructure the user operates, and does not change this decision.

## Decision
This project has no backend, no cloud resources, no container, no database server and no
deployment pipeline that the user operates. The single deployable artifact is
`MissionControl.app`, containing the `MissionControlWidgets` extension, built locally in Xcode,
signed with the user's Developer ID (paid Apple Developer Program membership, required regardless
for App Groups and keychain access groups), and copied to `/Applications`. Notarisation is
optional and only relevant if the bundle is ever moved to another machine.

Should the webhook option in ADR-0006 ever be taken up, it introduces a **named second deploy
target**: a minimal always-on public HTTPS endpoint (a single serverless function is sufficient)
that receives provider webhooks and forwards them to the Mac over an outbound-initiated channel.
That component would need its own hosting, its own webhook shared secrets, its own uptime story
and its own ADR. It is deferred, not assumed.

## Consequences
### Positive
- Nothing to operate, nothing to pay for, nothing to keep patched, no third party holding
  credentials or project data.
- The build/run loop is Cmd-R; there is no environment drift and no staging concept.
- All provider tokens stay on one machine in one keychain.

### Negative
- No off-machine backup of Tier A beyond whatever Time Machine or iCloud covers; a disk loss
  means re-registering Projects and re-pasting credentials.
- No remote observability beyond the narrow PostHog event set (ADR-0010) — if the poller
  misbehaves outside that set, the evidence exists only in the local unified log.
- Nothing runs when the Mac is asleep or off; combined with ADR-0006, events in those windows are
  simply missed.

### Neutral
- CI is unnecessary for v1 but harmless to add later (a GitHub Action building and archiving the
  app) — that would be build tooling, not a deploy target, and does not change this decision.
- Consuming third-party SaaS APIs (GitHub, Firebase, Supabase, Vercel, and now PostHog) is not a
  "backend" under this decision — the line is operating infrastructure vs. calling someone else's.

## Alternatives considered
- **A small always-on cloud service (VPS or serverless) for polling and webhooks from day one** —
  rejected: creates hosting cost, an uptime obligation, and off-machine credential storage, to
  solve a latency problem the user has not yet reported having.
- **Building the webhook relay now, before it is needed** — rejected: it is a genuinely new
  distributed system with its own failure modes; ADR-0006's polling design deliberately buys the
  time to find out whether it is ever warranted.

## References
- `.agentheim/knowledge/decisions/0001-permanent-single-user-personal-tool.md`
- `.agentheim/knowledge/decisions/0006-resident-app-polling-refresh-topology.md` — deferred
  webhook option.
- `.agentheim/knowledge/decisions/0010-unified-logging-plus-posthog-for-structured-events.md` —
  why PostHog doesn't count as a backend under this ADR.
