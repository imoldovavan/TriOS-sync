import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/mod_manager/utils/mod_file_utils.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/cloud_conflict_files.dart';
import 'package:trios/save_sync/mod_sync_items.dart';
import 'package:trios/save_sync/models/mod_sync_manifest.dart';
import 'package:trios/save_sync/models/save_sync_state.dart';
import 'package:trios/save_sync/save_archiver.dart';
import 'package:trios/save_sync/save_content_hash.dart';
import 'package:trios/save_sync/save_sync_backend.dart';
import 'package:trios/save_sync/save_sync_backups.dart';
import 'package:trios/save_sync/save_sync_decision.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/save_sync/save_sync_names.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/logging.dart';

/// Where one mod folder stands. Uses the same statuses as saves.
class ModSyncItem {
  const ModSyncItem({
    required this.folderName,
    required this.status,
    this.localHash,
    this.localSizeBytes,
    this.remoteManifest,
    this.record,
    this.problem,
  });

  final String folderName;
  final SaveSyncItemStatus status;

  /// Null if the folder isn't on this PC or wasn't hashed.
  final String? localHash;

  /// Total size of the folder's files. Null like [localHash].
  final int? localSizeBytes;
  final ModSyncManifest? remoteManifest;
  final ModSyncRecord? record;

  /// Extra detail for [SaveSyncItemStatus.nameProblem] and
  /// [SaveSyncItemStatus.error].
  final String? problem;
}

/// Where the enabled-mods list stands.
class EnabledModListItem {
  const EnabledModListItem({
    required this.status,
    required this.localMods,
    required this.localHash,
    this.remote,
    this.record,
    this.problem,
  });

  final SaveSyncItemStatus status;

  /// The mods enabled on this PC.
  final List<ShallowModVariant> localMods;
  final String localHash;
  final EnabledModListManifest? remote;
  final EnabledModListRecord? record;
  final String? problem;
}

class ModSyncOverview {
  const ModSyncOverview({
    required this.items,
    required this.enabledList,
    required this.conflictCopies,
  });

  final List<ModSyncItem> items;
  final EnabledModListItem enabledList;
  final List<CloudConflictCopy> conflictCopies;

  ModSyncItem? item(String folderName) =>
      items.where((i) => i.folderName == folderName).firstOrNull;
}

enum ModSyncConflictChoice { keepLocal, keepSynced, skip }

/// The mod sync steps, with no UI. [SaveSyncNotifier] decides when to run
/// them. Shares the backend, machine, and state store with [SaveSyncEngine].
class ModSyncEngine {
  ModSyncEngine({
    required this.backend,
    required this.modsFolder,
    required this.backups,
    required this.machine,
    required this.stateStore,
    required this.tempFolder,
    this.triosVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SaveSyncBackend backend;
  final Directory modsFolder;

  /// Backups for mods only, separate from save backups.
  final SaveSyncBackups backups;
  final SaveSyncMachine machine;
  final SaveSyncStateStore stateStore;

  /// Local folder for zips on their way in or out.
  final Directory tempFolder;
  final String? triosVersion;
  final DateTime Function() _clock;

  /// Looks at both sides and works out each mod's status and the
  /// enabled-mods list's status. [localEnabledMods] are the mods enabled on
  /// this PC. [onProgress] gets "Reading mod 3 of 76: name" messages.
  Future<ModSyncOverview> loadOverview(
    List<ShallowModVariant> localEnabledMods, {
    void Function(String message)? onProgress,
  }) async {
    await backend.prepare();
    final listing = await backend.listMods();
    final state = await stateStore.read();

    final localNames = listModFolderNames(modsFolder).toSet();
    final allNames = {
      ...localNames,
      ...listing.manifests.keys,
      ...listing.archiveNames,
      ...listing.unreadableManifests.keys,
    }.toList()..sort();
    final caseClashes = findCaseClashes(allNames);
    final namesWithConflictCopies = listing.modNamesWithConflictCopies;
    final newHashes = <String, ModFolderHash>{};

    final items = <ModSyncItem>[];
    for (final (index, name) in allNames.indexed) {
      final manifest = listing.manifests[name];
      final record = state.modRecords[_key(name)];

      ModSyncItem item(
        SaveSyncItemStatus status, {
        ModFolderHash? hash,
        String? problem,
      }) => ModSyncItem(
        folderName: name,
        status: status,
        localHash: hash?.contentHash,
        localSizeBytes: hash?.fingerprint.totalBytes,
        remoteManifest: manifest,
        record: record,
        problem: problem,
      );

      final nameProblem = caseClashes.contains(name)
          ? SaveNameProblem.caseClash
          : checkSaveFolderName(name);

      if (nameProblem != null) {
        items.add(
          item(SaveSyncItemStatus.nameProblem, problem: nameProblem.message),
        );
      } else if (namesWithConflictCopies.contains(name)) {
        items.add(item(SaveSyncItemStatus.cloudConflictCopy));
      } else if (listing.unreadableManifests[name] case final reason?) {
        items.add(item(SaveSyncItemStatus.error, problem: reason));
      } else if ((manifest != null) != listing.archiveNames.contains(name)) {
        items.add(item(SaveSyncItemStatus.waitingForCloud));
      } else {
        ModFolderHash? localHash;
        if (localNames.contains(name)) {
          onProgress?.call(
            'Reading mod ${index + 1} of ${allNames.length}: $name',
          );
          localHash = await _localHash(name, state.modHashes, newHashes);
        }
        final decision = decideSaveSync(
          localHash: localHash?.contentHash,
          remoteHash: manifest?.contentHash,
          recordHash: record?.contentHash,
        );
        items.add(item(_statusFor(decision), hash: localHash));
      }
    }

    if (newHashes.isNotEmpty) {
      await stateStore.update(
        (s) => s.copyWith(modHashes: {...s.modHashes, ...newHashes}),
      );
    }

    return ModSyncOverview(
      items: items,
      enabledList: _enabledListItem(localEnabledMods, listing, state),
      conflictCopies: listing.conflictCopies,
    );
  }

  /// Writes this PC's copy of the mod to the sync location.
  Future<void> push(String folderName) async {
    await backend.prepare();
    final folder = _localFolder(folderName);
    // Hash again now; the folder may have changed since the overview.
    final fingerprint = await computeModFingerprint(folder);
    final contentHash = await computeModContentHash(folder);
    final modInfo = await getModInfo(folder, StringBuffer());

    tempFolder.createSync(recursive: true);
    final zip = File(p.join(tempFolder.path, 'mod-$folderName.zip'));
    try {
      await archiveModFolder(folder, zip);
      final manifest = ModSyncManifest(
        folderName: folderName,
        modId: modInfo?.id,
        modName: modInfo?.name,
        modVersion: modInfo?.version?.toString(),
        contentHash: contentHash,
        archiveHash: await computeFileHash(zip),
        archiveSizeBytes: await zip.length(),
        syncedAt: _clock().toUtc(),
        machineId: machine.id,
        machineName: machine.name,
        os: machine.os,
        triosVersion: triosVersion,
      );
      await backend.uploadMod(zip, manifest);
      await _saveRecord(
        folderName,
        contentHash,
        manifest,
        hash: ModFolderHash(fingerprint: fingerprint, contentHash: contentHash),
      );
      Fimber.i('Mod sync: pushed $folderName.');
    } finally {
      if (zip.existsSync()) zip.deleteSync();
    }
  }

  /// Replaces this PC's copy with the synced one, or adds it if this PC
  /// doesn't have it. The current local copy is moved to backups.
  Future<void> pull(
    ModSyncItem item, {
    SaveSyncBackupReason reason = SaveSyncBackupReason.beforePull,
  }) async {
    final manifest = item.remoteManifest;
    if (manifest == null) {
      throw SaveSyncException(
        'There is no synced copy of the mod ${item.folderName} to pull.',
      );
    }

    await backend.prepare();
    tempFolder.createSync(recursive: true);
    final zip = File(p.join(tempFolder.path, 'mod-${item.folderName}.zip'));
    try {
      await backend.downloadModArchive(item.folderName, zip);
      if (await computeFileHash(zip) != manifest.archiveHash) {
        throw SaveSyncException(
          'The synced zip for the mod ${item.folderName} does not match its '
          'manifest yet. Your cloud client may still be uploading or '
          'downloading it. Try again in a minute.',
        );
      }

      await installModFromArchive(
        zipFile: zip,
        modsFolder: modsFolder,
        folderName: item.folderName,
        modInfoFileName: await _modInfoFileNameForPull(
          item.folderName,
          manifest,
        ),
        moveReplacedMod: (replaced) =>
            backups.backUpSaveFolder(replaced, item.folderName, reason),
      );

      final folder = _localFolder(item.folderName);
      final fingerprint = await computeModFingerprint(folder);
      final installedHash = await computeModContentHash(folder);
      if (installedHash != manifest.contentHash) {
        Fimber.w(
          'Mod sync: ${item.folderName} was pulled but its content hash '
          'differs from the manifest. It will show as changed on this PC.',
        );
      }
      await _saveRecord(
        item.folderName,
        manifest.contentHash,
        manifest,
        hash: ModFolderHash(
          fingerprint: fingerprint,
          contentHash: installedHash,
        ),
      );
      Fimber.i('Mod sync: pulled ${item.folderName}.');
    } finally {
      if (zip.existsSync()) zip.deleteSync();
      _removeTempFolderIfEmpty();
    }
  }

  /// Both copies already match; remember that.
  Future<void> recordUpToDate(ModSyncItem item) async {
    final manifest = item.remoteManifest;
    final hash = item.localHash;
    if (manifest == null || hash == null) return;
    if (item.record?.contentHash == hash && item.record?.manifest == manifest) {
      return;
    }
    await _saveRecord(item.folderName, hash, manifest);
  }

  Future<void> resolveConflict(
    ModSyncItem item,
    ModSyncConflictChoice choice,
  ) async {
    switch (choice) {
      case ModSyncConflictChoice.keepLocal:
        await backUpSyncedCopy(item, SaveSyncBackupReason.conflictSynced);
        await push(item.folderName);
      case ModSyncConflictChoice.keepSynced:
        await pull(item, reason: SaveSyncBackupReason.conflictLocal);
      case ModSyncConflictChoice.skip:
        break;
    }
  }

  /// Copies the synced zip and manifest into a local backup folder.
  Future<Directory> backUpSyncedCopy(
    ModSyncItem item,
    SaveSyncBackupReason reason,
  ) async {
    final folder = backups.createBackupFolder(item.folderName, reason);
    await backend.downloadModArchive(
      item.folderName,
      File(p.join(folder.path, '${item.folderName}.zip')),
    );
    if (item.remoteManifest case final manifest?) {
      await File(p.join(folder.path, '${item.folderName}.manifest.json'))
          .writeAsString(_encodeJson(manifest.toMap()), encoding: utf8);
    }
    return folder;
  }

  /// "Remove from sync folder": moves the mod's zip and manifest to this PC's
  /// backups and forgets the record. Other PCs keep their copy.
  Future<void> removeFromSyncFolder(ModSyncItem item) async {
    await backend.prepare();
    final folder = backups.createBackupFolder(
      item.folderName,
      SaveSyncBackupReason.removedFromSyncFolder,
    );
    await backend.takeMod(item.folderName, folder);
    final key = _key(item.folderName);
    await stateStore.update(
      (s) => s.copyWith(modRecords: {...s.modRecords}..remove(key)),
    );
    Fimber.i('Mod sync: removed ${item.folderName} from the sync folder.');
  }

  /// Moves cloud-client conflict copies of mods and of the enabled-mods list
  /// into local backups.
  Future<void> takeConflictCopies(List<CloudConflictCopy> copies) async {
    for (final copy in copies) {
      final name =
          saveFolderNameFromSyncFileName(copy.originalFileName) ??
          copy.originalFileName;
      final folder = backups.createBackupFolder(
        name,
        SaveSyncBackupReason.cloudConflictCopy,
      );
      await backend.takeModConflictCopy(
        copy,
        File(p.join(folder.path, copy.fileName)),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Enabled-mods list

  /// Only the enabled-mods list's status, without looking at mod folders.
  /// Used after pulled mods changed what is installed.
  Future<EnabledModListItem> loadEnabledList(
    List<ShallowModVariant> localEnabledMods,
  ) async {
    await backend.prepare();
    return _enabledListItem(
      localEnabledMods,
      await backend.listMods(),
      await stateStore.read(),
    );
  }

  /// Writes this PC's enabled-mods list to the sync location.
  Future<void> pushEnabledList(List<ShallowModVariant> localMods) async {
    await backend.prepare();
    final list = EnabledModListManifest(
      contentHash: computeEnabledModListHash(localMods),
      mods: localMods,
      syncedAt: _clock().toUtc(),
      machineId: machine.id,
      machineName: machine.name,
      os: machine.os,
      triosVersion: triosVersion,
    );
    await backend.writeEnabledModList(list);
    await _saveEnabledListRecord(list);
    Fimber.i('Mod sync: pushed the enabled-mods list.');
  }

  /// Call after the synced list was applied on this PC (or both lists
  /// already match), so it counts as synced.
  Future<void> recordEnabledListSynced(EnabledModListItem item) async {
    final remote = item.remote;
    if (remote == null) return;
    if (item.record?.contentHash == remote.contentHash &&
        item.record?.manifest == remote) {
      return;
    }
    await _saveEnabledListRecord(remote);
  }

  /// "Keep this PC's list": backs up the synced list, then pushes this PC's.
  Future<void> keepLocalEnabledList(EnabledModListItem item) async {
    if (item.remote case final remote?) {
      final folder = backups.createBackupFolder(
        'enabled-mods',
        SaveSyncBackupReason.conflictSynced,
      );
      await File(p.join(folder.path, enabledModListFileName))
          .writeAsString(_encodeJson(remote.toMap()), encoding: utf8);
    }
    await pushEnabledList(item.localMods);
  }

  // -------------------------------------------------------------------------

  EnabledModListItem _enabledListItem(
    List<ShallowModVariant> localMods,
    RemoteModListing listing,
    SaveSyncState state,
  ) {
    final localHash = computeEnabledModListHash(localMods);
    final remote = listing.enabledModList;
    final record =
        state.enabledModListRecords[SaveSyncState.folderKey(modsFolder.path)];

    EnabledModListItem item(SaveSyncItemStatus status, {String? problem}) =>
        EnabledModListItem(
          status: status,
          localMods: localMods,
          localHash: localHash,
          remote: remote,
          record: record,
          problem: problem,
        );

    if (listing.enabledModListHasConflictCopy) {
      return item(SaveSyncItemStatus.cloudConflictCopy);
    }
    if (listing.enabledModListProblem case final problem?) {
      return item(SaveSyncItemStatus.error, problem: problem);
    }
    final decision = decideSaveSync(
      localHash: localHash,
      remoteHash: remote?.contentHash,
      recordHash: record?.contentHash,
    );
    return item(_statusFor(decision));
  }

  /// The local folder's content hash and fingerprint, reusing the stored
  /// hash if the fingerprint hasn't changed. Newly computed hashes go into
  /// [newHashes].
  Future<ModFolderHash> _localHash(
    String folderName,
    Map<String, ModFolderHash> storedHashes,
    Map<String, ModFolderHash> newHashes,
  ) async {
    final folder = _localFolder(folderName);
    final fingerprint = await computeModFingerprint(folder);
    final key = _key(folderName);
    final stored = storedHashes[key];
    if (stored != null && stored.fingerprint == fingerprint) return stored;
    final hash = ModFolderHash(
      fingerprint: fingerprint,
      contentHash: await computeModContentHash(folder),
    );
    newHashes[key] = hash;
    return hash;
  }

  /// Which name the pulled folder's `mod_info.json` should get:
  /// - the folder exists here: keep this PC's name (enabled or disabled);
  /// - it's new, but another folder here has the same mod: disabled, so two
  ///   versions are never active at once;
  /// - otherwise: as zipped (`mod_info.json`).
  Future<String?> _modInfoFileNameForPull(
    String folderName,
    ModSyncManifest manifest,
  ) async {
    final existing = _localFolder(folderName);
    if (existing.existsSync()) return currentModInfoFileName(existing);

    final modId = manifest.modId;
    if (modId == null) return null;
    for (final other in listModFolderNames(modsFolder)) {
      final info = await getModInfo(_localFolder(other), StringBuffer());
      if (info?.id == modId) return Constants.modInfoFileDisabledNames.first;
    }
    return null;
  }

  void _removeTempFolderIfEmpty() {
    final temp = Directory(p.join(modsFolder.path, modSyncTempFolderName));
    try {
      if (temp.existsSync() &&
          temp.listSync(recursive: true).whereType<File>().isEmpty) {
        temp.deleteSync(recursive: true);
      }
    } catch (e) {
      Fimber.w('Mod sync: could not remove ${temp.path}: $e');
    }
  }

  static SaveSyncItemStatus _statusFor(SaveSyncDecision decision) =>
      switch (decision) {
        SaveSyncDecision.upToDate => SaveSyncItemStatus.upToDate,
        SaveSyncDecision.push => SaveSyncItemStatus.willPush,
        SaveSyncDecision.pull => SaveSyncItemStatus.willPull,
        SaveSyncDecision.conflict => SaveSyncItemStatus.conflict,
        SaveSyncDecision.missingLocally => SaveSyncItemStatus.missingLocally,
        SaveSyncDecision.notFound => SaveSyncItemStatus.notFound,
      };

  String _key(String folderName) =>
      SaveSyncState.recordKey(modsFolder.path, folderName);

  Directory _localFolder(String folderName) =>
      Directory(p.join(modsFolder.path, folderName));

  String _encodeJson(Map<String, dynamic> map) =>
      '${const JsonEncoder.withIndent('  ').convert(map)}\n';

  Future<void> _saveRecord(
    String folderName,
    String contentHash,
    ModSyncManifest manifest, {
    ModFolderHash? hash,
  }) {
    final key = _key(folderName);
    return stateStore.update(
      (state) => state.copyWith(
        modRecords: {
          ...state.modRecords,
          key: ModSyncRecord(
            folderName: folderName,
            contentHash: contentHash,
            manifest: manifest,
            syncedAt: _clock().toUtc(),
          ),
        },
        modHashes: hash == null
            ? state.modHashes
            : {...state.modHashes, key: hash},
      ),
    );
  }

  Future<void> _saveEnabledListRecord(EnabledModListManifest list) =>
      stateStore.update(
        (state) => state.copyWith(
          enabledModListRecords: {
            ...state.enabledModListRecords,
            SaveSyncState.folderKey(modsFolder.path): EnabledModListRecord(
              contentHash: list.contentHash,
              manifest: list,
              syncedAt: _clock().toUtc(),
            ),
          },
        ),
      );
}
