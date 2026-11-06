Each numbered section is one commit.

## 1. Models and settings

- [x] 1.1 `ModSyncManifest` and `EnabledModListManifest` in `lib/save_sync/models/`
- [x] 1.2 `SaveSyncState`: `modRecords` (hash, fingerprint, manifest) and `enabledModListRecord`; old state files load with both empty
- [x] 1.3 `Settings.saveSyncModsEnabled` (default false)
- [x] 1.4 Run `dart run build_runner build --delete-conflicting-outputs`

## 2. Listing, fingerprints, hashes

- [x] 2.1 `mod_sync_items.dart`: list folders in the mods folder (skip names starting with `.`), fingerprint (file count, total size, newest time)
- [x] 2.2 Content hash with the top-level `mod_info.json` name treated as `mod_info.json` (reusing the stored hash is in 5.1)
- [x] 2.3 Enabled-list hash from sorted `smolVariantId`s
- [x] 2.4 Tests: renaming `mod_info.json` doesn't change the hash; fingerprint changes on edit, add, delete; list order doesn't change the list hash

## 3. Zip and extract for mods

- [x] 3.1 `save_archiver.dart`: zip a mod folder with `mod_info.json` names merged
- [x] 3.2 Extract into `<mods>/.trios-sync-incoming/<folder>`, then rename `mod_info.json` to this PC's name, or to the disabled name if another folder of the same mod exists
- [x] 3.3 Check memory with a large mod: extraction streams; zipping holds each file in memory about 3 times (a 600 MB mod of 200 MB files peaked at about 800 MB extra)
- [x] 3.4 Tests: round trip; existing disabled `mod_info` name kept; new second version comes in disabled; failed extract leaves the mod unchanged

## 4. Backend

- [x] 4.1 `SaveSyncBackend`: `listMods` (also returns the synced list), `downloadModArchive`, `uploadMod`, `takeMod`, `writeEnabledModList`, `takeModConflictCopy`
- [x] 4.2 Folder backend: `mods/` layout, `.tmp` + rename, zip before manifest, conflict copies under `mods/`
- [x] 4.3 Tests with two temp sync folders

## 5. Engine

- [x] 5.1 Mod overview: per-folder status from local listing, manifests, and records
- [x] 5.2 Mod push, pull, restore, "Remove from sync folder", conflict choices (keep this PC's, keep synced, skip)
- [x] 5.3 Enabled-list overview, push, pull, and conflict choices
- [x] 5.4 Tests against temp folders: new PC gets every mod; deleting a mod on A leaves B's copy and shows "Missing on this PC" on A; version switch alone is not a change

## 6. Applying the enabled-mods list

- [x] 6.1 Move the apply loop out of `activateModProfile` into `applyModList`; `activateModProfile` calls it
- [x] 6.2 Enabled-list pull calls `applyModList` and reports mods that aren't installed

## 7. Manager

- [x] 7.1 `_runSync` order: mods, reload mod list, enabled-mods list, saves
- [x] 7.2 Skip mods and the list while the game runs, with a message
- [x] 7.3 Progress messages "Reading/Writing mod N of M: <name>"
- [x] 7.4 A launch that would copy more than 500 MB of mods (either direction) asks "Sync mods now?" with "Not now"

## 8. UI

- [x] 8.1 "Also sync the mods folder" checkbox under Save Sync
- [x] 8.2 Mods subsection: summary line, enabled-list status, collapsed mod list with problems first, row buttons
- [x] 8.3 Mod conflict dialog and enabled-list conflict dialog
- [x] 8.4 Backups folder size next to "Open backups folder"

## 9. Docs and checks

- [x] 9.1 Glossary entries in `CONTEXT.md`: mod sync, enabled-mods list
- [x] 9.2 Update the `save_sync/` line in `CLAUDE.md` and `AGENTS.md`
- [x] 9.3 `flutter analyze` and `flutter test`
- [x] 9.4 Manual test plan `openspec/changes/cloud-mods-sync/manual-test-plan.md`: two simulated PCs with two mods folders on one PC, then Windows ↔ Linux through SeaDrive
