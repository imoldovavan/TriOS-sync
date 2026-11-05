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
import 'package:trios/save_sync/models/save_sync_state.dart';
import 'package:trios/save_sync/save_sync_backend.dart';
import 'package:trios/save_sync/save_sync_backups.dart';
import 'package:trios/save_sync/save_sync_dialogs.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
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
  });

  /// False when sync is off or can't run (no folder, no saves folder).
  final bool isActive;
  final String? inactiveReason;
  final SaveSyncOverview? overview;

  /// Set while a sync step is running.
  final String? busyMessage;
  final String? errorMessage;
  final String? lastMessage;
  final DateTime? lastRunAt;

  /// True between launch and game exit, while this PC's lock file exists.
  final bool isSessionOpen;

  bool get isBusy => busyMessage != null;

  SaveSyncStatus copyWith({
    SaveSyncOverview? overview,
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
  );
}

enum _SyncOutcome { done, cancelLaunch }

/// What one sync run did, for the status line.
class _SyncRunSummary {
  int pushed = 0;
  int pulled = 0;

  /// Set when mods were switched to match a pulled save.
  String? modProfileName;
  final errors = <String>[];

  String describe() {
    final parts = [
      if (pushed > 0) 'Wrote $pushed ${pushed == 1 ? 'save' : 'saves'}',
      if (pulled > 0) 'pulled $pulled ${pulled == 1 ? 'save' : 'saves'}',
    ];
    if (parts.isEmpty) return 'Everything was already up to date.';
    var text = '${parts.join(', ')}.';
    if (modProfileName != null) {
      text += ' Switched mods to the profile "$modProfileName".';
    }
    return pushed > 0 ? '$text $_cloudUploadNote' : text;
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

    Future.microtask(_refreshAndCheckLeftoverLock);
    return SaveSyncStatus(
      isActive: true,
      busyMessage: 'Checking saves...',
      isSessionOpen: _isSessionOpen,
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
        state = state.copyWith(
          overview: overview,
          busyMessage: () => null,
          errorMessage: () => null,
        );
      } catch (e, st) {
        _setError(e, st);
      }
    });
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
  }) async {
    summary ??= _SyncRunSummary();
    state = state.copyWith(busyMessage: () => 'Syncing saves...');
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
                switchMods =
                    choice == SaveSyncModCheckChoice.pullAndSwitchMods;
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
      busyMessage: () => null,
      errorMessage: () =>
          summary!.errors.isEmpty ? null : summary.errors.join('\n'),
      lastMessage: summary.describe,
      lastRunAt: DateTime.now(),
    );
    return _SyncOutcome.done;
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
    return ModProfileManagerNotifier.computeModProfileChanges(
      ModProfile.newProfile('', mods),
      ref.read(AppState.mods),
      ref.read(AppState.modVariants).value ?? [],
      ref.read(AppState.enabledModVariants),
    );
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
