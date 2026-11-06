import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_variant.dart';
import 'package:trios/save_sync/mod_sync_dialogs.dart';
import 'package:trios/save_sync/mod_sync_engine.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/save_sync/save_sync_manager.dart';
import 'package:trios/save_sync/save_sync_settings_section.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/trios_expansion_tile.dart';

/// The "Mods" part of the Save Sync group: a summary, the enabled-mods list,
/// and the list of mod folders with problems first.
class ModSyncSection extends ConsumerWidget {
  const ModSyncSection({
    super.key,
    required this.overview,
    required this.isBusy,
  });

  /// Null while the mods haven't been checked yet.
  final ModSyncOverview? overview;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = this.overview;
    if (overview == null) {
      return const Text('Mods have not been checked yet.');
    }
    final notifier = ref.read(saveSyncProvider.notifier);
    final list = overview.enabledList;
    final variantsByFolder = {
      for (final variant in ref.watch(AppState.modVariants).value ?? [])
        p.basename(variant.modFolder.path): variant,
    };
    final items = [...overview.items]
      ..sort((a, b) {
        final byProblem = _sortRank(a.status).compareTo(_sortRank(b.status));
        return byProblem != 0
            ? byProblem
            : a.folderName.toLowerCase().compareTo(b.folderName.toLowerCase());
      });

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(_summary(overview.items)),
          Row(
            spacing: 8,
            children: [
              const Text('Enabled-mods list:'),
              Flexible(
                child: Text(
                  [
                    list.status.label,
                    if (list.problem != null) list.problem!,
                    if (list.remote case final remote?)
                      '(synced list from ${remote.machineName}, '
                          '${remote.syncedAt.toLocal().relativeTimestamp()})',
                  ].join(' '),
                  style: TextStyle(
                    color: saveSyncStatusColor(theme, list.status),
                  ),
                ),
              ),
              if (list.status == SaveSyncItemStatus.conflict)
                OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => notifier.resolveEnabledListConflict(context),
                  child: const Text('Resolve...'),
                ),
            ],
          ),
          if (overview.conflictCopies.isNotEmpty)
            MovingTooltipWidget.text(
              message:
                  'Your cloud client made these copies because two PCs '
                  'changed the same file:\n'
                  '${overview.conflictCopies.map((c) => c.fileName).join('\n')}',
              child: OutlinedButton.icon(
                onPressed: isBusy
                    ? null
                    : notifier.moveModConflictCopiesToBackups,
                icon: const Icon(Icons.call_split),
                label: Text(
                  'Move ${overview.conflictCopies.length} mod conflict '
                  'copies to backups',
                ),
              ),
            ),
          if (items.isNotEmpty)
            TriOSExpansionTile(
              title: Text('Mods (${items.length})'),
              initiallyExpanded: items.any((i) => _sortRank(i.status) == 0),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  _ModRow(
                    item: item,
                    variant: variantsByFolder[item.folderName],
                    isBusy: isBusy,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// 0 for statuses that need the user, 1 for changes TriOS will make, 2 for
  /// up to date.
  static int _sortRank(SaveSyncItemStatus status) => switch (status) {
    SaveSyncItemStatus.upToDate => 2,
    SaveSyncItemStatus.willPush ||
    SaveSyncItemStatus.willPull ||
    SaveSyncItemStatus.waitingForCloud => 1,
    _ => 0,
  };

  static String _summary(List<ModSyncItem> items) {
    if (items.isEmpty) return 'No mods found on this PC or in the sync folder.';
    final counts = <SaveSyncItemStatus, int>{};
    for (final item in items) {
      counts[item.status] = (counts[item.status] ?? 0) + 1;
    }
    String part(SaveSyncItemStatus status, String text) =>
        '${counts[status]} $text';
    return [
      if (counts.containsKey(SaveSyncItemStatus.upToDate))
        part(SaveSyncItemStatus.upToDate, 'up to date'),
      if (counts.containsKey(SaveSyncItemStatus.willPush))
        part(SaveSyncItemStatus.willPush, 'will be written to the sync folder'),
      if (counts.containsKey(SaveSyncItemStatus.willPull))
        part(SaveSyncItemStatus.willPull, 'will be copied to this PC'),
      for (final status in counts.keys)
        if (_sortRank(status) == 0 ||
            status == SaveSyncItemStatus.waitingForCloud)
          '${counts[status]} "${status.label}"',
    ].join(', ');
  }
}

class _ModRow extends ConsumerWidget {
  const _ModRow({
    required this.item,
    required this.variant,
    required this.isBusy,
  });

  final ModSyncItem item;

  /// This PC's copy, if TriOS has loaded it.
  final ModVariant? variant;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(saveSyncProvider.notifier);
    final manifest = item.remoteManifest;
    final name =
        variant?.modInfo.nameOrId ?? manifest?.displayName ?? item.folderName;
    final version =
        variant?.modInfo.version?.toString() ?? manifest?.modVersion;
    final size = item.localSizeBytes ?? manifest?.archiveSizeBytes;

    return Padding(
      padding: const .symmetric(vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [name, ?version].join(' '),
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  [
                    item.folderName,
                    if (size != null) modSyncSizeText(size),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.status.label,
                  style: TextStyle(
                    color: saveSyncStatusColor(theme, item.status),
                  ),
                ),
                if (item.problem != null)
                  Text(item.problem!, style: theme.textTheme.bodySmall),
                if (manifest != null)
                  Text(
                    'Folder copy from ${manifest.machineName} '
                    '(${manifest.os}), '
                    '${manifest.syncedAt.toLocal().relativeTimestamp()}.',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (item.status == SaveSyncItemStatus.conflict)
            OutlinedButton(
              onPressed: isBusy
                  ? null
                  : () => notifier.resolveModConflict(context, item),
              child: const Text('Resolve...'),
            ),
          if (item.status == SaveSyncItemStatus.missingLocally &&
              manifest != null) ...[
            MovingTooltipWidget.text(
              message:
                  "Copies the mod from the sync folder back into this PC's "
                  'mods folder.',
              child: OutlinedButton(
                onPressed: isBusy ? null : () => notifier.restoreMod(item),
                child: const Text('Restore from sync folder'),
              ),
            ),
            MovingTooltipWidget.text(
              message:
                  'Moves the mod out of the sync folder into backups on this '
                  'PC. Other PCs keep their copy and will write it back.',
              child: OutlinedButton(
                onPressed: isBusy
                    ? null
                    : () => notifier.removeModFromSyncFolder(item),
                child: const Text('Remove from sync folder'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
