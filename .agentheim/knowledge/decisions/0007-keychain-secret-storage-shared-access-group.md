---
id: 0007
title: Credentials live in the macOS data protection keychain behind a shared access group
scope: global
status: accepted
date: 2026-08-13
supersedes: []
superseded_by: []
related_tasks: [infrastructure-hv013]
related_research: []
---

# ADR 0007: Credentials live in the macOS data protection keychain behind a shared access group

## Context
Every Service Integration needs provider auth material. It must survive reboots, be readable by
a background poller without an interactive prompt, never appear in the SQLite store, snapshot
files, logs or version control, and be revocable per Integration. Widget Quick Actions may
eventually want to execute inside the widget extension process, which would require the
extension to read a credential — not needed in v1, but expensive to enable retroactively,
because a keychain item's access group is fixed at write time.

## Decision
All credential material is stored in the macOS **data protection keychain**
(`kSecUseDataProtectionKeychain: true`) as `kSecClassGenericPassword` items:
- `kSecAttrService` = a fixed app-wide service string
- `kSecAttrAccount` = the Integration's UUID
- `kSecAttrAccessible` = `kSecAttrAccessibleAfterFirstUnlock`, so the resident poller works
  after login without prompting
- `kSecAttrAccessGroup` = a shared access group declared in both the app's and the extension's
  `keychain-access-groups` entitlement, provisioned from day one

The value is an opaque `Data` blob. `MCSecrets` exposes a narrow `SecretStore` protocol —
`store(_:for:)`, `read(for:)`, `delete(for:)` — and knows nothing about providers. Interpreting
the blob (bearer token vs. service account key vs. refresh token) is the provider adapter's job.

In v1 the widget extension does not read credentials: it renders snapshots only, and Quick
Action `AppIntent`s hand execution to the main app. The access group is provisioned anyway as
cheap insurance against a future in-extension execution path.

Hard rules: credentials never enter Tier A SQLite, never enter snapshot files, never enter
`os_log` output (all logging of credential-adjacent values uses redacted interpolation), and no
credential is ever written to a file in the repo.

## Consequences
### Positive
- OS-level at-rest protection and per-item revocation with no bespoke crypto.
- The app survives reboot and starts polling after login with no user interaction.
- A future in-extension Quick Action needs an entitlement flip, not a re-entry of every token.

### Negative
- Requires code signing with a real Team ID and a paid Apple Developer Program membership
  (keychain access groups, like App Groups, are unavailable to free personal teams).
- Data protection keychain items are bound to the signing identity; changing the signing
  certificate or bundle identifier orphans the items and forces re-entry of every credential.

### Neutral
- `kSecAttrAccessibleAfterFirstUnlock` is a deliberate trade: background polling without prompts,
  in exchange for credentials being readable by the signed app any time the Mac is unlocked
  post-boot. Acceptable for a single-user tool on the owner's own machine (ADR-0001).

## Alternatives considered
- **An encrypted file in the App Group container** — rejected: reinvents the keychain, and the
  encryption key has to live somewhere, which is the keychain.
- **The legacy (file-based) macOS keychain** — rejected: ACL-based sharing between an app and its
  extension is more awkward than access groups and diverges from the modern, documented path.
- **Environment variables or a dotfile** — rejected: no at-rest protection, trivially leaked into
  logs and backups, and unreachable from a sandboxed extension.
- **Provisioning the access group only when first needed** — rejected: access group is fixed at
  item-write time; retrofitting means re-entering every credential.

## References
- `.agentheim/knowledge/decisions/0001-permanent-single-user-personal-tool.md`
- `.agentheim/contexts/service-integrations/README.md` — Credential.
- Apple: Sharing access to keychain items among a collection of apps.
