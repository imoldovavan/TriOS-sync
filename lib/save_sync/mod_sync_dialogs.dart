import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/mod_sync_engine.dart';
import 'package:trios/utils/extensions.dart';

final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

String _formatDate(DateTime? date) =>
    date == null ? 'unknown' : _dateFormat.format(date.toLocal());

/// Like `bytesAsReadable`, with GB for large sizes such as a mods folder.
String modSyncSizeText(int bytes) => bytes >= 1024 * 1024 * 1024
    ? bytes.bytesAsReadableGB()
    : bytes.bytesAsReadable();

/// Asks which copy of a mod folder to keep when both changed. There is no
/// "keep both": two folders of the same mod version would confuse TriOS and
/// the game.
Future<ModSyncConflictChoice> showModSyncConflictDialog(
  BuildContext context,
  ModSyncItem item,
) async {
  final remote = item.remoteManifest;
  final result = await showDialog<ModSyncConflictChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Mod conflict: ${item.folderName}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text(
              'Files in this mod folder changed on this PC and in the sync '
              'folder since the last sync. Some mods save their settings '
              'inside their own folder, which causes this. Choose which copy '
              'to keep. The other copy is moved to backups, not deleted.',
            ),
            if (remote != null)
              Text(
                'Sync folder copy: ${remote.displayName} '
                '${remote.modVersion ?? ''}, from ${remote.machineName} '
                '(${remote.os}), ${_formatDate(remote.syncedAt)}.',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ModSyncConflictChoice.skip),
          child: const Text('Skip for now'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ModSyncConflictChoice.keepSynced),
          child: const Text('Keep synced copy'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ModSyncConflictChoice.keepLocal),
          child: const Text("Keep this PC's copy"),
        ),
      ],
    ),
  );
  return result ?? ModSyncConflictChoice.skip;
}

String _describe(ShallowModVariant mod) =>
    [mod.nameOrId, if (mod.version != null) mod.version.toString()].join(' ');

/// Asks which enabled-mods list to keep when both changed, showing the mods
/// that differ.
Future<ModSyncConflictChoice> showEnabledListConflictDialog(
  BuildContext context,
  EnabledModListItem item,
) async {
  final theme = Theme.of(context);
  final local = {for (final m in item.localMods) m.smolVariantId: m};
  final remote = {for (final m in item.remote?.mods ?? []) m.smolVariantId: m};
  final onlyHere = local.keys.where((id) => !remote.containsKey(id)).toList();
  final onlySynced = remote.keys.where((id) => !local.containsKey(id)).toList();

  Widget column(String title, List<ShallowModVariant> mods) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        if (mods.isEmpty) const Text('(none)'),
        for (final mod in mods.sortedByButBetter((m) => m.nameOrId))
          Text(_describe(mod)),
      ],
    ),
  );

  final result = await showDialog<ModSyncConflictChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enabled mods differ'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(
                item.record == null
                    ? 'This PC and the sync folder each have a list of enabled '
                          'mods, and they differ. Choose which list to use on '
                          'this PC from now on.'
                    : 'The enabled mods changed on this PC and in the sync '
                          'folder since the last sync. Choose which list to '
                          'keep.',
              ),
              if (item.remote case final remote?)
                Text(
                  'Synced list from ${remote.machineName} (${remote.os}), '
                  '${_formatDate(remote.syncedAt)}.',
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  column('Only on this PC', [
                    for (final id in onlyHere) local[id]!,
                  ]),
                  column('Only in the synced list', [
                    for (final id in onlySynced) remote[id]!,
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ModSyncConflictChoice.skip),
          child: const Text('Skip for now'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ModSyncConflictChoice.keepSynced),
          child: const Text('Keep synced list'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ModSyncConflictChoice.keepLocal),
          child: const Text("Keep this PC's list"),
        ),
      ],
    ),
  );
  return result ?? ModSyncConflictChoice.skip;
}

/// Asked at launch before a mod sync that moves a lot of data, such as the
/// first sync on a PC. Returns true to sync the mods now.
Future<bool> showLargeModSyncDialog(
  BuildContext context, {
  required int modCount,
  required int totalBytes,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sync mods now?'),
      content: SizedBox(
        width: 480,
        child: Text(
          'Mod sync will copy $modCount '
          '${modCount == 1 ? 'mod' : 'mods'} '
          '(${modSyncSizeText(totalBytes)}) between this PC and the sync '
          'folder. This can take many minutes. "Not now" launches the game '
          'without syncing mods; you can sync them later with "Sync now" in '
          'Settings > Save Sync.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sync mods now'),
        ),
      ],
    ),
  );
  return result ?? false;
}
