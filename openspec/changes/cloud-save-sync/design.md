## Context

- **Launching**: every launch from TriOS goes through `LauncherButton.launchGame` (`lib/launcher/launcher.dart`). It runs `performLaunchPrecheck`, then starts the game as a detached process. TriOS keeps no process handle, so it cannot wait for the game to exit.
- **Game exit**: `_GameRunningChecker` in `lib/trios/app_state.dart` polls every 1.5 seconds and exposes `AppState.isGameRunning`. It skips checks while TriOS is unfocused. It only runs when the `checkIfGameIsRunning` setting is on. Chipper already reacts to the game closing with `ref.listen(AppState.isGameRunning, ...)`, watching for a `true` → `false` change.
- **Saves**: `AppState.savesFolder` gives the saves folder (default or custom path). `SaveFileNotifier` (`lib/mod_profiles/save_reader.dart`) reads each `save*` folder's `descriptor.xml` into a `SaveFile`, including the enabled mod list. `ModProfileManagerNotifier.computeModProfileChanges` compares a mod list against installed mods. `ModProfileCard` uses it for saves.
- **Settings**: `Settings` (`lib/trios/settings/settings.dart`) is a `@MappableClass` saved to `trios_settings-v1.json` by `AppSettingNotifier`. Larger feature state lives in its own file through `GenericAsyncSettingsManager` + `GenericSettingsAsyncNotifier` (Mod Profiles uses this). The Settings page is a column of `SettingsGroup`s.
- **Archives**: the `archive` package (pure Dart, already a dependency) reads zips elsewhere in TriOS. The 7-Zip wrapper is used for mod installs, but its tests only run locally because they need the binary.

## Goals / Non-Goals

**Goals:** opt-in, safe, reviewable save syncing through a folder; behavior that holds up with slow, delayed cloud drives such as SeaDrive; working between Windows and Linux.

**Non-Goals:** networking, accounts, live sync while playing, passing deletions between machines, syncing `saves/common`.

## Decisions

### 1. Backend interface, one folder implementation
`SaveSyncBackend` (abstract) has methods to: read the layout marker, list remote entries (manifests, zips, conflict copies), read a manifest, copy a zip to a local file, write a zip and manifest, list/write/remove lock files, and move a remote file to a local path.
`FolderSaveSyncBackend` implements it with `dart:io`. An API backend later only needs a new implementation.
*Why:* the user asked for this, and it keeps file-system details out of the sync logic, so the logic can be tested against temp folders.

### 2. Zip with the `archive` package, run off the UI thread
Archives are created and extracted with `archive` (`ZipFileEncoder` / `ZipDecoder` with file streams) inside `Isolate.run`.
*Why:* no new dependency, works the same on all three platforms, and tests run in CI without the 7-Zip binary. Saves can be 100 MB+ uncompressed, so the work must not block the UI.
*Alternative:* the existing 7-Zip wrapper. Rejected because its interface has no "create archive" method yet and its tests are local-only.

### 3. Content hash, not modified times
`computeSaveContentHash(Directory)` lists all files, sorts by relative path (with `/`), and hashes `path + "\0" + sha256(file)` for each into one SHA-256. The manifest stores this hash and also the SHA-256 of the zip itself.
*Why:* cloud clients reset modified times. The zip hash lets the other machine detect a zip that does not match its manifest (still uploading, or a half-finished rename pair).

### 4. Pure decision function
`decideSaveSync(localHash, remoteManifest, record)` returns a `SaveSyncDecision` enum (`upToDate`, `push`, `pull`, `conflict`, `missingLocally`). It follows the decision table in the spec. It does no I/O.
*Why:* this is the riskiest logic, and a pure function is easy to test exhaustively.

### 5. Sync folder layout and per-machine lock files
```
<sync folder>/
  trios-save-sync.json                  { "layoutVersion": 1 }
  saves/<save>.zip
  saves/<save>.manifest.json
  locks/<machine-id>.lock.json
```
*Why:* if both machines wrote the same lock file, the cloud client would make conflict copies of it. One file per machine avoids that. The machine id is a UUID created once per TriOS install and stored in the sync state file. The machine name (`Platform.localHostname`) is for display only.

### 6. Write order and temp names
Push: zip the save into a local temp file → copy it to `saves/<save>.zip.tmp` → rename to `<save>.zip` → write `<save>.manifest.json.tmp` → rename. The old zip and manifest are not backed up on a normal push, because they are the previous version of this PC's own data and are already recorded locally. They are backed up when a conflict is resolved as "Keep this PC's save".
Pull: copy zip to a local temp file (60-second no-progress timeout) → check its SHA-256 against the manifest → extract to `saves/.trios-sync-incoming-<save>` → rename the current save to `saves/.trios-sync-outgoing-<save>` → rename incoming to `<save>` → move outgoing into backups. If the second rename fails, the outgoing folder is renamed back.
*Why:* every rename stays inside one folder, so it is atomic. Temp folders start with `.`, so Starsector does not list them as saves (it only lists folders starting with `save`). The `.tmp` suffix is ignored by Seafile's default ignore list, and other clients upload it only briefly.
Zip entries with absolute paths or `..` are rejected before extraction.

### 7. Backups are local
Backups go to `<Constants.configDataFolderPath>/save_sync_backups/<save>/<yyyy-MM-dd_HH-mm-ss>_<reason>/`. Reasons: `before-pull`, `conflict-local`, `conflict-synced`, `cloud-conflict-copy`. Moving across drives is done by copy, then compare file count and sizes, then delete the source.
*Why:* keeping backups out of the sync folder avoids uploading large files and avoids other machines seeing them. A settings button opens the folder. Backups are not pruned automatically in v1.

### 8. Sync state file
`SaveSyncStateManager extends GenericAsyncSettingsManager<SaveSyncState>` saves to `trios_save_sync_state-v1.json`. `SaveSyncState` holds `machineId` and a map of `SaveSyncRecord`s keyed by `"<saves folder path>|<save folder name>"`. Each record holds the content hash, the manifest from the last sync, and the sync time.
*Why:* keying by saves folder lets one PC act as two machines in manual testing by switching the custom saves folder. It also stops records from leaking between two game installs.

### 9. Settings
Added to `Settings`: `saveSyncEnabled` (default `false`), `saveSyncFolder` (`Directory?`, `DirectoryHook`), `saveSyncSaveNames` (`List<String>`, default empty). The sync record data stays out of `Settings` (decision 8) because it changes on every sync.

### 10. Session and game-exit detection
`SaveSyncNotifier` (an `AsyncNotifier<SaveSyncStatus>`) owns the session. A session opens when TriOS launches the game, or when the game is seen starting without a TriOS launch. Opening a session writes the lock and sets `AppState.keepCheckingGameWhileUnfocused` to true. A `ref.listen(AppState.isGameRunning, ...)` (same pattern as Chipper) runs post-exit sync on `true` → `false`, removes the lock, and clears the flag.
While a session is open and TriOS is unfocused, checks run every 5 seconds instead of every 1.5 seconds. Focused checks keep the 1.5-second interval.
If `checkIfGameIsRunning` is off, TriOS cannot tell when the game closes. The settings group then shows a warning with a button to turn it on, and TriOS falls back to syncing on the next launch or with "Sync now".

### 11. Launch integration
`LauncherButton.launchGame` calls `await ref.read(saveSyncProvider.notifier).prepareForLaunch(context)` first. It returns `false` if the user cancels. When save sync is off it returns `true` immediately, so launch behavior is unchanged.

### 12. Name checks and conflict copies
`save_sync_names.dart` checks Windows-invalid characters, trailing dot/space, reserved names (`CON`, `PRN`, `AUX`, `NUL`, `COM1`-`9`, `LPT1`-`9`), and case-insensitive duplicates across local and remote names. `cloud_conflict_files.dart` recognizes Seafile, Dropbox, and Syncthing conflict-copy names with regular expressions and returns the original file name they belong to.

### 13. UI
- **Settings page**: new `SettingsGroup(name: "Save Sync")` right after the "Starsector" group. It contains: enable checkbox (`CheckboxWithLabel`), sync folder field with a folder picker (`file_picker`, as `GamePathsWidget` does), a list of local and synced saves with a checkbox, character name, status, last sync time and machine, and buttons "Sync now", "Open backups folder", and "Move conflict copies to backups" (only shown when there are any). Tooltips use `MovingTooltipWidget.text`.
- **Dialogs** (`save_sync_dialogs.dart`): progress, lock warning, conflict choice, mod check, and error. They use `AlertDialog`, like the launch precheck dialog.
- No new navigation tab and no toolbar change in v1.

### 14. File list
New, under `lib/save_sync/`:
- `save_sync_backend.dart`: `SaveSyncBackend` interface.
- `folder_save_sync_backend.dart`: folder implementation, `.tmp` + rename, read timeout.
- `models/save_sync_manifest.dart`, `models/save_sync_lock.dart`, `models/save_sync_state.dart`: `@MappableClass` models.
- `save_content_hash.dart`: content hash.
- `save_archiver.dart`: zip and safe extract.
- `save_sync_decision.dart`: decision function.
- `save_sync_backups.dart`: moving data into backups.
- `save_sync_names.dart`, `cloud_conflict_files.dart`: name checks.
- `save_sync_manager.dart`: `SaveSyncNotifier`, state file manager, providers.
- `save_sync_dialogs.dart`, `save_sync_settings_section.dart`: UI.

Changed: `settings.dart` (+ generated mapper), `settings_page.dart`, `launcher.dart`, `app_state.dart`, `CONTEXT.md` (glossary terms).

### 15. Changes made during implementation
- Extraction refuses a zip with no top-level `descriptor.xml`. The `archive` package returns an empty archive for some damaged files instead of throwing, which would otherwise replace a save with an empty folder.
- `SaveSyncEngine` (`save_sync_engine.dart`) holds the sync steps with no UI or Riverpod, so they can be tested with two simulated PCs. `SaveSyncNotifier` (`save_sync_manager.dart`) decides when to run them and shows the dialogs.
- `readSave` in `save_reader.dart` now delegates to a top-level `readSaveFolder`, so save sync can read a `descriptor.xml` without the Mod Profiles notifier.
- `AppShell` listens to `saveSyncProvider` so the notifier exists from startup. It listens rather than watches, so status changes don't rebuild the shell.
- If a launch doesn't start the game within 3 minutes (for example the launch precheck was cancelled), the sync session closes and the lock is removed.
- The settings group has a "Check again" button that re-reads both sides without changing anything.

### 16. Switching mods to match a pulled save
- The mod check compares the save's mods with the mods **enabled** here (it used to compare only with installed mods), so it can list mods to turn on, turn off, or switch version.
- "Pull and switch mods" writes the save's mod list into a profile named "Save sync: <character>" and activates it with `activateModProfile`. *Why:* the active mod profile follows whatever is enabled, so switching mods directly would overwrite the user's own profile. Reusing one profile per character avoids piling up profiles.
- `activateModProfile` gained `reapplyIfActive`, because the "Save sync" profile may already be active when its list is replaced. Nothing else in Mod Profiles changed.
- The profile is saved with `updateState` and awaited, because `createModProfile` doesn't wait for its write and activation would not find the new profile.
- Switching runs once, after all pulls. If it was chosen for several saves, a dialog asks which one, because only one set of mods can be enabled.
- `activateModProfile` logs failures instead of throwing, so save sync compares again afterwards and reports leftovers as an error.
- Mods that aren't installed are not downloaded. That stays with the mod manager.

### 17. Checking the saves folder against vmparams
- `AppState.savesFolder` is `<game>/saves` or TriOS's custom saves folder. It never reads vmparams, so a saves path changed there was invisible to TriOS. Save sync would then pull into a folder the game doesn't use and push stale copies.
- `saves_folder_check.dart` reads `-Dcom.fs.starfarer.settings.paths.saves` from the first selected vmparams file (the same file TriOS's direct launch uses) and resolves relative paths against the game core folder, as `_generateVmparamOverrides` in `launcher.dart` does. Plain values, quoted values, and quoted arguments are handled.
- `savesFolderMismatchProvider` compares the two. While they differ, `SaveSyncNotifier.build` returns an inactive status, so no step can run. While the check is still loading, sync is also inactive, so nothing touches saves before the answer is known.
- The fix button sets the existing custom saves folder setting. TriOS never edits vmparams for this.
- `AppState.savesFolder` itself is unchanged, so Mod Profiles and other features behave as before.

## Risks / Trade-offs

- **Cloud client delay** → The other PC may not have the latest zip yet. The lock warning and the "waiting for cloud client" status make this visible. TriOS cannot know what the server has.
- **Game started outside TriOS** → No pre-launch pull. TriOS says so when it sees the game start.
- **Large saves on slow drives** → Pre-launch sync can take time. The progress dialog shows which save and step is running.
- **Starsector's save folder rules** → "Keep both" relies on Starsector loading a save from any folder starting with `save` that holds a `descriptor.xml`. This needs checking against the game code before that option ships.
- **Backups grow without limit** → Accepted for v1. The settings group shows the backups folder size.

## Open Questions

- Should the post-exit push also run when TriOS closes while a session is open? The current design runs it on the next TriOS start instead.
- Should Linux and macOS conflict-copy formats from other clients (OneDrive, Google Drive) be added? Their names are less predictable.
