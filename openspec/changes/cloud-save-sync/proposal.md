Status: needs-triage

## Why

Players who use more than one PC cannot continue the same Starsector campaign on both without copying save folders by hand. Copying by hand is easy to get wrong: an older save can overwrite a newer one, or a half-uploaded save can be loaded. Many players already run a cloud client (Seafile/SeaDrive, Dropbox, OneDrive, Google Drive, Syncthing) that keeps a folder identical across machines. TriOS already launches the game and knows when it closes, so it can move saves in and out of such a folder at the right moments.

## What Changes

- Add an opt-in **save sync** feature, off by default. The user picks a **sync folder** and which saves to sync.
- TriOS stores each synced save in the sync folder as one zip archive plus a small manifest file. The manifest records the save name, content hash, time, source machine and OS, game version, and mod list.
- **Before launch** (from TriOS's launch button): TriOS compares each selected save with the sync folder. If only the sync folder's copy changed, TriOS backs up the local save and replaces it with the synced one.
- **After the game closes**: TriOS archives each selected save that changed and writes it to the sync folder.
- **Lock file**: while the game runs, TriOS writes a lock file to the sync folder. At launch, a lock from another machine causes a warning that the user can override. Locks older than 24 hours are called out as probably stale.
- **Conflicts**: if both the local save and the synced save changed since the last sync, TriOS never picks one by itself. It asks: keep local, keep synced, or keep both. Whatever loses is backed up.
- **Cloud-client conflict copies** (for example Seafile's `name (SFConflict user 2026-11-04-15-20-00).zip`) are detected, shown as conflicts, and never treated as a normal save.
- **Mod check**: before replacing a local save with a synced one, TriOS compares the save's mod list with installed mods, using the same logic Mod Profiles uses for saves, and warns about missing or different mods.
- **Safety**: archives and manifests are written under a temporary name and then renamed. A local save is replaced only after the new copy is fully extracted and checked. Nothing is deleted outright; replaced data goes to a local backups folder.
- **Settings UI**: a "Save Sync" group on the Settings page with the enable switch, sync folder picker, list of saves with checkboxes and status, last sync time, a "Sync now" button, and clear error messages.
- The game-running check keeps checking every 5 seconds while TriOS is in the background, but only while a sync session is open, so TriOS notices the game closing without needing focus.
- The sync folder is accessed through a backend interface, so services with their own API can be added later.

## Capabilities

### New Capabilities
- `save-sync`: Opt-in syncing of selected Starsector saves through a folder kept in sync by an external cloud client.

### Modified Capabilities
- `game-running-check`: The polling loop keeps running while TriOS is unfocused when a save sync session is open.

## Out of scope (v1)

- TriOS doing any networking, accounts, or credentials itself.
- Syncing while the game is running.
- Passing deletions between machines. A save deleted on one machine is never deleted on another.
- Syncing `saves/common` (mod settings shared across saves).
- Pre-launch checks when the game is started outside TriOS. TriOS still writes the lock and pushes changes after the game closes, and says the pre-launch check was skipped.

## Impact

- **New folder**: `lib/save_sync/` (backend interface, folder backend, archiver, hashing, sync planner, manager, dialogs, settings section).
- **Modified files**: `lib/trios/settings/settings.dart` (+ regenerated mapper), `lib/trios/settings/settings_page.dart`, `lib/launcher/launcher.dart` (pre-launch hook), `lib/trios/app_state.dart` (polling while unfocused during a sync session).
- **Dependencies**: none new. Uses the existing `archive`, `crypto`, `uuid`, `path`, and `file_picker` packages.
- **Tests**: new `test/save_sync/` using temp directories only.

## Notes

### Decisions-so-far
- Background game check during a sync session: every 5 seconds (2026-11-04).
- Backups are not pruned automatically in v1.
- "Keep both" is unverified against the game code until checked.
- If TriOS closes while the game runs, the push happens on the next TriOS start.
- Glossary and CLAUDE.md/AGENTS.md updates are part of this change.
