import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/mod_profiles_manager.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/folder_save_sync_backend.dart';
import 'package:trios/save_sync/mod_sync_dialogs.dart';
import 'package:trios/save_sync/mod_sync_engine.dart';
import 'package:trios/save_sync/models/save_sync_state.dart';
import 'package:trios/save_sync/save_sync_backend.dart';
import 'package:trios/save_sync/save_sync_backups.dart';
import 'package:trios/save_sync/save_sync_dialogs.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/save_sync/saves_folder_check.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:uuid/uuid.dart';

/// Local backups of anything save sync replaced. Never inside the sync folder.
Directory get saveSyncBackupsFolder =>
    Directory(p.join(Constants.configDataFolderPath.path, 'save_sync_backups'));

const _cloudUploadNote =
    'Synced to folder. Your cloud client uploads it to other PCs.';

/// At launch, a mod sync that would copy more than this asks first.
const _largeModSyncBytes = 500 * 1024 * 1024;

/// A launch that hasn't started the game within this time closes its sync
/// session (e.g. the launch precheck was cancelled).
const _sessionStartTimeout = Duration(minutes: 3);

// ---------------------------------------------------------------------------
// Sync records file
// ---------------------------------------------------------------------------

final saveSyncStateProvider =
    AsyncNotifierProvider<SaveSyncStateNotifier, SaveSyncState>(
      SaveSyncStateNotifier.new,
    );

class SaveSyncStateFileManager
    extends GenericAsyncSettingsManager<SaveSyncState> {
  @override
  String get fileName => "trios_save_sync_state-v1.json";

  @override
  SaveSyncState Function(Map<String, dynamic> map) get fromMap =>
      (json) => SaveSyncStateMapper.fromMap(json);

  @override
  Map<String, dynamic> Function(SaveSyncState) get toMap =>
      (state) => state.toMap();

  @override
  FileFormat get fileFormat => FileFormat.json;
}

class SaveSyncStateNotifier
    extends GenericSettingsAsyncNotifier<SaveSyncState> {
  @override
  GenericAsyncSettingsManager<SaveSyncState> createSettingsManager() =>
      SaveSyncStateFileManager();

  @override
  SaveSyncState createDefaultState() => const SaveSyncState();
}

class _RiverpodSaveSyncStateStore implements SaveSyncStateStore {
  _RiverpodSaveSyncStateStore(this.ref);

  final Ref ref;

  @override
  Future<SaveSyncState> read() => ref.read(saveSyncStateProvider.future);

  @override
  Future<void> update(SaveSyncState Function(SaveSyncState) mutator) async {
    await ref.read(saveSyncStateProvider.future);
    await ref.read(saveSyncStateProvider.notifier).updateState(mutator);
  }
}

// ---------------------------------------------------------------------------
// Status shown in the UI
// ---------------------------------------------------------------------------

class SaveSyncStatus {
  const SaveSyncStatus({
    required this.isActive,
    this.inactiveReason,
    this.overview,
    this.busyMessage,
    this.errorMessage,
    this.lastMessage,
    this.lastRunAt,
    this.isSessionOpen = false,
    this.savesFolderMismatch,
    this.modsEnabled = false,
    this.modOverview,
  });

  /// False when sync is off or can't run (no folder, no saves folder, or
  /// TriOS and the game use different saves folders).
  final bool isActive;
  final String? inactiveReason;

  /// Set when the game's vmparams point to a different saves folder than the
  /// one TriOS reads. Sync is paused until they match.
  final SavesFolderMismatch? savesFolderMismatch;
  final SaveSyncOverview? overview;

  /// Set while a sync step is running.
  final String? busyMessage;
  final String? errorMessage;
  final String? lastMessage;
  final DateTime? lastRunAt;

  /// True between launch and game exit, while this PC's lock file exists.
  final bool isSessionOpen;

  /// "Also sync the mods folder" is ticked.
  final bool modsEnabled;

  /// Null until the mods were checked, or when mod sync is off.
  final ModSyncOverview? modOverview;

  bool get isBusy => busyMessage != null;

  SaveSyncStatus copyWith({
    SaveSyncOverview? overview,
    ModSyncOverview? modOverview,
    ValueGetter<String?>? busyMessage,
    ValueGetter<String?>? errorMessage,
    ValueGetter<String?>? lastMessage,
    DateTime? lastRunAt,
    bool? isSessionOpen,
  }) => SaveSyncStatus(
    isActive: isActive,
    inactiveReason: inactiveReason,
    overview: overview ?? this.overview,
    busyMessage: busyMessage != null ? busyMessage() : this.busyMessage,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    lastMessage: lastMessage != null ? lastMessage() : this.lastMessage,
    lastRunAt: lastRunAt ?? this.lastRunAt,
    isSessionOpen: isSessionOpen ?? this.isSessionOpen,
    savesFolderMismatch: savesFolderMismatch,
    modsEnabled: modsEnabled,
    modOverview: modOverview ?? this.modOverview,
  );
}

enum _SyncOutcome { done, cancelLaunch }

/// What one sync run did, for the status line.
class _SyncRunSummary {
  int pushed = 0;
  int pulled = 0;
  int modsPushed = 0;
  int modsPulled = 0;
  bool enabledListPushed = false;
  bool enabledListApplied = false;

  /// Set when mods were switched to match a pulled save.
  String? modProfileName;

  /// Shown after the counts, e.g. why mods were skipped.
  final notes = <String>[];
  final errors = <String>[];

  String describe() {
    String count(int n, String one, String many) => '$n ${n == 1 ? one : many}';
    final parts = [
      if (pushed > 0) 'Wrote ${count(pushed, 'save', 'saves')}',
      if (pulled > 0) 'pulled ${count(pulled, 'save', 'saves')}',
      if (modsPushed > 0) 'wrote ${count(modsPushed, 'mod', 'mods')}',
      if (modsPulled > 0) 'pulled ${count(modsPulled, 'mod', 'mods')}',
      if (enabledListPushed) 'wrote the enabled-mods list',
      if (enabledListApplied) 'applied the synced enabled-mods list',
    ];
    var text = parts.isEmpty
        ? 'Everything was already up to date.'
        : '${parts.join(', ')}.';
    if (parts.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
    if (modProfileName != null) {
      text += ' Switched mods to the profile "$modProfileName".';
    }
    if (notes.isNotEmpty) text += ' ${notes.join(' ')}';
    final wroteAnything = pushed > 0 || modsPushed > 0 || enabledListPushed;
    return wroteAnything ? '$text $_cloudUploadNote' : text;
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final saveSyncProvider = NotifierProvider<SaveSyncNotifier, SaveSyncStatus>(
  SaveSyncNotifier.new,
);

/// Decides when save sync runs (before launch, after the game exits, on
/// request) and asks the user when a decision is needed. The steps themselves
/// are in [SaveSyncEngine].
class SaveSyncNotifier extends Notifier<SaveSyncStatus> {
  final _runMutex = Mutex();
  bool _isSessionOpen = false;
  Timer? _sessionStartTimer;
  bool _checkedLeftoverLock = false;

  @override
  SaveSyncStatus build() {
    final enabled = ref.watch(appSettings.select((s) => s.saveSyncEnabled));
    final folder = ref.watch(appSettings.select((s) => s.saveSyncFolder));
    ref.watch(appSettings.select((s) => s.saveSyncSaveNames));
    final modsEnabled = ref.watch(
      appSettings.select((s) => s.saveSyncModsEnabled),
    );
    ref.watch(AppState.modsFolder);
    final savesFolder = ref.watch(AppState.savesFolder).value;

    ref.listen(AppState.isGameRunning, (previous, next) {
      final wasRunning = previous?.value == true;
      final isRunning = next.value == true;
      if (!wasRunning && isRunning) _onGameStarted();
      if (wasRunning && !isRunning) _onGameExited();
    });
    ref.onDispose(() => _sessionStartTimer?.cancel());

    if (!enabled) {
      return const SaveSyncStatus(
        isActive: false,
        inactiveReason: 'Save sync is off.',
      );
    }
    if (folder == null) {
      return const SaveSyncStatus(
        isActive: false,
        inactiveReason: 'Choose a sync folder to start syncing.',
      );
    }
    if (savesFolder == null) {
      return const SaveSyncStatus(
        isActive: false,
        inactiveReason:
            'TriOS could not find the Starsector saves folder. '
            'Set the game folder in the Starsector section above.',
      );
    }
    final mismatch = ref.watch(savesFolderMismatchProvider);
    if (!mismatch.hasValue && !mismatch.hasError) {
      // Don't touch any saves until we know TriOS reads the game's folder.
      return const SaveSyncStatus(
        isActive: false,
        inactiveReason: 'Checking the saves folder...',
      );
    }
    if (mismatch.value case final mismatch?) {
      return SaveSyncStatus(
        isActive: false,
        inactiveReason: mismatch.message,
        savesFolderMismatch: mismatch,
      );
    }

    Future.microtask(_refreshAndCheckLeftoverLock);
    return SaveSyncStatus(
      isActive: true,
      busyMessage: 'Checking saves...',
      isSessionOpen: _isSessionOpen,
      modsEnabled: modsEnabled,
    );
  }

  Set<String> get _selectedSaveNames =>
      ref.read(appSettings).saveSyncSaveNames.toSet();

  /// Re-reads both sides and updates the status. Changes nothing on disk.
  Future<void> refresh() async {
    if (!state.isActive) return;
    await _runMutex.protect(() async {
      state = state.copyWith(busyMessage: () => 'Checking saves...');
      try {
        final engine = await _createEngine();
        final overview = await engine.loadOverview(_selectedSaveNames);
        state = state.copyWith(overview: overview);
        await _refreshModOverview();
        state = state.copyWith(
          busyMessage: () => null,
          errorMessage: () => null,
        );
      } catch (e, st) {
        _setError(e, st);
      }
    });
  }

  /// Re-reads the mods and the enabled-mods list, if mod sync is on.
  Future<void> _refreshModOverview() async {
    if (!state.modsEnabled) return;
    final enabledMods = await _localEnabledMods();
    if (enabledMods == null) return;
    final engine = await _createModEngine();
    state = state.copyWith(
      modOverview: await engine.loadOverview(
        enabledMods,
        onProgress: (message) =>
            state = state.copyWith(busyMessage: () => message),
      ),
    );
  }

  void setSaveSelected(String saveFolderName, bool selected) {
    ref
        .read(appSettings.notifier)
        .update(
          (s) => s.copyWith(
            saveSyncSaveNames: selected
                ? {...s.saveSyncSaveNames, saveFolderName}.toList()
                : s.saveSyncSaveNames
                      .where((n) => n != saveFolderName)
                      .toList(),
          ),
        );
  }

  /// "Sync now" in settings: pull, push, and ask about conflicts.
  Future<void> syncNow(BuildContext context) async {
    if (!state.isActive) return;
    if (ref.read(AppState.isGameRunning).value == true) {
      state = state.copyWith(
        errorMessage: () =>
            'Starsector is running. Saves are synced after it closes.',
      );
      return;
    }
    await _runMutex.protect(() async {
      try {
        await _runSync(context, allowPull: true, isLaunch: false);
      } catch (e, st) {
        _setError(e, st);
      }
    });
  }

  /// Runs before every launch from TriOS. Returns false if the user cancelled
  /// the launch. When save sync is off, returns true straight away.
  Future<bool> prepareForLaunch(BuildContext context) async {
    if (state.savesFolderMismatch case final mismatch?) {
      // Launch anyway runs without a sync session: nothing is synced.
      return showSaveSyncLaunchErrorDialog(context, mismatch.message);
    }
    if (!state.isActive) return true;

    final progress = SaveSyncProgressDialog.show(
      context,
      'Checking synced saves...',
    );
    try {
      return await _runMutex.protect(() async {
        final engine = await _createEngine();
        await engine.backend.prepare();
        final locks = await engine.backend.readLocks();

        // This PC's lock with no game running: the last session ended without
        // syncing (e.g. TriOS was closed while playing). Push first.
        if (engine.hasOwnLock(locks)) {
          progress.update('Writing saves from the last session...');
          await _runSync(null, allowPull: false, isLaunch: false);
          await engine.removeLock();
        }

        final otherLocks = engine.otherMachinesLocks(locks);
        if (otherLocks.isNotEmpty) {
          if (!context.mounted) return false;
          if (!await showSaveSyncLockWarningDialog(context, otherLocks)) {
            return false;
          }
        }

        progress.update('Syncing saves...');
        final summary = _SyncRunSummary();
        if (!context.mounted) return false;
        final outcome = await _runSync(
          context,
          allowPull: true,
          isLaunch: true,
          summary: summary,
          onProgress: progress.update,
        );
        if (outcome == _SyncOutcome.cancelLaunch) return false;

        if (summary.errors.isNotEmpty) {
          if (!context.mounted) return false;
          if (!await showSaveSyncLaunchErrorDialog(
            context,
            summary.errors.join('\n\n'),
          )) {
            return false;
          }
        }

        await _openSession(engine);
        return true;
      });
    } on Exception catch (e, st) {
      _setError(e, st);
      progress.close();
      if (!context.mounted) return false;
      final launchAnyway = await showSaveSyncLaunchErrorDialog(
        context,
        _messageFor(e),
      );
      if (launchAnyway) {
        try {
          await _openSession(await _createEngine());
        } catch (e) {
          Fimber.w('Save sync: could not write lock file: $e');
        }
      }
      return launchAnyway;
    } finally {
      progress.close();
    }
  }

  /// Moves cloud-client conflict copies into local backups.
  Future<void> moveConflictCopiesToBackups() async {
    final copies = state.overview?.conflictCopies ?? [];
    if (copies.isEmpty) return;
    await _runMutex.protect(() async {
      try {
        state = state.copyWith(
          busyMessage: () => 'Moving conflict copies to backups...',
        );
        final engine = await _createEngine();
        await engine.takeConflictCopies(copies);
        state = state.copyWith(
          overview: await engine.loadOverview(_selectedSaveNames),
          busyMessage: () => null,
          errorMessage: () => null,
          lastMessage: () =>
              'Moved ${copies.length} conflict '
              '${copies.length == 1 ? 'copy' : 'copies'} to backups.',
        );
      } catch (e, st) {
        _setError(e, st);
      }
    });
  }

  /// Puts back a save that is missing on this PC, from the sync folder. Uses
  /// the same steps and mod check as a normal pull.
  Future<void> restoreSave(BuildContext context, SaveSyncItem item) async {
    if (ref.read(AppState.isGameRunning).value == true) {
      state = state.copyWith(
        errorMessage: () =>
            'Starsector is running. Close it before restoring a save.',
      );
      return;
    }
    await _runMutex.protect(() async {
      try {
        var switchMods = false;
        final changes = _modChanges(item);
        if (changes.isNotEmpty && context.mounted) {
          final choice = await showSaveSyncModCheckDialog(
            context,
            item,
            changes,
            isLaunch: false,
          );
          if (choice == SaveSyncModCheckChoice.skipSave) return;
          switchMods = choice == SaveSyncModCheckChoice.pullAndSwitchMods;
        }

        state = state.copyWith(
          busyMessage: () => 'Restoring ${item.saveFolderName}...',
        );
        final engine = await _createEngine();
        await engine.pull(item);
        final profileName = switchMods ? await _switchModsToSave(item) : null;
        state = state.copyWith(
          overview: await engine.loadOverview(_selectedSaveNames),
          busyMessage: () => null,
          errorMessage: () => null,
          lastMessage: () => [
            'Restored ${item.saveFolderName} from the sync folder.',
            if (profileName != null)
              'Switched mods to the profile "$profileName".',
          ].join(' '),
          lastRunAt: DateTime.now(),
        );
      } catch (e, st) {
        _setError(e, st);
      }
    });
  }

  /// Turns "Also sync the mods folder" on or off.
  void setModsEnabled(bool enabled) => ref
      .read(appSettings.notifier)
      .update((s) => s.copyWith(saveSyncModsEnabled: enabled));

  /// Puts back a mod that is missing on this PC, from the sync folder.
  Future<void> restoreMod(ModSyncItem item) =>
      _modAction('Restoring the mod ${item.folderName}...', (engine) async {
        await engine.pull(item);
        await ref.read(AppState.modVariants.notifier).reloadModVariants();
        return 'Restored the mod ${item.folderName} from the sync folder.';
      });

  /// Moves a mod's zip and manifest out of the sync folder into backups.
  /// Other PCs that still have the mod write it back.
  Future<void> removeModFromSyncFolder(ModSyncItem item) => _modAction(
    'Removing the mod ${item.folderName} from the sync folder...',
    (engine) async {
      await engine.removeFromSyncFolder(item);
      return 'Removed the mod ${item.folderName} from the sync folder. Other '
          'PCs that still have it will write it back.';
    },
  );

  /// Opens the conflict dialog for one mod from the settings list.
  Future<void> resolveModConflict(
    BuildContext context,
    ModSyncItem item,
  ) async {
    final choice = await showModSyncConflictDialog(context, item);
    if (choice == ModSyncConflictChoice.skip) return;
    await _modAction('Resolving conflict...', (engine) async {
      await engine.resolveConflict(item, choice);
      if (choice == ModSyncConflictChoice.keepSynced) {
        await ref.read(AppState.modVariants.notifier).reloadModVariants();
      }
      return null;
    });
  }

  /// Opens the conflict dialog for the enabled-mods list.
  Future<void> resolveEnabledListConflict(BuildContext context) async {
    final list = state.modOverview?.enabledList;
    if (list == null) return;
    final choice = await showEnabledListConflictDialog(context, list);
    if (choice == ModSyncConflictChoice.skip) return;
    await _modAction('Resolving conflict...', (engine) async {
      final summary = _SyncRunSummary();
      if (choice == ModSyncConflictChoice.keepLocal) {
        await engine.keepLocalEnabledList(list);
        summary.enabledListPushed = true;
      } else {
        await _applyEnabledList(engine, list, summary);
      }
      if (summary.errors.isNotEmpty) {
        throw SaveSyncException(summary.errors.join('\n'));
      }
      return summary.describe();
    });
  }

  /// Moves cloud-client conflict copies of mods into local backups.
  Future<void> moveModConflictCopiesToBackups() async {
    final copies = state.modOverview?.conflictCopies ?? [];
    if (copies.isEmpty) return;
    await _modAction('Moving conflict copies to backups...', (engine) async {
      await engine.takeConflictCopies(copies);
      return 'Moved ${copies.length} conflict '
          '${copies.length == 1 ? 'copy' : 'copies'} to backups.';
    });
  }

  /// Runs one mod action from the settings group, then re-reads the mods.
  /// [action] returns the message to show, or null.
  Future<void> _modAction(
    String busyMessage,
    Future<String?> Function(ModSyncEngine engine) action,
  ) async {
    if (ref.read(AppState.isGameRunning).value == true) {
      state = state.copyWith(
        errorMessage: () =>
            'Starsector is running. Mods are synced when it '
            'is not running.',
      );
      return;
    }
    await _runMutex.protect(() async {
      try {
        state = state.copyWith(busyMessage: () => busyMessage);
        final message = await action(await _createModEngine());
        await _refreshModOverview();
        state = state.copyWith(
          busyMessage: () => null,
          errorMessage: () => null,
          lastMessage: message == null ? null : () => message,
          lastRunAt: DateTime.now(),
        );
      } catch (e, st) {
        _setError(e, st);
      }
    });
  }

  /// Opens the conflict dialog for one save from the settings list.
  Future<void> resolveConflict(BuildContext context, SaveSyncItem item) async {
    final choice = await showSaveSyncConflictDialog(context, item);
    if (choice == SaveSyncConflictChoice.skip) return;
    await _runMutex.protect(() async {
      try {
        state = state.copyWith(busyMessage: () => 'Resolving conflict...');
        final engine = await _createEngine();
        await engine.resolveConflict(item, choice);
        state = state.copyWith(
          overview: await engine.loadOverview(_selectedSaveNames),
          busyMessage: () => null,
          errorMessage: () => null,
          lastRunAt: DateTime.now(),
        );
      } catch (e, st) {
        _setError(e, st);
      }
    });
  }

  // -------------------------------------------------------------------------

  /// Syncs every selected save. Conflicts and mod mismatches are asked about
  /// only when a [context] is given; otherwise they are left for later.
  /// Errors for one save don't stop the others; they go into [summary].
  Future<_SyncOutcome> _runSync(
    BuildContext? context, {
    required bool allowPull,
    required bool isLaunch,
    _SyncRunSummary? summary,
    void Function(String message)? onProgress,
  }) async {
    summary ??= _SyncRunSummary();
    void progress(String message) {
      state = state.copyWith(busyMessage: () => message);
      onProgress?.call(message);
    }

    // Mods first, then the enabled-mods list, then saves: the save mod check
    // should compare against the mods this PC will actually use.
    if (state.modsEnabled) {
      try {
        await _runModSync(
          context,
          allowPull: allowPull,
          isLaunch: isLaunch,
          summary: summary,
          progress: progress,
        );
      } on Exception catch (e) {
        Fimber.w('Mod sync failed: $e');
        summary.errors.add('Mods: ${_messageFor(e)}');
      }
    }

    progress('Syncing saves...');
    final engine = await _createEngine();
    final overview = await engine.loadOverview(_selectedSaveNames);
    // Pulled saves the user chose "switch mods" for. Applied once at the end,
    // since only one set of mods can be enabled.
    final switchModsFor = <SaveSyncItem>[];

    for (final item in overview.items.where((i) => i.isSelected)) {
      try {
        switch (item.status) {
          case SaveSyncItemStatus.upToDate:
            await engine.recordUpToDate(item);
          case SaveSyncItemStatus.willPush:
            state = state.copyWith(
              busyMessage: () => 'Writing ${item.saveFolderName}...',
            );
            await engine.push(item.saveFolderName);
            summary.pushed++;
          case SaveSyncItemStatus.willPull:
            if (!allowPull) continue;
            var switchMods = false;
            if (context != null && context.mounted) {
              final changes = _modChanges(item);
              if (changes.isNotEmpty) {
                final choice = await showSaveSyncModCheckDialog(
                  context,
                  item,
                  changes,
                  isLaunch: isLaunch,
                );
                if (choice == SaveSyncModCheckChoice.cancelLaunch) {
                  return _SyncOutcome.cancelLaunch;
                }
                if (choice == SaveSyncModCheckChoice.skipSave) continue;
                switchMods = choice == SaveSyncModCheckChoice.pullAndSwitchMods;
              }
            }
            state = state.copyWith(
              busyMessage: () => 'Pulling ${item.saveFolderName}...',
            );
            await engine.pull(item);
            summary.pulled++;
            if (switchMods) switchModsFor.add(item);
          case SaveSyncItemStatus.conflict:
            if (context == null || !context.mounted) continue;
            final choice = await showSaveSyncConflictDialog(context, item);
            await engine.resolveConflict(item, choice);
          default:
            break;
        }
      } on Exception catch (e) {
        Fimber.w('Save sync: ${item.saveFolderName} failed: $e');
        summary.errors.add('${item.saveFolderName}: ${_messageFor(e)}');
      }
    }

    if (switchModsFor.isNotEmpty && context != null && context.mounted) {
      final chosen = switchModsFor.length == 1
          ? switchModsFor.single
          : await showSaveSyncChooseModsDialog(context, switchModsFor);
      if (chosen != null) {
        state = state.copyWith(
          busyMessage: () => 'Switching mods for ${chosen.characterName}...',
        );
        try {
          summary.modProfileName = await _switchModsToSave(chosen);
        } on Exception catch (e) {
          Fimber.w('Save sync: switching mods failed: $e');
          summary.errors.add('Switching mods: ${_messageFor(e)}');
        }
      }
    }

    state = state.copyWith(
      overview: await engine.loadOverview(_selectedSaveNames),
    );
    try {
      await _refreshModOverview();
    } on Exception catch (e) {
      summary.errors.add('Mods: ${_messageFor(e)}');
    }
    state = state.copyWith(
      busyMessage: () => null,
      errorMessage: () =>
          summary!.errors.isEmpty ? null : summary.errors.join('\n'),
      lastMessage: summary.describe,
      lastRunAt: DateTime.now(),
    );
    return _SyncOutcome.done;
  }

  /// Syncs every mod folder, then the enabled-mods list. Pulls only when
  /// [allowPull]. Conflicts are asked about only when a [context] is given.
  /// Errors for one mod don't stop the others; they go into [summary].
  Future<void> _runModSync(
    BuildContext? context, {
    required bool allowPull,
    required bool isLaunch,
    required _SyncRunSummary summary,
    required void Function(String message) progress,
  }) async {
    if (ref.read(AppState.isGameRunning).value == true) {
      summary.notes.add('Mods are synced when the game is not running.');
      return;
    }

    final enabledMods = await _localEnabledMods();
    if (enabledMods == null) {
      summary.notes.add(
        'Mods were not synced: TriOS was still reading the mods folder.',
      );
      return;
    }

    final engine = await _createModEngine();
    final overview = await engine.loadOverview(
      enabledMods,
      onProgress: progress,
    );
    final toPull = allowPull
        ? overview.items
              .where((i) => i.status == SaveSyncItemStatus.willPull)
              .toList()
        : <ModSyncItem>[];
    final toPush = overview.items
        .where((i) => i.status == SaveSyncItemStatus.willPush)
        .toList();

    final bytesToCopy =
        toPull.map((i) => i.remoteManifest?.archiveSizeBytes ?? 0).sum +
        toPush.map((i) => i.localSizeBytes ?? 0).sum;
    if (isLaunch && bytesToCopy > _largeModSyncBytes) {
      if (context == null || !context.mounted) return;
      final syncNow = await showLargeModSyncDialog(
        context,
        modCount: toPull.length + toPush.length,
        totalBytes: bytesToCopy,
      );
      if (!syncNow) {
        summary.notes.add('Mods were not synced this time.');
        return;
      }
    }

    // Pulls before pushes, so a mod both sides need is settled first.
    for (final (index, item) in toPull.indexed) {
      progress(
        'Pulling mod ${index + 1} of ${toPull.length}: '
        '${item.remoteManifest?.displayName ?? item.folderName}',
      );
      try {
        await engine.pull(item);
        summary.modsPulled++;
      } on Exception catch (e) {
        Fimber.w('Mod sync: ${item.folderName} failed: $e');
        summary.errors.add('Mod ${item.folderName}: ${_messageFor(e)}');
      }
    }
    for (final (index, item) in toPush.indexed) {
      progress(
        'Writing mod ${index + 1} of ${toPush.length}: ${item.folderName}',
      );
      try {
        await engine.push(item.folderName);
        summary.modsPushed++;
      } on Exception catch (e) {
        Fimber.w('Mod sync: ${item.folderName} failed: $e');
        summary.errors.add('Mod ${item.folderName}: ${_messageFor(e)}');
      }
    }
    for (final item in overview.items) {
      try {
        switch (item.status) {
          case SaveSyncItemStatus.upToDate:
            await engine.recordUpToDate(item);
          case SaveSyncItemStatus.conflict:
            if (context == null || !context.mounted) continue;
            final choice = await showModSyncConflictDialog(context, item);
            if (choice == ModSyncConflictChoice.keepSynced && !allowPull) {
              continue;
            }
            progress('Resolving conflict for the mod ${item.folderName}...');
            await engine.resolveConflict(item, choice);
          default:
            break;
        }
      } on Exception catch (e) {
        Fimber.w('Mod sync: ${item.folderName} failed: $e');
        summary.errors.add('Mod ${item.folderName}: ${_messageFor(e)}');
      }
    }

    if (summary.modsPulled > 0) {
      progress('Reloading mods...');
      await ref.read(AppState.modVariants.notifier).reloadModVariants();
    }

    progress('Syncing the enabled-mods list...');
    final enabledAfterPulls = await _localEnabledMods();
    if (enabledAfterPulls == null) return;
    final list = await engine.loadEnabledList(enabledAfterPulls);
    try {
      switch (list.status) {
        case SaveSyncItemStatus.upToDate:
          await engine.recordEnabledListSynced(list);
        case SaveSyncItemStatus.willPush:
          await engine.pushEnabledList(list.localMods);
          summary.enabledListPushed = true;
        case SaveSyncItemStatus.willPull:
          if (!allowPull) break;
          await _applyEnabledList(engine, list, summary);
        case SaveSyncItemStatus.conflict:
          if (context == null || !context.mounted) break;
          final choice = await showEnabledListConflictDialog(context, list);
          switch (choice) {
            case ModSyncConflictChoice.keepLocal:
              await engine.keepLocalEnabledList(list);
              summary.enabledListPushed = true;
            case ModSyncConflictChoice.keepSynced:
              if (allowPull) await _applyEnabledList(engine, list, summary);
            case ModSyncConflictChoice.skip:
              break;
          }
        default:
          break;
      }
    } on Exception catch (e) {
      Fimber.w('Mod sync: enabled-mods list failed: $e');
      summary.errors.add('Enabled-mods list: ${_messageFor(e)}');
    }
  }

  /// Turns mods on and off to match the synced list, the same way activating
  /// a mod profile does, without changing which profile is chosen. Mods that
  /// aren't installed here are reported as an error.
  Future<void> _applyEnabledList(
    ModSyncEngine engine,
    EnabledModListItem list,
    _SyncRunSummary summary,
  ) async {
    final mods = list.remote?.mods ?? [];
    await ref
        .read(modProfilesProvider.notifier)
        .applyModList(mods, description: 'the synced enabled-mods list');
    await engine.recordEnabledListSynced(list);
    summary.enabledListApplied = true;

    final missing = _modChangesFor(mods)
        .where((c) => c.changeType == ModChangeType.missingMod)
        .toList();
    if (missing.isNotEmpty) {
      summary.errors.add(
        'Enabled-mods list: these mods are not installed on this PC: '
        '${missing.map((c) => c.variantAsShallowMod?.nameOrId ?? c.modId).join(', ')}.',
      );
    }
  }

  Future<void> _openSession(SaveSyncEngine engine) async {
    await engine.writeLock();
    _setSessionOpen(true);
    _sessionStartTimer?.cancel();
    _sessionStartTimer = Timer(_sessionStartTimeout, () {
      if (ref.read(AppState.isGameRunning).value != true) {
        Fimber.i('Save sync: the game did not start; closing the session.');
        _closeSession();
      }
    });
  }

  Future<void> _closeSession() async {
    _sessionStartTimer?.cancel();
    _setSessionOpen(false);
    try {
      await (await _createEngine()).removeLock();
    } catch (e) {
      Fimber.w('Save sync: could not remove lock file: $e');
    }
  }

  void _setSessionOpen(bool isOpen) {
    _isSessionOpen = isOpen;
    ref.read(AppState.keepCheckingGameWhileUnfocused.notifier).state = isOpen;
    state = state.copyWith(isSessionOpen: isOpen);
  }

  Future<void> _onGameStarted() async {
    _sessionStartTimer?.cancel();
    if (!state.isActive || _isSessionOpen) return;
    // Started outside TriOS (or TriOS restarted mid-game): no pre-launch check
    // happened, but still hold the lock and push after exit.
    try {
      await _openSession(await _createEngine());
      _sessionStartTimer?.cancel();
      const message =
          'Starsector was started outside TriOS, so synced saves were not '
          'checked first.';
      state = state.copyWith(lastMessage: () => message);
      _snack(message, SnackBarType.warn);
    } catch (e, st) {
      _setError(e, st);
    }
  }

  Future<void> _onGameExited() async {
    if (!state.isActive || !_isSessionOpen) return;
    await _runMutex.protect(() async {
      final summary = _SyncRunSummary();
      try {
        final context = ref.read(AppState.appContext);
        await _runSync(
          context != null && context.mounted ? context : null,
          allowPull: false,
          isLaunch: false,
          summary: summary,
        );
        await _closeSession();
        if (summary.errors.isEmpty) {
          _snack(summary.describe(), SnackBarType.info);
        } else {
          _snack(
            'Save sync failed for some saves. See Settings > Save Sync.',
            SnackBarType.error,
          );
        }
      } catch (e, st) {
        _setError(e, st);
        _snack('Save sync failed: ${_messageFor(e)}', SnackBarType.error);
      }
    });
  }

  /// At startup: this PC's own lock means the last session never synced.
  Future<void> _refreshAndCheckLeftoverLock() async {
    await refresh();
    if (_checkedLeftoverLock || !state.isActive) return;
    _checkedLeftoverLock = true;

    final ownLock =
        state.overview != null &&
        (await _createEngine()).hasOwnLock(state.overview!.locks);
    if (!ownLock) return;

    final isRunning = await ref.read(AppState.isGameRunning.future);
    _setSessionOpen(true);
    // If the game is running, the exit listener syncs when it closes.
    if (!isRunning) await _onGameExited();
  }

  /// How the synced save's mods differ from the mods enabled on this PC.
  List<ModChange> _modChanges(SaveSyncItem item) {
    final mods = item.remoteManifest?.mods ?? [];
    if (mods.isEmpty) return [];
    return _modChangesFor(mods);
  }

  /// How [mods] differ from the mods enabled on this PC.
  List<ModChange> _modChangesFor(List<ShallowModVariant> mods) =>
      ModProfileManagerNotifier.computeModProfileChanges(
        ModProfile.newProfile('', mods),
        ref.read(AppState.mods),
        ref.read(AppState.modVariants).value ?? [],
        ref.read(AppState.enabledModVariants),
      );

  /// The mods enabled on this PC, with the active version of each. Null
  /// until TriOS has read the mods folder: reading earlier would see no mods
  /// and could push an empty list to the other PCs.
  Future<List<ShallowModVariant>?> _localEnabledMods() async {
    await ref.read(AppState.modVariants.future);
    await ref.read(AppState.enabledModsFile.future);
    if (!ref.read(AppState.modsHaveLoaded)) return null;
    return ref
        .read(AppState.enabledModVariants)
        .map(ShallowModVariant.fromModVariant)
        .toList();
  }

  /// Saves the synced save's mod list as a "Save sync: (character)" profile
  /// (reusing it if it exists) and switches to it, the same way the Mod
  /// Profiles page does. Writing into the active profile instead would
  /// overwrite the user's own mod list. Returns the profile name.
  Future<String> _switchModsToSave(SaveSyncItem item) async {
    final mods = item.remoteManifest?.mods ?? [];
    final name = saveSyncModProfileName(item.characterName);
    final profiles = ref.read(modProfilesProvider.notifier);
    await ref.read(modProfilesProvider.future);

    late String profileId;
    await profiles.updateState((current) {
      final existing = current.modProfiles.firstWhereOrNull(
        (p) => p.name == name,
      );
      if (existing != null) {
        profileId = existing.id;
        return current.copyWith(
          modProfiles: [
            for (final p in current.modProfiles)
              p.id == existing.id
                  ? p.copyWith(
                      enabledModVariants: mods,
                      dateModified: DateTime.now(),
                    )
                  : p,
          ],
        );
      }
      final created = ModProfile.newProfile(
        name,
        mods,
        sortOrder:
            (current.modProfiles.map((p) => p.sortOrder).maxOrNull ?? 0) + 1,
      );
      profileId = created.id;
      return current.copyWith(modProfiles: [...current.modProfiles, created]);
    });

    await profiles.activateModProfile(profileId, reapplyIfActive: true);
    // activateModProfile logs failures instead of throwing, so check the result.
    if (canSwitchModsFor(_modChanges(item))) {
      throw SaveSyncException(
        'Some mods could not be switched for ${item.characterName}. '
        'Check the Mods page.',
      );
    }
    return name;
  }

  Future<SaveSyncEngine> _createEngine() async {
    final settings = ref.read(appSettings);
    final folder = settings.saveSyncFolder;
    final savesFolder = ref.read(AppState.savesFolder).value;
    if (folder == null || savesFolder == null) {
      throw SaveSyncException('Save sync is not set up.');
    }
    return SaveSyncEngine(
      backend: FolderSaveSyncBackend(folder),
      savesFolder: savesFolder,
      backups: SaveSyncBackups(saveSyncBackupsFolder),
      machine: SaveSyncMachine.current(await _machineId()),
      stateStore: _RiverpodSaveSyncStateStore(ref),
      tempFolder: Directory(
        p.join(Directory.systemTemp.path, 'trios_save_sync'),
      ),
      gameVersion: ref.read(AppState.starsectorVersion).value,
      triosVersion: Constants.version,
    );
  }

  Future<ModSyncEngine> _createModEngine() async {
    final folder = ref.read(appSettings).saveSyncFolder;
    final modsFolder = await ref.read(AppState.modsFolder.future);
    if (folder == null || modsFolder == null) {
      throw SaveSyncException(
        'Mod sync is not set up: TriOS could not find the mods folder.',
      );
    }
    return ModSyncEngine(
      backend: FolderSaveSyncBackend(folder),
      modsFolder: modsFolder,
      backups: SaveSyncBackups(
        Directory(p.join(saveSyncBackupsFolder.path, 'mods')),
      ),
      machine: SaveSyncMachine.current(await _machineId()),
      stateStore: _RiverpodSaveSyncStateStore(ref),
      tempFolder: Directory(
        p.join(Directory.systemTemp.path, 'trios_save_sync'),
      ),
      triosVersion: Constants.version,
    );
  }

  Future<String> _machineId() async {
    final existing = (await ref.read(saveSyncStateProvider.future)).machineId;
    if (existing != null) return existing;
    final created = const Uuid().v4();
    await ref
        .read(saveSyncStateProvider.notifier)
        .updateState((s) => s.copyWith(machineId: created));
    return created;
  }

  String _messageFor(Object e) =>
      e is SaveSyncException ? e.message : e.toString();

  void _setError(Object e, StackTrace st) {
    Fimber.w('Save sync failed.', ex: e, stacktrace: st);
    state = state.copyWith(
      busyMessage: () => null,
      errorMessage: () => _messageFor(e),
    );
  }

  void _snack(String message, SnackBarType type) {
    final context = ref.read(AppState.appContext);
    if (context == null || !context.mounted) return;
    showSnackBar(context: context, content: Text(message), type: type);
  }
}
