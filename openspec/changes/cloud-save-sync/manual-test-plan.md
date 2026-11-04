# Save sync: manual test plan

## Before you start

- **Back up your real saves first.** Copy `<Starsector>/saves` to a folder outside the game folder.
- Use a throwaway campaign for every step that launches the game.
- Backups made by save sync are in `<TriOS config folder>/save_sync_backups/`. Settings > Save Sync > "Open backups folder" opens it.
- "Check again" re-reads both sides without changing anything. "Sync now" pulls, pushes, and asks about conflicts.

## Part 1: two simulated PCs on one PC

Records are kept per saves folder. Switching TriOS's custom saves folder makes one PC behave like two. Most steps don't need the game.

### Setup

1. Create `C:\trios-sync-test\sync`, `C:\trios-sync-test\pc A saves`, and `C:\trios-sync-test\pc B saves`. The spaces are deliberate.
2. Copy one save folder (for example `save_test_123`) into `pc A saves`.
3. Settings > Starsector: turn on the custom saves folder and set it to `pc A saves`.
4. Settings > Save Sync: tick "Sync saves through a folder", choose `C:\trios-sync-test\sync`, and tick the save.

| # | Steps | Expected |
|---|---|---|
| 1.1 | After setup, look at the save's status. | "Changed on this PC; will be written to the sync folder". |
| 1.2 | Click "Sync now". | Status "Up to date". The sync folder has `trios-save-sync.json`, `saves/save_test_123.zip`, `saves/save_test_123.manifest.json`, and no `.tmp` files. The manifest shows this PC's name and `windows`, and uses `\n` line endings. |
| 1.3 | Switch the custom saves folder to `pc B saves`. | "Newer copy in the sync folder; will replace this PC's copy". |
| 1.4 | Click "Sync now". | The save appears in `pc B saves`. Status "Up to date". Nothing in backups. |
| 1.5 | Add a file `notes.txt` inside the save in `pc B saves`, then "Check again". | "Changed on this PC". "Sync now" writes it, and the message says the cloud client uploads it. |
| 1.6 | Switch to `pc A saves`, then "Sync now". | A's copy now contains `notes.txt`. The old copy is in `save_sync_backups/save_test_123/<time>_before-pull/save_test_123/`. |
| 1.7 | Add `a.txt` to A's copy and run "Sync now". Switch to B, add `b.txt` to B's copy, then "Check again". | Status "Changed on this PC and in the sync folder" with a "Resolve..." button. Nothing changes on its own. |
| 1.8 | Click "Resolve..." and choose "Keep synced save". | B's copy now has `a.txt`. B's old copy (with `b.txt`) is in a `_conflict-local` backup. |
| 1.9 | Repeat 1.7, then choose "Keep this PC's save". | B's copy is pushed. The synced zip and manifest it replaced are in a `_conflict-synced` backup. |
| 1.10 | Repeat 1.7, then choose "Keep both". | A new folder `save_test_123_synced_<time>` appears in B's saves folder, unticked. The original save is pushed. |
| 1.11 | Repeat 1.7, then choose "Skip for now". | Nothing changes. Status stays "Changed on this PC and in the sync folder". |
| 1.12 | Change the modified time of every file in the sync folder (for example in PowerShell: `Get-ChildItem C:\trios-sync-test\sync -Recurse -File \| % { $_.LastWriteTime = '2030-01-01' }`), then "Check again". | Still "Up to date". |
| 1.13 | Copy `saves/save_test_123.zip` to `saves/save_test_123 (SFConflict test 2026-11-04-15-20-00).zip`, then "Check again". | Status "Cloud conflict copy found". A "Move 1 conflict copies to backups" button appears. Clicking it moves the copy to a `_cloud-conflict-copy` backup, and the status returns to normal. |
| 1.14 | Rename `saves/save_test_123.zip` to something else, then "Check again". Rename it back afterwards. | "Waiting for the cloud client to finish". |
| 1.15 | Copy a different save's zip over `saves/save_test_123.zip`. On the other "PC", where a pull is due, click "Sync now". | Error: the synced zip "does not match its manifest yet". The local save is unchanged. |
| 1.16 | In `saves/save_test_123.manifest.json`, add a fake mod to `mods`, e.g. `{"modId": "not_a_real_mod", "modName": "Fake", "smolVariantId": "x", "version": "1.0"}`. Then pull on the other "PC". | A dialog lists "Fake 1.0: not installed" with "Skip this save" and "Pull anyway". |
| 1.17 | Rename the whole sync folder, then "Check again". Rename it back. | Error: "The sync folder was not found ...". TriOS does not create the folder again. |
| 1.18 | Create `sync/locks/other-pc.lock.json` containing `{"machineId": "other-pc", "machineName": "LINUX-BOX", "os": "linux", "startedAt": "<now, UTC, e.g. 2026-11-04T15:00:00.000Z>"}`. Click Launch. | A warning names LINUX-BOX. "Cancel" stops the launch. |
| 1.19 | Set `startedAt` in that file to two days ago and launch again. | The same warning adds "over a day old ... probably left over from a crash". Delete the file afterwards. |
| 1.20 | Untick "Sync saves through a folder" and launch. | The launch behaves as before. No file in the sync folder changes. |

### With the game (real saves folder, throwaway campaign, after the backup above)

Turn off the custom saves folder. In Save Sync, tick only the throwaway save.

| # | Steps | Expected |
|---|---|---|
| 1.21 | Launch from TriOS. | A short "Checking synced saves..." dialog. `sync/locks/<id>.lock.json` appears. |
| 1.22 | Play, save, and quit to desktop **without clicking back into TriOS**. | Within about 5 seconds the zip in the sync folder updates. A message says the save was written. The lock file is gone. |
| 1.23 | Launch from TriOS, close TriOS while playing, quit the game, then start TriOS. | On start, TriOS writes the changed save and removes the lock. |
| 1.24 | With TriOS open, start the game from its own launcher. | A warning says the game was started outside TriOS. A lock appears. After you quit, the save is written. |
| 1.25 | Turn off Settings > "Check if game is running". | Save Sync shows a warning with a "Turn it on" button. |

## Part 2: Windows and Linux through SeaDrive

### Setup

- The same Seafile library is mounted on both PCs. On Windows it is `C:\Users\moljoh\seadrive_root\ionut_2\My Libraries\Starsector\trios-sync`. On Linux use the SeaDrive mount for the same library, e.g. `~/SeaDrive/My Libraries/Starsector/trios-sync`.
- Build and install this branch on both PCs.
- On both: enable save sync, pick the library folder, and tick the same throwaway campaign. After the first PC writes it, the second PC shows it in the list.
- After each write, wait until SeaDrive shows the files as uploaded before using the other PC.

| # | Steps | Expected |
|---|---|---|
| 2.1 | Windows: launch from TriOS, play, save, quit. | The message says the save was written to the folder and that the cloud client uploads it. SeaDrive uploads the zip, then the manifest. |
| 2.2 | Linux: open Settings > Save Sync, then click Launch. | Before upload finishes: "Waiting for the cloud client to finish", or a zip/manifest mismatch error; the local save is unchanged. After upload: the save is pulled before the game starts. If mods differ, the mod dialog appears. |
| 2.3 | Linux: play, save, quit. | The save is written. The manifest says `linux` and has `\n` line endings. Paths inside the zip use `/`. |
| 2.4 | Windows: launch. | The Linux save is pulled. The previous Windows copy is in a `_before-pull` backup. |
| 2.5 | Windows: start the game. Once SeaDrive has delivered the lock file to Linux, launch on Linux. | Linux warns that the game may be running on the Windows PC. Note how long SeaDrive took to deliver the lock. |
| 2.6 | Disconnect Windows from the network. Play and save on both PCs, then reconnect. | Seafile may create `(SFConflict ...)` copies. TriOS shows "Cloud conflict copy found". Move the copies to backups, then resolve the remaining conflict with the dialog. |
| 2.7 | Windows: make the library's files online-only in SeaDrive, disconnect the network, then launch. | Within about 60 seconds an error says the cloud client may be offline. The local save is unchanged. "Launch anyway" still starts the game. |
| 2.8 | Use a character name with spaces and non-English letters. | Syncs both ways with no errors. |
