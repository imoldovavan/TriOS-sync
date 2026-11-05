import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/trios_radio_tile.dart';

final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

String _formatDate(DateTime? date) =>
    date == null ? 'unknown' : _dateFormat.format(date.toLocal());

/// A non-dismissible "working on it" dialog. Call [close] when done; other
/// dialogs can open on top of it in the meantime.
class SaveSyncProgressDialog {
  SaveSyncProgressDialog._(this._message);

  final ValueNotifier<String> _message;
  NavigatorState? _navigator;
  Route<void>? _route;

  static SaveSyncProgressDialog show(BuildContext context, String message) {
    final handle = SaveSyncProgressDialog._(ValueNotifier(message));
    handle._navigator = Navigator.of(context);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(),
              ),
              Flexible(
                child: ValueListenableBuilder(
                  valueListenable: handle._message,
                  builder: (context, message, _) => Text(message),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    handle._route = route;
    handle._navigator!.push(route);
    return handle;
  }

  void update(String message) => _message.value = message;

  void close() {
    final route = _route;
    if (route == null) return;
    _route = null;
    if (route.isActive) _navigator?.removeRoute(route);
  }
}

/// Warns that another machine may be running the game. Returns true to
/// launch anyway.
Future<bool> showSaveSyncLockWarningDialog(
  BuildContext context,
  List<SaveSyncLock> otherLocks,
) async {
  final now = DateTime.now().toUtc();
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Starsector may be running on another PC'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            for (final lock in otherLocks) ...[
              Text(
                'Starsector may be running on ${lock.machineName} '
                '(${lock.os}), started ${lock.startedAt.toLocal().relativeTimestamp()}. '
                'Its saves may not have reached this PC yet.',
              ),
              if (lock.isStale(now))
                Text(
                  'This lock is over a day old and is probably left over from a crash.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
            const Text(
              'If you play here now, the two PCs may end up with different '
              'versions of the same save.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Launch anyway'),
        ),
      ],
    ),
  );
  return result ?? false;
}

enum SaveSyncModCheckChoice {
  pullAndSwitchMods,
  pullKeepMods,
  skipSave,
  cancelLaunch,
}

bool _isMissing(ModChange change) =>
    change.changeType == ModChangeType.missingMod ||
    change.changeType == ModChangeType.missingVariant;

/// True if TriOS can turn mods on/off or switch versions for any of [changes].
/// Mods that aren't installed can't be fixed this way.
bool canSwitchModsFor(List<ModChange> changes) =>
    changes.any((c) => !_isMissing(c));

String _describeModChange(ModChange change) {
  final installedName = change.mod?.findFirstEnabledOrHighestVersion?.modInfo;
  final savedName =
      '${change.variantAsShallowMod?.nameOrId ?? change.modId} '
      '${change.variantAsShallowMod?.version ?? ''}';
  return switch (change.changeType) {
    ModChangeType.enable =>
      change.toVariant?.modInfo.formattedNameVersion ?? savedName,
    ModChangeType.disable =>
      change.fromVariant?.modInfo.formattedNameVersion ??
          installedName?.formattedNameVersion ??
          change.modId,
    ModChangeType.swap =>
      '${installedName?.nameOrId ?? change.modId}: '
          '${change.fromVariant?.modInfo.version ?? '?'} → '
          '${change.toVariant?.modInfo.version ?? '?'}',
    ModChangeType.missingMod => '$savedName (not installed)',
    ModChangeType.missingVariant => '$savedName (this version not installed)',
  };
}

/// Shows how the synced save's mods differ from the mods enabled here, and
/// offers to switch to them.
Future<SaveSyncModCheckChoice> showSaveSyncModCheckDialog(
  BuildContext context,
  SaveSyncItem item,
  List<ModChange> changes, {
  required bool isLaunch,
}) async {
  final theme = Theme.of(context);
  final canSwitch = canSwitchModsFor(changes);
  final hasMissing = changes.any(_isMissing);

  Widget section(String title, Iterable<ModChange> sectionChanges) {
    final list = sectionChanges.toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        for (final change in list) Text('• ${_describeModChange(change)}'),
      ],
    );
  }

  Iterable<ModChange> ofType(ModChangeType type) =>
      changes.where((c) => c.changeType == type);

  final result = await showDialog<SaveSyncModCheckChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Mods differ for ${item.characterName}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(
                'The synced copy of ${item.saveFolderName} was saved with '
                'different mods than the ones enabled on this PC.',
              ),
              section('Would be turned on', ofType(ModChangeType.enable)),
              section('Would be turned off', ofType(ModChangeType.disable)),
              section('Would switch version', ofType(ModChangeType.swap)),
              section(
                'Not installed on this PC (install these yourself)',
                changes.where(_isMissing),
              ),
              if (canSwitch)
                Text(
                  '"Pull and switch mods" saves the mod list as the profile '
                  '"${saveSyncModProfileName(item.characterName)}" and '
                  'switches to it. Your current profile is not changed.',
                ),
              if (hasMissing)
                Text(
                  'Loading the save without its mods may break it.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (isLaunch)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(SaveSyncModCheckChoice.cancelLaunch),
            child: const Text('Cancel launch'),
          ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SaveSyncModCheckChoice.skipSave),
          child: const Text('Skip this save'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SaveSyncModCheckChoice.pullKeepMods),
          child: Text(canSwitch ? 'Pull, keep my mods' : 'Pull anyway'),
        ),
        if (canSwitch)
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(SaveSyncModCheckChoice.pullAndSwitchMods),
            child: const Text('Pull and switch mods'),
          ),
      ],
    ),
  );
  return result ?? SaveSyncModCheckChoice.skipSave;
}

/// Name of the mod profile that holds a synced save's mod list.
String saveSyncModProfileName(String characterName) =>
    'Save sync: $characterName';

/// Asked when "switch mods" was chosen for more than one pulled save. Returns
/// the save whose mods to use, or null to leave mods as they are.
Future<SaveSyncItem?> showSaveSyncChooseModsDialog(
  BuildContext context,
  List<SaveSyncItem> items,
) async {
  var selected = items.first;
  return showDialog<SaveSyncItem>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Which save's mods should be used?"),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Text(
                'You chose to switch mods for more than one save. Only one '
                'set of mods can be enabled at a time. Pick the save you plan '
                'to play.',
              ),
              for (final item in items)
                TriOSRadioTile<SaveSyncItem>(
                  value: item,
                  groupValue: selected,
                  onChanged: (value) {
                    if (value != null) setState(() => selected = value);
                  },
                  title: Text(
                    '${item.characterName} (${item.saveFolderName})',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Don't change mods"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: const Text('Switch mods'),
          ),
        ],
      ),
    ),
  );
}

/// Asks which copy to keep when both changed. Never decides by itself.
Future<SaveSyncConflictChoice> showSaveSyncConflictDialog(
  BuildContext context,
  SaveSyncItem item,
) async {
  final local = item.localSave;
  final remote = item.remoteManifest;
  final theme = Theme.of(context);

  Widget column(String title, List<String> lines) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        for (final line in lines) Text(line),
      ],
    ),
  );

  final result = await showDialog<SaveSyncConflictChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Save conflict: ${item.saveFolderName}'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            const Text(
              'This save changed on this PC and in the sync folder since the '
              'last sync. Choose which copy to keep. The other copy is moved '
              'to backups, not deleted.',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                column('This PC', [
                  'Character: ${local?.characterName ?? 'unknown'}',
                  'Saved: ${_formatDate(local?.saveDate)}',
                ]),
                column('Sync folder', [
                  'Character: ${remote?.characterName ?? 'unknown'}',
                  'Saved: ${_formatDate(remote?.saveDate)}',
                  'From: ${remote?.machineName ?? 'unknown'} (${remote?.os ?? '?'})',
                  'Synced: ${_formatDate(remote?.syncedAt)}',
                ]),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SaveSyncConflictChoice.skip),
          child: const Text('Skip for now'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SaveSyncConflictChoice.keepBoth),
          child: const Text('Keep both'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SaveSyncConflictChoice.keepSynced),
          child: const Text('Keep synced save'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SaveSyncConflictChoice.keepLocal),
          child: const Text("Keep this PC's save"),
        ),
      ],
    ),
  );
  return result ?? SaveSyncConflictChoice.skip;
}

/// Explains a failed sync before launch. Returns true to launch anyway.
Future<bool> showSaveSyncLaunchErrorDialog(
  BuildContext context,
  String message,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Save sync failed'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              SelectableText(message),
              const Text(
                'Your local saves were not changed by the failed step.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Launch anyway'),
        ),
      ],
    ),
  );
  return result ?? false;
}
