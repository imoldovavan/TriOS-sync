import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/save_sync/save_sync_manager.dart';
import 'package:trios/save_sync/saves_folder_check.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// The "Save Sync" group on the Settings page.
class SaveSyncSettingsSection extends ConsumerWidget {
  const SaveSyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = ref.watch(appSettings.select((s) => s.saveSyncEnabled));
    final folder = ref.watch(appSettings.select((s) => s.saveSyncFolder));
    final checksGameRunning = ref.watch(
      appSettings.select((s) => s.checkIfGameIsRunning),
    );
    final status = ref.watch(saveSyncProvider);
    final notifier = ref.read(saveSyncProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: const Text(
            'Continue the same campaign on more than one PC. TriOS copies the '
            'saves you pick into a folder that your cloud client (SeaDrive, '
            'Dropbox, OneDrive, Google Drive, Syncthing, ...) keeps in sync. '
            'Before launch, newer saves are taken from the folder; after the '
            'game closes, changed saves are written to it. TriOS itself '
            'uploads nothing.',
          ),
        ),
        CheckboxWithLabel(
          value: enabled,
          label: 'Sync saves through a folder',
          onChanged: (value) => ref
              .read(appSettings.notifier)
              .update((s) => s.copyWith(saveSyncEnabled: value ?? false)),
        ),
        if (enabled) ...[
          _SyncFolderRow(folderPath: folder?.path),
          if (!checksGameRunning)
            Row(
              spacing: 8,
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error),
                const Flexible(
                  child: Text(
                    '"Check if game is running" is off, so TriOS cannot tell '
                    'when the game closes. Saves are only written to the sync '
                    'folder on the next launch or with "Sync now".',
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(appSettings.notifier)
                      .update((s) => s.copyWith(checkIfGameIsRunning: true)),
                  child: const Text('Turn it on'),
                ),
              ],
            ),
          if (status.savesFolderMismatch case final mismatch?)
            _SavesFolderMismatchWarning(mismatch: mismatch)
          else if (!status.isActive && status.inactiveReason != null)
            Text(status.inactiveReason!),
          if (status.isActive) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: status.isBusy
                      ? null
                      : () => notifier.syncNow(context),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync now'),
                ),
                OutlinedButton.icon(
                  onPressed: status.isBusy ? null : notifier.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check again'),
                ),
                MovingTooltipWidget.text(
                  message:
                      'Anything save sync replaced is kept here:\n'
                      '${saveSyncBackupsFolder.path}',
                  child: OutlinedButton.icon(
                    onPressed: () {
                      saveSyncBackupsFolder.createSync(recursive: true);
                      saveSyncBackupsFolder.openInExplorer();
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open backups folder'),
                  ),
                ),
                if (status.overview?.conflictCopies.isNotEmpty == true)
                  MovingTooltipWidget.text(
                    message:
                        'Your cloud client made these copies because two PCs '
                        'changed the same file:\n'
                        '${status.overview!.conflictCopies.map((c) => c.fileName).join('\n')}',
                    child: OutlinedButton.icon(
                      onPressed: status.isBusy
                          ? null
                          : notifier.moveConflictCopiesToBackups,
                      icon: const Icon(Icons.call_split),
                      label: Text(
                        'Move ${status.overview!.conflictCopies.length} '
                        'conflict copies to backups',
                      ),
                    ),
                  ),
              ],
            ),
            if (status.busyMessage != null)
              Row(
                spacing: 8,
                children: [
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Text(status.busyMessage!),
                ],
              ),
            if (status.errorMessage != null)
              SelectableText(
                status.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (status.lastMessage != null)
              Text(
                [
                  status.lastMessage!,
                  if (status.lastRunAt != null)
                    '(${status.lastRunAt!.relativeTimestamp()})',
                ].join(' '),
              ),
            if (status.isSessionOpen)
              const Text(
                'Starsector is running. Changed saves are written to the sync '
                'folder after it closes.',
              ),
            if (status.overview != null)
              _SaveList(items: status.overview!.items, isBusy: status.isBusy),
          ],
        ],
      ],
    );
  }
}

class _SavesFolderMismatchWarning extends ConsumerWidget {
  const _SavesFolderMismatchWarning({required this.mismatch});

  final SavesFolderMismatch mismatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(Icons.warning, color: theme.colorScheme.error),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text(
                  'Save sync is paused: the game and TriOS use different '
                  'saves folders.',
                ),
                SelectableText(
                  'Game (from ${mismatch.vmparamsFile.path}):\n'
                  '    ${mismatch.gameSavesFolder.path}\n'
                  'TriOS:\n'
                  '    ${mismatch.triosSavesFolder.path}',
                ),
                MovingTooltipWidget.text(
                  message:
                      'Sets the custom saves folder in the Starsector section '
                      'above to the folder the game uses.',
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(appSettings.notifier)
                        .update(
                          (s) => s.copyWith(
                            useCustomSavesPath: true,
                            customSavesPath: mismatch.gameSavesFolder,
                          ),
                        ),
                    child: const Text("Use the game's saves folder"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncFolderRow extends ConsumerWidget {
  const _SyncFolderRow({required this.folderPath});

  final String? folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      spacing: 8,
      children: [
        const Text('Sync folder:'),
        Flexible(
          child: SelectableText(
            folderPath ?? 'Not set',
            style: TextStyle(
              color: folderPath == null
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        ),
        MovingTooltipWidget.text(
          message:
              'Pick the folder your cloud client syncs, e.g. a folder in your '
              'SeaDrive library. Use the same library on every PC; its path '
              'can differ between PCs.',
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await FilePicker.platform.getDirectoryPath(
                dialogTitle: 'Choose the save sync folder',
                initialDirectory: folderPath,
              );
              if (picked == null) return;
              ref
                  .read(appSettings.notifier)
                  .update(
                    (s) => s.copyWith(
                      saveSyncFolder: picked.toDirectory().normalize,
                    ),
                  );
            },
            icon: const Icon(Icons.folder),
            label: const Text('Choose...'),
          ),
        ),
      ],
    );
  }
}

class _SaveList extends ConsumerWidget {
  const _SaveList({required this.items, required this.isBusy});

  final List<SaveSyncItem> items;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Text('No saves found on this PC or in the sync folder.');
    }
    final notifier = ref.read(saveSyncProvider.notifier);
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const .symmetric(vertical: 4),
              child: Row(
                spacing: 8,
                children: [
                  Checkbox(
                    value: item.isSelected,
                    onChanged: isBusy
                        ? null
                        : (value) => notifier.setSaveSelected(
                            item.saveFolderName,
                            value ?? false,
                          ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.characterName.isEmpty
                              ? item.saveFolderName
                              : item.characterName,
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          item.saveFolderName,
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
                          style: TextStyle(color: _statusColor(theme, item)),
                        ),
                        if (item.problem != null)
                          Text(item.problem!, style: theme.textTheme.bodySmall),
                        if (_lastSyncText(item) case final text?)
                          Text(text, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (item.status == SaveSyncItemStatus.conflict)
                    OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => notifier.resolveConflict(context, item),
                      child: const Text('Resolve...'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _lastSyncText(SaveSyncItem item) {
    final record = item.record;
    final manifest = item.remoteManifest;
    if (record == null && manifest == null) return null;
    return [
      if (record != null)
        'Last synced here ${record.syncedAt.toLocal().relativeTimestamp()}.',
      if (manifest != null)
        'Folder copy from ${manifest.machineName} (${manifest.os}), '
            '${manifest.syncedAt.toLocal().relativeTimestamp()}.',
    ].join(' ');
  }

  Color? _statusColor(ThemeData theme, SaveSyncItem item) =>
      switch (item.status) {
        SaveSyncItemStatus.upToDate => theme.statusColors.success,
        SaveSyncItemStatus.willPush ||
        SaveSyncItemStatus.willPull ||
        SaveSyncItemStatus.waitingForCloud => theme.statusColors.info,
        SaveSyncItemStatus.missingLocally ||
        SaveSyncItemStatus.notFound => theme.statusColors.warning,
        SaveSyncItemStatus.conflict ||
        SaveSyncItemStatus.cloudConflictCopy ||
        SaveSyncItemStatus.nameProblem ||
        SaveSyncItemStatus.error => theme.colorScheme.error,
        SaveSyncItemStatus.notSelected => null,
      };
}
