Each numbered section is one commit.

## 1. Models and settings

- [ ] 1.1 Add `SaveSyncManifest`, `SaveSyncManifestMod`, `SaveSyncLock`, `SaveSyncRecord`, `SaveSyncState` as `@MappableClass` models in `lib/save_sync/models/`
- [ ] 1.2 Add `saveSyncEnabled`, `saveSyncFolder`, `saveSyncSaveNames` to `Settings`
- [ ] 1.3 Run `dart run build_runner build --delete-conflicting-outputs`

## 2. Pure logic

- [ ] 2.1 `save_sync_names.dart`: Windows-invalid names, reserved names, case-insensitive duplicates
- [ ] 2.2 `cloud_conflict_files.dart`: recognize Seafile, Dropbox, Syncthing conflict copies and return the original name
- [ ] 2.3 `save_sync_decision.dart`: `SaveSyncDecision` enum and `decideSaveSync`, following the spec's decision table
- [ ] 2.4 Lock age check (stale after 24 hours) and "is this my lock" check
- [ ] 2.5 Tests for 2.1–2.4 in `test/save_sync/`

## 3. Hashing, archives, backups

- [ ] 3.1 `save_content_hash.dart`: content hash over sorted relative paths with `/`
- [ ] 3.2 `save_archiver.dart`: zip a save folder to a file in an isolate; extract with rejection of absolute and `..` paths
- [ ] 3.3 Safe replace of a local save (incoming/outgoing rename, roll back on failure)
- [ ] 3.4 `save_sync_backups.dart`: move to timestamped backup folder, copy-then-verify across drives
- [ ] 3.5 Tests: hash stable across path separators and file order, zip round trip, bad zip leaves local save unchanged, backups keep all files

## 4. Backend

- [ ] 4.1 `save_sync_backend.dart`: `SaveSyncBackend` interface
- [ ] 4.2 `folder_save_sync_backend.dart`: layout marker, listing (skipping conflict copies and `.tmp`), `.tmp` + rename writes, zip before manifest, per-machine lock files, UTF-8 + `\n` JSON
- [ ] 4.3 Copy with a 60-second no-progress timeout and a clear error message
- [ ] 4.4 Tests using two temp sync folders: push then pull, zip/manifest hash mismatch shows "waiting", layout version too new is refused

## 5. Sync manager

- [ ] 5.1 `SaveSyncStateManager` (`trios_save_sync_state-v1.json`) with a machine id created on first use
- [ ] 5.2 `SaveSyncNotifier`: build per-save status from local saves, manifests, and records
- [ ] 5.3 `syncNow`, `prepareForLaunch`, `afterGameExit`, conflict resolution actions (keep local / keep synced / keep both / skip)
- [ ] 5.4 Mod check for pulls using `computeModProfileChanges`
- [ ] 5.5 Session handling: lock write/remove, leftover own lock at startup, game started outside TriOS
- [ ] 5.6 Tests for the manager flows against temp folders (no real saves folder)

## 6. Game-running check and launch hook

- [ ] 6.1 Add `AppState.keepCheckingGameWhileUnfocused` and read it in `_GameRunningChecker._poll`
- [ ] 6.2 Call `prepareForLaunch` at the start of `LauncherButton.launchGame`; stop if it returns `false`

## 7. UI

- [ ] 7.1 `save_sync_dialogs.dart`: progress, lock warning, conflict, mod check, error dialogs
- [ ] 7.2 `save_sync_settings_section.dart`: enable checkbox, folder picker, save list with status, buttons, cloud-upload note, warning when the game-running check is off
- [ ] 7.3 Add the "Save Sync" group to `settings_page.dart` after "Starsector"

## 8. Docs and checks

- [ ] 8.1 Add glossary entries to `CONTEXT.md`: save sync, sync folder, sync session, sync record
- [ ] 8.2 Add a line for `lib/save_sync/` to the feature list in `CLAUDE.md` and `AGENTS.md`
- [ ] 8.3 `flutter analyze`, `dart run custom_lint`, `flutter test`
- [ ] 8.4 Write the manual test plan (two folders on one PC; Windows ↔ Linux through SeaDrive) in `openspec/changes/cloud-save-sync/manual-test-plan.md`
