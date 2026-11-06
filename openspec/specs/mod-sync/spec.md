### Requirement: Opt-in setting
Mod sync SHALL be off by default. It SHALL do nothing unless save sync is on and the user ticks "Also sync the mods folder". Turning it off SHALL leave the mods folder and the sync folder unchanged.

#### Scenario: Save sync on, mod sync off
- **WHEN** save sync is on and mod sync is off
- **THEN** no file in the mods folder or in the sync folder's `mods` folder is read or written

### Requirement: What is synced
Mod sync SHALL sync every folder directly inside the mods folder, and `enabled_mods.json`. Other files directly inside the mods folder SHALL be ignored.

#### Scenario: Several versions of one mod
- **WHEN** the mods folder holds `Nexerelin` and `Nexerelin-0.12.1e`
- **THEN** both folders are synced as separate items

### Requirement: Sync folder layout
The sync folder SHALL hold:
- `mods/<mod-folder-name>.zip`: the mod folder's contents.
- `mods/<mod-folder-name>.manifest.json`: UTF-8 JSON with `\n` line endings, holding the folder name, mod id, mod name, mod version, content hash, zip SHA-256, zip size, sync time (UTC), machine id, machine name, and OS.
- `enabled-mods.json`: the synced enabled-mods list, with its content hash, sync time, machine id, machine name, and OS.

Writes SHALL use the same `.tmp` name and rename order as saves: zip first, then manifest.

#### Scenario: Older TriOS reads the folder
- **WHEN** a TriOS without mod sync uses the same sync folder
- **THEN** it ignores the `mods` folder and `enabled-mods.json`, and save sync keeps working

### Requirement: Mod change detection
TriOS SHALL decide whether a mod changed with the same content hash and decision table as saves, with one difference: if the folder's top level has exactly one file named `mod_info.json`, `mod_info.json.disabled`, `mod_info.json.disabled-by-TriOS`, or `mod_info.json.disabled-by-SMOL`, it SHALL be hashed and zipped as `mod_info.json`.

TriOS SHALL keep, per mod folder, the last content hash together with the folder's file count, total size, and newest file modified time. If those three are unchanged, TriOS SHALL reuse the stored hash instead of reading the files.

#### Scenario: Switching the active version
- **WHEN** TriOS switches a mod from version A to version B by renaming `mod_info.json` files
- **THEN** neither folder counts as changed

#### Scenario: Unchanged mods at launch
- **WHEN** no mod folder changed since the last sync
- **THEN** TriOS reads no file contents in the mods folder and only lists files

### Requirement: Pulling a mod
Pulling a mod SHALL follow the same steps as pulling a save: copy the zip to a local temp file, check its SHA-256 against the manifest, extract to a temp folder, move the current folder to backups, then move the new folder into place. If the mod folder already existed on this PC, its `mod_info.json` file SHALL keep this PC's name (enabled or disabled). After pulls, TriOS SHALL reload its mod list.

#### Scenario: New mod from another PC
- **WHEN** the sync folder has a mod this PC never had
- **THEN** TriOS extracts it into the mods folder and it appears on the Mods page

#### Scenario: Pull fails part-way
- **WHEN** extracting a mod fails
- **THEN** the temp folder is removed and this PC's copy of that mod is unchanged

### Requirement: Deletions are not passed on
A mod folder deleted on one PC SHALL NOT be deleted from any other PC or from the sync folder automatically.

#### Scenario: Mod deleted on this PC
- **WHEN** a mod synced before is missing from this PC's mods folder
- **THEN** its status is "Missing on this PC", nothing is pushed or deleted, and the row offers "Restore from sync folder" and "Remove from sync folder"

#### Scenario: Remove from sync folder
- **WHEN** the user clicks "Remove from sync folder"
- **THEN** the mod's zip and manifest are moved from the sync folder to this PC's backups, and the mod no longer appears in the list
- **AND** other PCs keep their copy, which they show as "Changed on this PC; will be written to the sync folder" until they push it again

### Requirement: Enabled-mods list
The synced enabled-mods list SHALL hold the enabled mod ids and, for each mod with more than one folder, which folder is active. Its content hash SHALL be computed from the sorted list, so a change in order alone is not a change. It SHALL follow the same decision table as saves.

On pull, TriOS SHALL apply the list the same way the Mod Profiles page applies a profile: turn mods on or off and switch versions. Mods in the list that aren't installed SHALL be skipped and reported.

#### Scenario: Turned a mod on, on the other PC
- **WHEN** another PC turned on a mod and pushed the list, and this PC's list didn't change
- **THEN** this PC turns the same mod on

#### Scenario: First sync on a second PC
- **WHEN** this PC has never synced the list and its list differs from the synced one
- **THEN** TriOS asks which list to keep, the same as when both changed

#### Scenario: Mods not loaded yet
- **WHEN** a sync runs before TriOS has read the mods folder
- **THEN** mod sync is skipped for that run with a note, so an empty list is never pushed

#### Scenario: Both PCs changed the list
- **WHEN** both lists changed since the last sync and differ
- **THEN** TriOS shows the differences and asks "Keep this PC's list" or "Keep synced list", with "Skip for now". It never picks one by itself.

### Requirement: Order and game running
Every sync SHALL run mods first, then the enabled-mods list, then saves. Mod sync SHALL NOT run while the game is running.

#### Scenario: Sync now while the game runs
- **WHEN** the user clicks "Sync now" while Starsector is running
- **THEN** nothing is synced, and TriOS says the game is running

#### Scenario: Large sync at launch
- **WHEN** a launch would copy more than 500 MB of mods in either direction
- **THEN** TriOS asks "Sync mods now?" with the number of mods and the size; "Not now" launches without syncing mods

### Requirement: Mod conflicts
If both copies of a mod changed since the last sync, TriOS SHALL ask "Keep this PC's copy", "Keep synced copy", or "Skip for now". Whatever loses SHALL go to backups.

### Requirement: Status display
The Save Sync group SHALL show a summary line for mods and a list with each mod's name, version, folder name, and status, using the same status labels as saves. While syncing, it SHALL show progress as "Writing mod 3 of 76: <name>" or "Reading mod 3 of 76: <name>".
