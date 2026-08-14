---
id: infrastructure-w4dg3
title: Desktop widget still renders "No data yet" after fixing the .atomic cross-process read bug
status: done
type: bug
context: infrastructure
created: 2026-08-14
completed: 2026-08-15
depends_on: [infrastructure-001-walking-skeleton]
blocks: []
tags: [walking-skeleton-followup, widget, tier-b]
related_adrs: [0004, 0005]
related_research: []
prior_art: []
---

## Why

During manual verification of `infrastructure-001-walking-skeleton`, the placed desktop widget
(`IntegrationStatusWidget`) persistently rendered "No data yet — open the app" even after all
three Integrations were connected and the app confirmed (via `os.Logger`, `Poll Now`, and direct
inspection of the App Group container on disk) that it was writing correct, fresh, well-formed
snapshot + manifest JSON on every poll.

## What was found and fixed this session (real, verified bugs — not the remaining blocker)

1. **Stale duplicate WidgetKit extension registration.** An earlier unsigned command-line
   verification build (`xcodebuild ... CODE_SIGNING_ALLOWED=NO`) landed in a second, different
   `DerivedData` folder and registered `com.lorenzoemanuele.missioncontrol.widgets` with
   LaunchServices/`pluginkit` twice — once ad-hoc-signed, once properly Team-ID-signed — which
   kept the widget out of the gallery entirely. Fixed by unregistering the stale bundle
   (`lsregister -u`) and deleting its `DerivedData` folder. Not a code bug; a side effect of
   diagnostic tooling. Documented here so it isn't mistaken for evidence of a code issue if a
   similar duplicate-registration symptom recurs.
2. **`SnapshotStore` writes used `Data.write(options: .atomic)`.** Confirmed via `.error`-level
   `os.Logger` output (now permanently added to `readManifest()`/`readSnapshot()` — see the type
   doc comment in `MissionControl/MissionControlKit/Sources/MCSnapshot/SnapshotStore.swift`) that
   this produced `NSPOSIXErrorDomain Code=1 "Operation not permitted"` when the **widget
   extension** process (a sibling to the writing app process, sharing the same App Group
   entitlement) tried to open a file the app had written atomically — a documented App Sandbox
   quirk where the temp-file-then-rename dance scopes the result to the writer's own sandbox
   container. Fixed by switching both `writeSnapshot` and `writeManifest` to plain (non-atomic)
   writes.

## What's still broken

After both fixes above, and after rebuilding + relaunching + reconnecting + polling, the widget
**still** showed "No data yet" per the user's direct report. This was not re-diagnosed before the
session stopped — the `.error`-level logging added in fix #2 should be the next diagnostic
starting point (check whether `readManifest()`/`readSnapshot()` are now succeeding but something
else nulls out `entry.snapshot`, or whether a *different* error is now being logged for the same
symptom).

## What to try next

- Re-check `log show --predicate 'subsystem == "com.lorenzoemanuele.missioncontrol" AND category
  == "snapshot-store"'` after a fresh poll, now that writes are non-atomic — confirm whether the
  `Operation not permitted` error is actually gone or whether it persists for a different reason
  (e.g. the *directory* itself, not just individual files, carrying the same sandbox-scoping
  problem from `FileManager.createDirectory` in `AppGroupContainer.snapshotsURL`).
- If the read now succeeds but the widget still shows no data, add temporary logging inside
  `IntegrationStatusTimelineProvider.getTimeline`/`getSnapshot` themselves (not just
  `SnapshotStore`) to confirm those methods are actually being invoked by WidgetKit at all, and
  what `entry.snapshot` actually contains at completion time.
- Consider whether `AppGroupContainer.snapshotsURL`'s unconditional
  `FileManager.default.createDirectory(...)` call on every read (not just writes) could itself be
  sandbox-restricted for the extension process in a way that silently throws before ever reaching
  the file read — verify by adding a distinct log line before/after that call.
- Worth ruling out: whether the *pre-existing* stale files on disk (written by the old `.atomic`
  path, before this session's fix) needed to be deleted rather than merely overwritten — if macOS
  ties the sandbox-scoping to the file's original inode/creation rather than re-checking on
  overwrite, a plain non-atomic write to the *same path* could inherit the old restriction. Try
  deleting `~/Library/Group Containers/group.com.lorenzoemanuele.missioncontrol/Snapshots/`
  entirely (safe — Tier B is a self-healing cache per ADR-0005) and letting the next poll recreate
  it fresh, rather than relying on the fix to correct existing files in place.

## Acceptance criteria

- [x] With the main app running and at least one Integration connected, a placed desktop widget
      (small or medium) renders real Integration data, not "No data yet".
- [x] Root cause is identified and recorded here (or in a new ADR if it reveals a real
      architectural decision, e.g. a change to how/where Tier B is written).

## Outcome

**Root cause found, confirmed by direct evidence, and fixed — nothing to do with `SnapshotStore`
at all.** Two more hypotheses were tried and definitively ruled out by controlled testing before
finding it:

1. **`com.apple.quarantine` extended attribute** — every file the app wrote into the App Group
   container carried this tag (agent "MissionControl" — the writer itself). Looked like a
   plausible App-Sandbox-auto-quarantine mechanism. Ruled out conclusively: fully quit the app (so
   nothing could rewrite files), stripped the attribute via `xattr -d com.apple.quarantine` on all
   four files, verified via `xattr -l` they stayed clean, then had the widget re-render (remove +
   re-add) with the app still dead. It **still** failed with the identical
   `NSPOSIXErrorDomain Code=1 "Operation not permitted"`. Quarantine was never the blocker.
2. (Carried over from the prior session) `.atomic` vs. non-atomic writes, and stale-file/inode
   theories — also ruled out by the same kind of direct test (fresh directory, fresh files, same
   failure).

**The actual root cause:** `project.yml` (xcodegen) writes `com.apple.security.application-groups`
directly into both targets' `.entitlements` files via `CODE_SIGN_ENTITLEMENTS`, bypassing Xcode's
Signing & Capabilities UI entirely. That UI isn't just a convenience editor — it's what actually
registers a capability like App Groups with the Apple Developer Portal and provisions a profile
that grants it. Without that registration having actually run, Xcode's Automatic Signing silently
falls back to a generic wildcard profile. Confirmed by decoding the real provisioning profile:

```
security cms -D -i ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/<uuid>.provisionprofile
```

Before the fix, the only profile on disk was `Mac Team Provisioning Profile: *`
(`application-identifier: 2C553PK57P.*`) — a wildcard profile, whose `Entitlements` dict had
`application-identifier` and `keychain-access-groups` but **no `application-groups` entry at
all**. Wildcard profiles cannot carry App Groups by Apple's own rules. This explains every
observed symptom exactly: the compiled entitlements XML still claims the capability (so
`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` resolves fine, and the writing
app can read its own output), but real cross-process sandbox enforcement checks the actual
provisioning grant, not the binary's local entitlements blob, and refuses the sibling widget
extension process.

**Fix:** opened each target's Signing & Capabilities tab in Xcode (App Groups was already listed
there — the fix was Xcode actually completing its registration/provisioning flow when the tab was
visited, not adding anything that wasn't already declared). This generated two new,
app-ID-specific profiles — `Mac Team Provisioning Profile: com.lorenzoemanuele.missioncontrol` and
`...missioncontrol.widgets` — both confirmed via the same `security cms -D -i` inspection to carry
`com.apple.security.application-groups`. Reads succeeded immediately afterward, confirmed via the
`.error`-level logging added to `SnapshotStore` (zero failures from the new process, vs. 100%
failure rate before) — and notably, `com.apple.quarantine` was still present on the files at that
point, further confirming it was never the actual blocker.

**What's left in the code:** `SnapshotStore.clearQuarantine(at:)` is kept as harmless hygiene (see
its updated doc comment), and the `.error`-level read-failure logging is kept permanently — it's
exactly what let this be diagnosed with certainty instead of guessed at. The infrastructure BC
README's "Provisioning caveat" section now documents this pattern generally for any future
xcodegen-authored capability that needs portal registration.
