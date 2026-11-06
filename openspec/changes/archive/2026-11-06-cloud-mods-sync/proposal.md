Status: needs-triage

## Why

Save sync moves a campaign between PCs, but the campaign only loads if both PCs have the same mods. Today the user has to copy mod folders by hand and turn on the same mods on each PC. A save that was played with a mod the other PC doesn't have can't be loaded there. TriOS already has a sync folder that a cloud client keeps identical across PCs, so it can keep the mods folder in step the same way it does saves.

## What Changes

- Add an opt-in **mod sync** setting: "Also sync the mods folder", under the Save Sync group. It is off by default. It uses the same sync folder as save sync and only works while save sync is on.
- Every folder in the mods folder is synced, including older versions of the same mod. Each mod folder is stored in the sync folder as one zip plus a manifest, like a save.
- **`enabled_mods.json`** (which mods are turned on) is synced too, together with which version of each mod is active. If both PCs changed it since the last sync, TriOS asks which list to keep.
- Mods are synced at the same moments as saves: before launch, after the game closes, and with "Sync now". Mods sync first, then the enabled-mods list, then saves. That way the save mod check compares against the mods that will actually be used.
- **Deletions are never passed between PCs.** A mod deleted on one PC stays on the other PCs and in the sync folder. The PC where it was deleted shows it as "Missing on this PC", with "Restore from sync folder" and "Remove from sync folder" buttons. Nothing happens unless the user clicks one.
- Change detection uses content hashes, as for saves. TriOS remembers each mod folder's hash with the folder's file count, total size and newest file time, so it only re-reads mod folders that changed. Hashing 2 GB of mods at every launch would be too slow.
- Which version of a mod is active doesn't count as a change to that mod's folder. TriOS switches versions by renaming `mod_info.json`, so the hash treats every name of that file as `mod_info.json`. The active version travels with the enabled-mods list instead.
- Mods are never read or written while the game is running.
- Replaced mod folders go to the backups folder, like replaced saves.
- The Save Sync settings group shows a mod list: name, version, status, and buttons, with a summary line such as "74 up to date, 2 will be written to the sync folder".

## Capabilities

### New Capabilities
- `mod-sync`: Opt-in syncing of the whole mods folder and the enabled-mods list through the save sync folder.

### Modified Capabilities
- `save-sync`: Pre-launch and post-exit sync also run mod sync, in the order mods, enabled-mods list, saves.

## Out of scope

- Downloading mods from their websites instead of copying them. Many mods have no direct download link, and the copy works for every mod.
- Choosing which mods to sync. Every mod folder is synced.
- Passing deletions between PCs.
- Syncing the game's own files, `saves/common`, or files in the mods folder that are not inside a mod folder (other than `enabled_mods.json`).
- Cleaning up old mod backups automatically.

## Impact

- **New files** in `lib/save_sync/`: mod listing and hashing, the enabled-mods list item, and a mod list for the settings group.
- **Modified files**: `save_sync_engine.dart`, `save_sync_manager.dart`, `folder_save_sync_backend.dart`, `save_sync_backend.dart`, `save_sync_settings_section.dart`, `save_sync_dialogs.dart`, `models/save_sync_state.dart`, and `lib/trios/settings/settings.dart` (with regenerated mappers).
- **Dependencies**: none new.
- **Disk and upload size**: the first sync writes every mod to the sync folder. For the maintainer's PC that is about 1.9 GB. After that only changed mods are written.
- **Tests**: new tests in `test/save_sync/` using temp folders only.

## Notes

### Decisions-so-far (2026-11-06)
- Deleted mods are never removed from other PCs.
- `enabled_mods.json` is synced like the mods; a conflict asks which list to keep.
- Mod sync is its own checkbox, separate from save sync, off by default.
