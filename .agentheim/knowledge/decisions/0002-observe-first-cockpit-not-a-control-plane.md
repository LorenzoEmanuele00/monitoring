---
id: 0002
title: Observe-first cockpit with narrow quick actions, not a control plane
scope: global
status: accepted
date: 2026-08-07
supersedes: []
superseded_by: []
related_tasks: []
related_research: []
---

# ADR 0002: Observe-first cockpit with narrow quick actions, not a control plane

## Context
Early in the brainstorm, "control everything from a single point" was ambiguous between two
very different products: a full remote-operations console (merge PRs, manage servers via
SSH/CLI, run arbitrary deploys) versus a glanceable status board with a handful of one-click
escape hatches. This had to be resolved before any bounded context design, since it determines
how much surface area Service Integrations needs to expose.

## Decision
The product is observe-first: its main job is showing project/integration state at a glance.
It supports a small, explicitly bounded set of Quick Actions (e.g. re-run a GitHub Action,
restart a broken deploy) triggered directly against a provider's API, plus deep links out to
the provider's own dashboard. It will never grow into a general operations console: no PR
merging, no SSH/terminal-style server management, no CLI interface, no full CI/CD control.
Any operation beyond a narrow, well-understood Quick Action stays on the vendor's own platform.

## Consequences
### Positive
- Service Integrations' surface area stays small and reviewable — each Provider adapter only
  needs to support a short, explicit list of Quick Actions, not full API coverage.
- Avoids duplicating (and falling out of sync with) vendor dashboards' own operational UIs.
- Lower security exposure: fewer destructive/high-privilege actions need credentials with wide
  scopes.

### Negative
- Some genuinely convenient actions (e.g. merging a PR from the widget) are permanently out of
  scope, even if trivial to add technically — the temptation must be actively resisted as the
  product grows.

### Neutral
- The list of "which actions count as Quick Actions" is a per-Provider design decision made in
  Service Integrations, not a one-time global list fixed by this ADR.

## Alternatives considered
- **Full operations console** (merge PRs, SSH into servers, trigger arbitrary deploys) —
  rejected: explicitly ruled out by the user; would balloon Service Integrations' scope and
  security surface for a personal tool that mainly needs visibility.

## References
- `.agentheim/vision.md` — Non-goals section.
- `.agentheim/contexts/service-integrations/README.md` — Quick Action definition.
