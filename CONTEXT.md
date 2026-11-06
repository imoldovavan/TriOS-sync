# TriOS

An all-in-one Starsector launcher, mod manager, and toolkit. This glossary fixes the words the project uses for its own concepts, so the code, the UI, and conversations about them agree.

## Appearance

**Theme**:
A named set of colours someone picks to change how TriOS looks. It covers colours, the font, and the app name, but not the app icon.
_Avoid_: Skin, palette, colour scheme

**Built-in theme**:
A theme that ships inside TriOS. Replaced wholesale whenever TriOS updates.
_Avoid_: Default theme, stock theme

**User theme**:
A theme someone wrote themselves. Kept outside the install folder so a TriOS update never removes it.
_Avoid_: Custom theme, personal theme

**Theme id**:
What TriOS remembers when someone picks a theme. Separate from the theme's display name, so renaming a theme doesn't lose the selection.
_Avoid_: Theme key, theme name

**Theme modifiers**:
Settings that change TriOS's appearance regardless of which theme is active — the app icon, the app name, and the animated background.
_Avoid_: Theme overrides, appearance settings

## Mod updates

**Muted mod**:
A mod the user has told TriOS to stop mentioning. No version check runs for it at all, so no update ever appears for it anywhere — the Mods page, the Dashboard, or the Catalog. Stays that way until the user unmutes it.
_Avoid_: Ignored mod, silenced mod, hidden mod

**Muted update**:
One version of one mod that the user has told TriOS to stop mentioning. Version checks keep running, and the mod speaks up again by itself as soon as it advertises a different version. For skipping one broken release, as opposed to going quiet on the mod. Not the same as a muted mod.
_Avoid_: Skipped version, ignored update, dismissed update

## Mod sources

**Mod source**:
A record of where TriOS learned about a mod — the version checker, the catalog, a forum thread, or a download. Collected automatically as TriOS encounters the mod.
_Avoid_: Mod origin, mod link, mod record (that's the container holding all of a mod's sources)

**Source override**:
A value the user typed in to replace what a mod source collected automatically. Wins over the automatic value, field by field, and survives automatic re-collection.
_Avoid_: Manual link, user link, custom source

## Grids

**Frozen column**:
A column the user has told a grid to keep in view while the other columns scroll sideways. Frozen columns always sit leftmost, keeping their order relative to each other. Named after Excel's "freeze panes".
_Avoid_: Pinned column (pinning is the grids' word for rows held at the top), sticky column, locked column

## Save sync

**Save sync**:
Opt-in copying of chosen Starsector saves between PCs through a folder that a cloud client keeps the same on every PC. TriOS writes and reads the folder; the cloud client does the uploading.
_Avoid_: Cloud saves, save backup, save upload

**Sync folder**:
The folder save sync reads from and writes to. Kept in sync by something other than TriOS (SeaDrive, Dropbox, OneDrive, Google Drive, Syncthing). Its path can differ between PCs.
_Avoid_: Cloud folder, remote, sync target

**Sync session**:
The time from launching the game until TriOS has written its changed saves after the game closes. While a session is open, this PC's lock file sits in the sync folder.
_Avoid_: Play session, sync lock (the lock is the file, not the session)

**Sync record**:
What this PC remembers about a save from its last successful sync: the content hash both copies had then, and the manifest. Used to tell which side changed.
_Avoid_: Sync state, last-sync cache

**Mod sync**:
The opt-in part of save sync that also copies every folder in the mods folder, and the enabled-mods list, through the sync folder. Mods deleted on one PC are never deleted on the others.
_Avoid_: Mod upload, mod mirror, mod backup

**Enabled-mods list**:
In mod sync, the mods turned on and the active version of each, synced as `enabled-mods.json` in the sync folder. TriOS applies it the way it applies a mod profile, so it is not a copy of the game's `enabled_mods.json` file.
_Avoid_: Enabled mods file (that is the game's `enabled_mods.json`), mod profile (profiles are the user's named lists)
