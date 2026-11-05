Each numbered section is one commit.

## 1. Models and settings

- [x] 1.1 Add `SaveSyncManifest`, `SaveSyncManifestMod`, `SaveSyncLock`, `SaveSyncRecord`, `SaveSyncState` as `@MappableClass` models in `lib/save_sync/models/`
- [x] 1.2 Add `saveSyncEnabled`, `saveSyncFolder`, `saveSyncSaveNames` to `Settings`
- [x] 1.3 Run `dart run build_runner build --delete-conflicting-outputs`

## 2. Pure logic

- [x] 2.1 `save_sync_names.dart`: Windows-invalid names, reserved names, case-insensitive duplicates
- [x] 2.2 `cloud_conflict_files.dart`: recognize Seafile, Dropbox, Syncthing conflict copies and return the original name
- [x] 2.3 `save_sync_decision.dart`: `SaveSyncDecision` enum and `decideSaveSync`, following the spec's decision table
- [x] 2.4 Lock age check (stale after 24 hours) and "is this my lock" check
- [x] 2.5 Tests for 2.1–2.4 in `test/save_sync/`

## 3. Hashing, archives, backups

- [x] 3.1 `save_content_hash.dart`: content hash over sorted relative paths with `/`
- [x] 3.2 `save_archiver.dart`: zip a save folder to a file in an isolate; extract with rejection of absolute and `..` paths
- [x] 3.3 Safe replace of a local save (incoming/outgoing rename, roll back on failure)
- [x] 3.4 `save_sync_backups.dart`: move to timestamped backup folder, copy-then-verify across drives
- [x] 3.5 Tests: hash stable across path separators and file order, zip round trip, bad zip leaves local save unchanged, backups keep all files

## 4. Backend

- [x] 4.1 `save_sync_backend.dart`: `SaveSyncBackend` interface
- [x] 4.2 `folder_save_sync_backend.dart`: layout marker, listing (skipping conflict copies and `.tmp`), `.tmp` + rename writes, zip before manifest, per-machine lock files, UTF-8 + `\n` JSON
- [x] 4.3 Copy with a 60-second no-progress timeout and a clear error message
- [x] 4.4 Tests using two temp sync folders: push then pull, zip/manifest hash mismatch shows "waiting", layout version too new is refused

## 5. Sync manager

- [x] 5.1 `SaveSyncStateManager` (`trios_save_sync_state-v1.json`) with a machine id created on first use
- [x] 5.2 `SaveSyncNotifier`: build per-save status from local saves, manifests, and records
- [x] 5.3 `syncNow`, `prepareForLaunch`, `afterGameExit`, conflict resolution actions (keep local / keep synced / keep both / skip)
- [x] 5.4 Mod check for pulls using `computeModProfileChanges`
- [x] 5.5 Session handling: lock write/remove, leftover own lock at startup, game started outside TriOS
- [x] 5.6 Tests for the engine flows against temp folders (no real saves folder). The notifier's dialog flows are covered by the manual test plan.

## 6. Game-running check and launch hook

- [x] 6.1 Add `AppState.keepCheckingGameWhileUnfocused` and read it in `_GameRunningChecker._poll`
- [x] 6.2 Call `prepareForLaunch` at the start of `LauncherButton.launchGame`; stop if it returns `false`

## 7. UI

- [x] 7.1 `save_sync_dialogs.dart`: progress, lock warning, conflict, mod check, error dialogs
- [x] 7.2 `save_sync_settings_section.dart`: enable checkbox, folder picker, save list with status, buttons, cloud-upload note, warning when the game-running check is off
- [x] 7.3 Add the "Save Sync" group to `settings_page.dart` after "Starsector"

## 8. Docs and checks

- [x] 8.1 Add glossary entries to `CONTEXT.md`: save sync, sync folder, sync session, sync record
- [x] 8.2 Add a line for `lib/save_sync/` to the feature list in `CLAUDE.md` and `AGENTS.md`
- [x] 8.3 `flutter analyze` (no issues in new or changed lines) and `flutter test` (all pass except the existing `local-only` 7-Zip tests, which need the maintainer's test archives). `dart run custom_lint` can't run: `custom_lint` is in `analysis_options.yaml` but not in `pubspec.yaml`.
- [x] 8.4 Write the manual test plan (two folders on one PC; Windows ↔ Linux through SeaDrive) in `openspec/changes/cloud-save-sync/manual-test-plan.md`

## 9. Switch mods to match a pulled save

- [x] 9.1 Mod check compares with enabled mods and lists turn on / turn off / switch version / not installed
- [x] 9.2 "Pull and switch mods" saves a "Save sync: <character>" profile and activates it (`activateModProfile` gets `reapplyIfActive`)
- [x] 9.3 Ask which save's mods to use when several were chosen; report mods that didn't switch as an error
- [x] 9.4 Manual test plan steps 1.26–1.29 (the notifier's dialog flows have no automated tests, same as 5.6)

## 10. Saves folder must match the game's vmparams

- [x] 10.1 `saves_folder_check.dart`: read and resolve the vmparams saves path, compare with TriOS's saves folder
- [x] 10.2 Pause save sync while they differ; block launch with "Launch anyway" / "Cancel"
- [x] 10.3 Settings warning with both paths and "Use the game's saves folder"
- [x] 10.4 Tests for reading and resolving the path; manual test plan steps 1.30–1.32

## 11. Restore a save deleted on this PC

- [x] 11.1 "Restore from sync folder" button for saves marked "Missing on this PC" (normal pull with mod check)
- [x] 11.2 Engine test for restoring; manual test plan step 1.33
