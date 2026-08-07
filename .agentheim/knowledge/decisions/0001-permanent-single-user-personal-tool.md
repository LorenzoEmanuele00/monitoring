---
id: 0001
title: Permanent single-user, personal-tool scope
scope: global
status: accepted
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: []
related_research: []
---

# ADR 0001: Permanent single-user, personal-tool scope

## Context
During the brainstorm session, the motivating drive behind this project was named as wanting a
single, centralized point of control over an arbitrarily growing number of personal projects.
It was necessary to establish whether "future proof" meant scaling toward other users
(teammates, a shared account, a commercial product) or scaling toward more projects/integrations
under one user.

## Decision
This is, and will permanently remain, a single-user tool built by and for one person (Lorenzo),
running on one Mac. "Future proof" refers exclusively to the number of Projects and Service
Integrations the tool can absorb over time — never to multi-tenancy, team accounts, or shared
access.

## Consequences
### Positive
- No auth/authorization model beyond local machine access is needed.
- No multi-tenant data isolation, permissions, or sharing concerns complicate the domain model.
- Every bounded context can assume exactly one Project owner exists.

### Negative
- If priorities ever change toward a shared or commercial tool, this is a deliberate pivot, not
  an incremental extension — expect rework across Project Registry and any persistence choices
  made assuming single-user.

### Neutral
- This decision doesn't rule out running the tool on more than one of the user's own Macs later
  (a sync concern), only multi-*user* scenarios.

## Alternatives considered
- **Build for eventual team/multi-user use** — rejected: no such need was expressed, and
  designing for it now would add authorization/isolation complexity with no current payoff.

## References
- `.agentheim/vision.md` — Users, Non-goals sections.
