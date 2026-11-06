## Context

Save sync (`openspec/changes/cloud-save-sync/`) already moves selected saves through a sync folder. It has a folder backend, zip and hash helpers, a decision table, sync records, backups, locks, and the launch and game-exit hooks. Mod sync reuses all of these. This document covers only what is new or different for mods.

The maintainer's mods folder is 1.9 GB in 76 folders, and some mods are there in more than one version. TriOS switches the active version of a mod by renaming `mod_info.json` in the inactive folders to `mod_info.json.disabled-by-TriOS` (`Constants.modInfoFileDisabledNames`).

## Goals / Non-Goals

**Goals:** keep every mod folder and the enabled-mods list the same on all PCs, without slowing down each launch and without ever deleting a mod on another PC.

**Non-Goals:** downloading mods from the internet, picking which mods to sync, passing deletions on, syncing while the game runs.

## Decisions

### 1. Each mod folder is one item, like a save

Each folder directly inside the mods folder becomes one item. It is stored as `mods/<folder>.zip` and `mods/<folder>.manifest.json`, uses `decideSaveSync` unchanged, and has a sync record. Reusing the save code means the same safety rules apply: temp names, zip-then-manifest order, hash check before extract, and backups.

Folders whose name starts with `.` are skipped. This leaves out TriOS's own temp folder (decision 6) and hidden folders such as `.git` at the top level.

**Why not one zip for the whole mods folder:** every small change would rewrite 2 GB.

### 2. `mod_info.json` is hashed and zipped under one name

When hashing and zipping a mod folder, every file named in `Constants.modInfoFileNames` is treated as `mod_info.json`. Switching the active version then doesn't change any folder's hash. The active version is synced with the enabled-mods list instead (decision 4).

When a pulled mod folder replaces one that exists on this PC, the extracted `mod_info.json` is renamed back to this PC's name before the folder is moved into place. A pulled folder that is new on this PC keeps the name `mod_info.json` unless another folder of the same mod id exists here. In that case it gets `mod_info.json.disabled-by-TriOS`, so two versions are never active at once. The enabled-mods list then decides which version is active.

### 3. Fast change check with a folder fingerprint

Hashing 2 GB at every launch takes too long. The sync record for each mod stores a fingerprint next to the content hash: file count, total size in bytes, and the newest file modified time. Before hashing, TriOS lists the folder's files (sizes and times only). If the fingerprint matches the record, the stored hash is used. Otherwise the folder is hashed again.

After a pull, the fingerprint is taken from the extracted folder, because extracting sets new file times.

**Trade-off:** an edit that keeps the same size and doesn't change any file time would be missed. Editors always update the file time, so this is very unlikely.

### 4. The enabled-mods list is synced as data, not as a file

The item is a list of `ShallowModVariant` (mod id, mod version, `smolVariantId`) for the enabled mods. This is the same shape Mod Profiles and save manifests use. The local list comes from `AppState.enabledModVariants`. The content hash is the SHA-256 of the sorted `smolVariantId`s, so order doesn't matter. It is stored as `enabled-mods.json` at the sync folder root, with machine, OS, and sync time.

Syncing the list instead of the file's bytes has two benefits. The active version of each mod travels with it. And TriOS writes `enabled_mods.json` itself, the same way it does for any other change.

On pull, the list is applied with the loop from `ModProfileManagerNotifier.activateModProfile`: `computeModProfileChanges`, then `changeActiveModVariant` for each change, then `validateModDependencies`. That loop is moved into a new method, `applyModList(List<ShallowModVariant>)`, and both callers use it. Mod sync doesn't set `activeModProfileId`. The active profile follows the new mod list, as it does after any manual change.

### 5. Sync order and the game-running rule

`_runSync` runs in this order:
1. Mod folders: pulls first, then pushes.
2. Reload the mod list (`reloadModVariants`) if anything was pulled.
3. The enabled-mods list.
4. Saves, as today.

Mods are pulled before the list so the list can turn on mods that just arrived. The list comes before saves so the save mod check compares against the final mods.

Steps 1–3 are skipped while the game is running. On Windows, the game holds mod files open.

### 6. Temp folder inside the mods folder

Pulled mods are extracted to `<mods folder>/.trios-sync-incoming/<folder>`, then renamed into place. Renaming on the same drive is instant, so a 500 MB mod isn't copied twice. Neither the game nor TriOS treats that folder as a mod, because each mod's `mod_info.json` sits two levels down. The folder is removed after each run. The zip is still copied to the local temp folder first, as for saves.

### 7. Backups

A mod folder that is replaced goes to `save_sync_backups/mods/<folder>/<time>_<reason>/`. It is moved by rename when the backups folder is on the same drive. Backups are not cleaned up automatically. The settings group shows the size of the backups folder next to "Open backups folder", because mod backups can grow large.

### 8. Missing mods and "Remove from sync folder"

A mod with a record that is missing on this PC gets the status "Missing on this PC". Two buttons:
- "Restore from sync folder": a normal pull.
- "Remove from sync folder": moves the zip and manifest to backups and drops the record.

Other PCs still have the mod and a record, so they see the sync folder copy as missing and push it again. That is the "never remove from other PCs" rule. To get rid of a mod everywhere, the user deletes it on each PC and then removes it from the sync folder.

### 9. Backend changes

`SaveSyncBackend` gains mod methods that mirror the save ones: `listMods`, `downloadModArchive`, `uploadMod`, `takeMod` (move zip and manifest to a local folder), `readEnabledModList`, and `writeEnabledModList`. The folder backend writes them in the layout from the spec. Cloud conflict copies under `mods/` are found and handled the same way as under `saves/`.

The layout version stays at 1. Older TriOS versions ignore the new files.

### 10. Settings, state, and UI

- `Settings.saveSyncModsEnabled` (default false).
- `SaveSyncState` gains `modRecords` (folder name → content hash, fingerprint, manifest) and `enabledModListRecord`. Old state files load with both empty.
- The Save Sync group shows a checkbox "Also sync the mods folder". When it's ticked, it adds a "Mods" subsection with a summary line, the enabled-mods list status (with a "Resolve..." button on conflict), and a collapsed list of mods. The list shows problems first: conflicts, missing, errors.
- The conflict dialog for a mod offers "Keep this PC's copy", "Keep synced copy", and "Skip for now". There is no "Keep both", because two folders of the same mod version would confuse TriOS and the game.
- The conflict dialog for the enabled-mods list shows the mods that differ, then "Keep this PC's list", "Keep synced list", and "Skip for now".
- Progress messages: "Reading mod 3 of 76: Nexerelin", "Writing mod 3 of 76: Nexerelin".

### 11. File list

New:
- `lib/save_sync/mod_sync_items.dart`: list mod folders, fingerprint, hash with `mod_info.json` names merged, the enabled-list hash.
- `lib/save_sync/models/mod_sync_manifest.dart` and `enabled_mod_list_manifest.dart`.
- `lib/save_sync/mod_sync_section.dart`: the Mods subsection.
- `test/save_sync/mod_sync_engine_test.dart`, `test/save_sync/mod_sync_items_test.dart`.

Changed:
- `save_sync_engine.dart` (mod and enabled-list pull and push; it stays free of UI code).
- `save_sync_manager.dart` (order, game-running rule, progress, dialogs).
- `save_sync_backend.dart`, `folder_save_sync_backend.dart`, `save_archiver.dart` (zip and extract with the `mod_info.json` rename).
- `save_sync_dialogs.dart`, `save_sync_settings_section.dart`, `models/save_sync_state.dart`.
- `lib/trios/settings/settings.dart`.
- `lib/mod_profiles/mod_profiles_manager.dart` (`applyModList` taken out of `activateModProfile`).
- Plus the regenerated `.mapper.dart` files.

### 12. Changes made during implementation

- **Separate engine and dialog files.** Mod steps are in `ModSyncEngine` (`mod_sync_engine.dart`) and the mod dialogs in `mod_sync_dialogs.dart`, instead of growing `SaveSyncEngine` and `save_sync_dialogs.dart`. Both manifests are in `models/mod_sync_manifest.dart`.
- **Stored hashes are kept apart from records.** `SaveSyncState.modHashes` holds each folder's fingerprint and hash, and `modRecords` holds the sync records. Mods are hashed before their first sync too, so the stored hash has to exist without a record.
- **No separate read for the list.** `listMods` returns the synced enabled-mods list with the mods. `ModSyncEngine.loadEnabledList` re-reads only the list after pulls.
- **Only the top-level `mod_info.json` is renamed.** A `mod_info.json` in a subfolder keeps its name. If a folder has more than one of the names at the top level, none is renamed.
- **The "ask first" dialog covers pulls too.** A second PC pulling 2 GB at launch is as slow as the first PC writing it. At launch, a mod sync that would copy more than 500 MB in either direction asks "Sync mods now?" with "Not now". "Sync now" never asks.
- **First list sync on a second PC asks.** A PC that has never synced the list, and whose own list differs, gets the "Enabled mods differ" dialog instead of having its list replaced. This follows the decision table (no record, both differ: conflict).
- **Mod sync waits for the mod list.** It skips the run with a note until TriOS has scanned the mods folder (`AppState.modsHaveLoaded`). Reading earlier would see no enabled mods and could push an empty list.
- **Mods are pulled, then pushed, then conflicts are asked.** After the game closes, only pushes run, as for saves.
- **The shared install code moved.** Saves and mods use one `_installFolder` helper in `save_archiver.dart`.
- **`applyModList` skips a reload.** Before, an early stop in `activateModProfile` (profile not found, or already active) still reloaded the mod list. It no longer does.

## Risks / Trade-offs

- **First sync is large.** About 1.9 GB is zipped and written, and the cloud client then uploads it. The first "Sync now" can take many minutes. The progress line shows which mod is being written, and the first sync is started with "Sync now", not at launch: if the first sync would happen at launch, TriOS asks "Write 76 mods (1.9 GB) to the sync folder now?" with "Not now".
- **Backups grow.** Each pulled update of a big mod keeps the old copy. The size is shown, and the user can empty the folder.
- **Long paths on Windows.** Some mods have deep folders. Extracting under `.trios-sync-incoming` adds about 22 characters. Extraction errors name the file that failed.
- **Letter case on Linux.** A mod that refers to its files with the wrong letter case works on Windows and fails on Linux. Mod sync can't fix that. It is the same as copying the mod by hand.
- **Mods that write into their own folder.** A few mods save settings inside their folder. Each such write makes the mod count as changed, and if both PCs write before syncing, the user gets a conflict for that mod.
- **Zip memory use.** Extraction streams each file, so it uses little memory. Zipping holds each file in memory about 3 times over, whether or not it compresses. Measured: a mod of three 200 MB files peaked at about 800 MB above normal. Files inside Starsector mods are usually a few MB, so this only matters for unusual mods. A streaming zip writer would need a new dependency.

## Open Questions

- Should very large mods (for example over 1 GB) be skipped with a warning instead of synced? Leaving them in for now.
