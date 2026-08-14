---
id: infrastructure-w4dg3
title: Desktop widget still renders "No data yet" after fixing the .atomic cross-process read bug
status: backlog
type: bug
context: infrastructure
created: 2026-08-14
completed:
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

- [ ] With the main app running and at least one Integration connected, a placed desktop widget
      (small or medium) renders real Integration data, not "No data yet".
- [ ] Root cause is identified and recorded here (or in a new ADR if it reveals a real
      architectural decision, e.g. a change to how/where Tier B is written).
