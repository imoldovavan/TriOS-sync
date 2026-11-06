# Mod sync: manual test plan

## Before you start

- **Your real mods folder is not used in Part 1.** Part 1 points TriOS at test folders. Don't launch the game during Part 1.
- Save sync must be set up first (see `openspec/changes/cloud-save-sync/manual-test-plan.md`, Part 1 setup). Mod sync uses the same sync folder.
- Backups of replaced mods are in `<TriOS config folder>/save_sync_backups/mods/`.

## Part 1: two simulated PCs on one PC

Switching TriOS's custom mods folder makes one PC behave like two. Records are kept per mods folder.

### Setup

1. Create `C:\trios-sync-test\pc A mods` and `C:\trios-sync-test\pc B mods`.
2. Copy three small mods from your real mods folder into `pc A mods`, for example `LazyLib`, `MagicLib`, and `Larger Zoom Out`. Copy, don't move.
3. Copy a second version of one of them into `pc A mods` too, if you have one (for example `Leading Pip` and `Leading Pip-1.10.2`).
4. Settings > Starsector: turn on the custom mods folder and set it to `pc A mods`. On the Mods page, turn on two of the mods.
5. Settings > Save Sync: tick "Also sync the mods folder".

| # | Steps | Expected |
|---|---|---|
| 1 | After setup, look at the Mods part of Save Sync. | Summary like "4 will be written to the sync folder". Enabled-mods list: "Changed on this PC; will be written to the sync folder". |
| 2 | Click "Sync now". | The status line shows "Writing mod 1 of 4: ..." while it runs. Then all mods are "Up to date", and the list is "Up to date". The sync folder has `mods/<folder>.zip` and `.manifest.json` for each, and `enabled-mods.json` at the root. No `.tmp` files. |
| 3 | Look inside a mod's `.manifest.json` in the sync folder. | It has the folder name, mod id, name, version, this PC's name, and `windows`. |
| 4 | Click "Check again" without changing anything. | Everything stays "Up to date", and the check is quick: unchanged mods are not read again. |
| 5 | Switch the custom mods folder to `pc B mods` (empty). | Mods show "Newer copy in the sync folder; will replace this PC's copy". The list shows "Changed on this PC and in the sync folder", because B has its own (empty) list. |
| 6 | Click "Sync now". | The mods are copied into `pc B mods` and appear on the Mods page. The enabled-mods dialog opens, listing the mods "Only in the synced list". Choose "Keep synced list". The same two mods are now turned on. Your chosen mod profile is unchanged. |
| 7 | Check `pc B mods` for the two versions of the same mod from step 3. | Only one of them is active; the other has `mod_info.json.disabled`. No folder named `.trios-sync-incoming` is left over. |
| 8 | On B, turn off one mod on the Mods page, then "Sync now". | "Wrote the enabled-mods list." Switch back to `pc A mods` and "Sync now": the same mod is turned off on A. |
| 9 | On A, switch the active version of the mod with two versions (Mods page), then "Check again". | Both of its folders stay "Up to date". Only the enabled-mods list shows as changed. |
| 10 | On A, edit a text file inside one mod (for example add a line to its `mod_info.json` description), then "Sync now". Switch to B and "Sync now". | B gets the change. The old copy is in `save_sync_backups/mods/<folder>/<time>_before-pull/`. |
| 11 | On B, edit a file in a mod and don't sync. Switch to A, edit the same mod differently, "Sync now". Switch to B and "Check again". | The mod shows "Changed on this PC and in the sync folder" with "Resolve...". The dialog offers "Keep this PC's copy", "Keep synced copy", and "Skip for now", and no "Keep both". |
| 12 | On A, delete one mod folder in File Explorer, then "Sync now". | Its status is "Missing on this PC; nothing was deleted", with "Restore from sync folder" and "Remove from sync folder". The sync folder still has it. Switch to B: B still has it, "Up to date". |
| 13 | On A, click "Restore from sync folder". | The mod is back on A and on the Mods page. |
| 14 | Delete it on A again, then click "Remove from sync folder". | The mod disappears from A's list. Its zip and manifest are in `save_sync_backups/mods/<folder>/<time>_removed-from-sync-folder/`. Switch to B: B shows it "Changed on this PC; will be written to the sync folder", and the next sync writes it back. |
| 15 | Copy `mods/<folder>.zip` to `mods/<folder> (SFConflict test 2026-11-06-10-00-00).zip`, then "Check again". | That mod shows "Cloud conflict copy found", and a "Move 1 mod conflict copies to backups" button appears. Clicking it moves the copy to backups. |
| 16 | Look at "Open backups folder". | The button shows the backups size, for example "Open backups folder (12.30 MB)". |
| 17 | Untick "Also sync the mods folder", then "Sync now". | Only saves are synced. Nothing in `pc A mods` or the sync folder's `mods` changes. |

## Part 2: your real mods folder, Windows ↔ Linux through SeaDrive

Do this only after Part 1 works. Turn off the custom mods folder so TriOS uses `<game folder>/mods`. Consider backing up your mods folder first (1.9 GB).

| # | Steps | Expected |
|---|---|---|
| 2.1 | Windows: tick "Also sync the mods folder" and click "Sync now". | All mods are written, with progress per mod. This can take many minutes. Wait for SeaDrive to finish uploading. |
| 2.2 | Linux: tick "Also sync the mods folder" and click Launch. | A dialog asks "Sync mods now?" with the number of mods and the size. "Sync mods now" copies them before the game starts; "Not now" launches without syncing mods. |
| 2.3 | Linux: after the pull, check the Mods page. | The same mods and versions are there. The enabled-mods dialog asks which list to keep the first time. |
| 2.4 | Linux: play with the synced mods and a synced save. | The save loads without missing-mod errors. |
| 2.5 | Linux: turn a mod on, quit the game. Windows: launch. | The mod is turned on on Windows before the game starts. |
| 2.6 | Start the game, then click "Sync now" in TriOS while it runs. | Sync now says the game is running; nothing in the mods folder changes. |
