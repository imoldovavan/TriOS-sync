## ADDED Requirements

### Requirement: Opt-in setting
Save sync SHALL be off by default. It SHALL do nothing until the user turns it on, chooses a sync folder, and selects at least one save. The sync folder SHALL be a user setting and never a hardcoded path.

#### Scenario: Fresh install
- **WHEN** TriOS starts with default settings
- **THEN** no file is read from or written to any sync folder, and launching the game behaves exactly as before

#### Scenario: Enabled without a folder
- **WHEN** save sync is turned on but no sync folder is set
- **THEN** the Save Sync settings group shows "Choose a sync folder to start syncing" and launching behaves as before

### Requirement: Sync folder layout
The sync folder SHALL contain:
- `trios-save-sync.json`: a marker file with the layout version.
- `saves/<save-folder-name>.zip`: one archive per synced save, holding the save folder's contents.
- `saves/<save-folder-name>.manifest.json`: one manifest per synced save.
- `locks/<machine-id>.lock.json`: one lock file per machine while that machine's game is running.

Each machine SHALL write only its own lock file, so two machines never edit the same lock file.

#### Scenario: First use of an empty folder
- **WHEN** the user picks an empty folder as the sync folder
- **THEN** TriOS creates the marker file and the `saves` and `locks` subfolders

#### Scenario: Folder from a newer TriOS
- **WHEN** the marker file has a layout version higher than this TriOS supports
- **THEN** TriOS does not read or write the folder and shows "This sync folder was written by a newer version of TriOS. Update TriOS on this PC."

### Requirement: Manifest contents
Each manifest SHALL be UTF-8 JSON with `\n` line endings and SHALL contain: layout version, save folder name, character name, a content hash of the save's files, a SHA-256 hash of the zip file, the save date from `descriptor.xml`, the time it was written to the sync folder (UTC), machine id, machine name, OS, game version, TriOS version, and the save's enabled mods (id, name, version).

#### Scenario: Paths inside an archive
- **WHEN** a save is archived on Windows
- **THEN** every path inside the zip uses `/` as the separator and is relative to the save folder

### Requirement: Change detection by content hash
TriOS SHALL decide whether a save changed by comparing content hashes, not file modification times. The content hash SHALL be a SHA-256 over every file's relative path (with `/` separators) and SHA-256 contents, sorted by path. For each selected save TriOS SHALL keep a sync record with the content hash and manifest from the last successful sync.

#### Scenario: Cloud client touches the modified time only
- **WHEN** a synced zip's modified time changes but its manifest's content hash matches the sync record
- **THEN** TriOS treats the save as unchanged

#### Scenario: Decision table
- **WHEN** TriOS compares a selected save's local copy (L), synced copy (S), and sync record (R)
- **THEN** it SHALL decide:
  - L and S both match R: up to date.
  - Only L differs from R: push.
  - Only S differs from R: pull.
  - Both differ from R and L equals S: up to date (record is updated).
  - Both differ from R and L differs from S: conflict.
  - No record, L exists, S missing: push.
  - No record, S exists, L missing: pull.
  - No record, both exist and equal: up to date (record is created).
  - No record, both exist and differ: conflict.
  - Record exists, L missing: "Missing on this PC"; nothing is pushed or deleted. A "Restore from sync folder" button pulls the synced copy back, with the same zip check and mod check as any pull. Nothing restores it automatically.
  - Record exists, S missing: push.

### Requirement: Pre-launch sync
When save sync is active and the user launches the game from TriOS, TriOS SHALL check for locks, then sync each selected save, before the existing launch precheck runs. A progress dialog SHALL show while this happens.

#### Scenario: Synced copy is newer
- **WHEN** the decision for a save is "pull"
- **THEN** TriOS runs the mod check, copies the zip to a local temp file, checks its SHA-256 against the manifest, extracts it to a temp folder, moves the current local save to backups, and moves the extracted folder into place

#### Scenario: Sync fails before launch
- **WHEN** any step of pre-launch sync fails
- **THEN** the local save is unchanged, and a dialog explains what failed with "Launch anyway" and "Cancel" buttons

### Requirement: Post-exit sync
When the game stops running and this machine has an open sync session, TriOS SHALL push every selected save whose decision is "push", then remove this machine's lock file. If a conflict is found, TriOS SHALL show the conflict dialog instead of pushing that save.

#### Scenario: Game closed while TriOS is in the background
- **WHEN** the game closes and TriOS is not focused
- **THEN** TriOS still notices within a few seconds and pushes changed saves

#### Scenario: TriOS was closed while the game ran
- **WHEN** TriOS starts, finds this machine's lock file, and the game is not running
- **THEN** TriOS runs post-exit sync and removes the lock

#### Scenario: Game started outside TriOS
- **WHEN** TriOS sees the game start without a TriOS launch
- **THEN** TriOS opens a sync session, writes the lock, shows "Starsector was started outside TriOS, so synced saves were not checked first", and pushes changes after the game closes

### Requirement: Lock files
A lock file SHALL contain machine id, machine name, OS, TriOS version, and start time (UTC). A lock is stale if it is older than 24 hours.

#### Scenario: Another machine's lock exists at launch
- **WHEN** the user launches and a lock from a different machine id exists
- **THEN** TriOS shows "Starsector may be running on <machine> (<OS>), started <relative time>. Its saves may not have reached this PC yet." with "Launch anyway" and "Cancel"

#### Scenario: Stale lock
- **WHEN** the other machine's lock is older than 24 hours
- **THEN** the same dialog adds "This lock is over a day old and is probably left over from a crash."

#### Scenario: Own leftover lock
- **WHEN** this machine's own lock exists at launch and the game is not running
- **THEN** TriOS runs post-exit sync first, then continues the launch without a warning

### Requirement: Conflict resolution
TriOS SHALL never resolve a conflict by itself. The conflict dialog SHALL show both copies' save date, character name, machine name, and sync time, and offer "Keep this PC's save", "Keep synced save", "Keep both", and "Skip for now".

#### Scenario: Keep this PC's save
- **WHEN** the user picks "Keep this PC's save"
- **THEN** the synced zip and manifest are copied to backups, and the local save is pushed

#### Scenario: Keep synced save
- **WHEN** the user picks "Keep synced save"
- **THEN** the local save is moved to backups, and the synced save is pulled

#### Scenario: Keep both
- **WHEN** the user picks "Keep both"
- **THEN** the synced save is extracted next to the local one under a new folder name ending in `_synced_<timestamp>`, which is not selected for sync, and the local save is pushed

#### Scenario: Skip
- **WHEN** the user picks "Skip for now"
- **THEN** nothing changes for that save, and its status stays "Conflict"

### Requirement: Cloud-client conflict copies
TriOS SHALL recognize conflict copies made by cloud clients in the sync folder: Seafile (`(SFConflict <user> <yyyy-MM-dd-HH-mm-ss>)`), Dropbox (`(<machine>'s conflicted copy <date>)`), and Syncthing (`.sync-conflict-<date>-<time>-<id>`). These files SHALL never be read as a normal save or manifest.

#### Scenario: Seafile conflict copy of a manifest
- **WHEN** `saves/save_foo_123.manifest (SFConflict ionut 2026-11-04-15-20-00).json` exists
- **THEN** save `save_foo_123` shows status "Cloud conflict copy found", sync for that save pauses, and the settings group offers "Move conflict copies to backups"

### Requirement: Saves folder matches the game
TriOS SHALL read `-Dcom.fs.starfarer.settings.paths.saves` from the vmparams file TriOS launches with, resolving a relative path against the game core folder. If it points to a different folder than the saves folder TriOS reads, save sync SHALL pause and SHALL not read or write any save.

#### Scenario: vmparams moves the saves folder
- **WHEN** vmparams sets the saves path to `D:\StarsectorSaves` and TriOS reads `<game folder>/saves`
- **THEN** the Save Sync group shows both paths and a "Use the game's saves folder" button, and the save list and sync buttons are hidden

#### Scenario: Use the game's saves folder
- **WHEN** the user clicks "Use the game's saves folder"
- **THEN** TriOS turns on its custom saves folder setting with the vmparams path, and save sync resumes

#### Scenario: Launch while the folders differ
- **WHEN** the user launches from TriOS while the folders differ
- **THEN** TriOS shows the message with "Launch anyway" and "Cancel"; "Launch anyway" starts the game without syncing, writing a lock, or pushing after exit

#### Scenario: vmparams sets no saves path
- **WHEN** vmparams has no saves path, or can't be read
- **THEN** save sync uses TriOS's saves folder as before

### Requirement: Mod check before pull
Before replacing a local save with a synced one, TriOS SHALL compare the manifest's mod list with the mods enabled on this PC using `ModProfileManagerNotifier.computeModProfileChanges`, the same way Mod Profiles compares a profile.

#### Scenario: Mods differ
- **WHEN** the synced save's mods differ from the enabled mods (mods to turn on or off, a different version, or mods not installed)
- **THEN** TriOS lists the differences by kind and offers "Pull, keep my mods" (or "Pull anyway" if nothing can be switched), "Skip this save", and, before a launch, "Cancel launch"

#### Scenario: Switch mods to match
- **WHEN** at least one difference can be fixed with installed mods and the user chooses "Pull and switch mods"
- **THEN** after the pull, TriOS stores the save's mod list in a mod profile named `Save sync: <character name>` (creating it, or replacing the list of an existing one with that name), switches to that profile the same way the Mod Profiles page does, and leaves the user's previous profile unchanged
- **AND** mods that are not installed are skipped and stay listed in the dialog

#### Scenario: Several saves want their mods
- **WHEN** "Pull and switch mods" was chosen for more than one save in one sync
- **THEN** after all pulls, TriOS asks which save's mods to use, with "Don't change mods" as an option

#### Scenario: Switching fails
- **WHEN** some mods are still different after switching
- **THEN** TriOS reports it as a sync error; the pulled save stays in place

### Requirement: Safe writes and backups
TriOS SHALL write each zip and manifest under a `.tmp` name in the sync folder and rename it when complete. The zip SHALL be renamed before the manifest. TriOS SHALL never delete save data outright. Any local save or synced file that is replaced SHALL first go to `<TriOS config folder>/save_sync_backups/<save-folder-name>/<timestamp>_<reason>/`.

#### Scenario: Zip is newer than its manifest
- **WHEN** another machine has renamed the new zip but not yet the manifest
- **THEN** the zip's SHA-256 does not match the manifest, and TriOS shows "Waiting for the cloud client to finish" instead of pulling

#### Scenario: Extraction fails
- **WHEN** extracting a pulled zip fails part-way
- **THEN** the temp folder is removed and the local save is unchanged

### Requirement: Slow and offline cloud drives
Reads from the sync folder SHALL fail with a clear message if no data arrives for 60 seconds. Pulled zips SHALL be copied to a local temp file before extraction.

#### Scenario: SeaDrive is offline
- **WHEN** a zip is a cloud-only placeholder and the cloud client cannot download it
- **THEN** TriOS reports "Could not read <file> from the sync folder. Your cloud client may be offline or still downloading it." and the local save is unchanged

### Requirement: Cross-platform names
TriOS SHALL refuse to sync a save whose folder name contains characters that are invalid on Windows (`<>:"/\|?*` or control characters), ends with a space or dot, or is a reserved Windows name. TriOS SHALL refuse to sync two saves whose names differ only by letter case.

#### Scenario: Case clash
- **WHEN** the sync folder holds `save_Foo_1.zip` and the local saves folder holds `save_foo_1`
- **THEN** both saves show "Name differs only by letter case from another save" and neither is synced

### Requirement: Status display
The Save Sync settings group SHALL show, per save: name, character, status (up to date, will push, will pull, conflict, missing on this PC, waiting for cloud client, error), last sync time, and which machine last wrote it. After a push it SHALL show "Synced to folder. Your cloud client uploads it to other PCs." Hovering a save SHALL show a popup with the details of this PC's copy and the sync folder's copy: save time, in-game date, character level, credits (read from `campaign.xml`), game version (the newest game version among the save's enabled mods, since saves don't record it), difficulty, iron mode, number of enabled mods, and who wrote the synced copy and when.
