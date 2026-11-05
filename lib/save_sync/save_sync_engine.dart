import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_sync/cloud_conflict_files.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';
import 'package:trios/save_sync/models/save_sync_state.dart';
import 'package:trios/save_sync/save_archiver.dart';
import 'package:trios/save_sync/save_credits_reader.dart';
import 'package:trios/save_sync/save_content_hash.dart';
import 'package:trios/save_sync/save_sync_backend.dart';
import 'package:trios/save_sync/save_sync_backups.dart';
import 'package:trios/save_sync/save_sync_decision.dart';
import 'package:trios/save_sync/save_sync_names.dart';
import 'package:trios/utils/logging.dart';

/// This PC, as other PCs see it in manifests and lock files.
class SaveSyncMachine {
  const SaveSyncMachine({
    required this.id,
    required this.name,
    required this.os,
  });

  factory SaveSyncMachine.current(String id) => SaveSyncMachine(
    id: id,
    name: Platform.localHostname,
    os: Platform.operatingSystem,
  );

  final String id;
  final String name;
  final String os;
}

/// Reads and updates this PC's [SaveSyncState].
abstract class SaveSyncStateStore {
  Future<SaveSyncState> read();

  Future<void> update(SaveSyncState Function(SaveSyncState state) mutator);
}

/// Where one save stands. Shown in the settings list and drives what a sync
/// run does.
enum SaveSyncItemStatus {
  notSelected("Not synced"),
  upToDate("Up to date"),
  willPush("Changed on this PC; will be written to the sync folder"),
  willPull("Newer copy in the sync folder; will replace this PC's copy"),
  conflict("Changed on this PC and in the sync folder"),
  missingLocally("Missing on this PC; nothing was deleted"),
  waitingForCloud("Waiting for the cloud client to finish"),
  cloudConflictCopy("Cloud conflict copy found"),
  nameProblem("Name can't be synced"),
  notFound("Not found on this PC or in the sync folder"),
  error("Error");

  const SaveSyncItemStatus(this.label);

  final String label;
}

class SaveSyncItem {
  const SaveSyncItem({
    required this.saveFolderName,
    required this.isSelected,
    required this.status,
    this.localSave,
    this.localHash,
    this.remoteManifest,
    this.record,
    this.problem,
  });

  final String saveFolderName;
  final bool isSelected;
  final SaveSyncItemStatus status;

  /// Details from this PC's `descriptor.xml`, if the save exists here and
  /// could be read.
  final SaveFile? localSave;

  /// Only computed for selected saves.
  final String? localHash;
  final SaveSyncManifest? remoteManifest;
  final SaveSyncRecord? record;

  /// Extra detail for [SaveSyncItemStatus.nameProblem] and
  /// [SaveSyncItemStatus.error].
  final String? problem;

  String get characterName =>
      localSave?.characterName ?? remoteManifest?.characterName ?? '';
}

class SaveSyncOverview {
  const SaveSyncOverview({
    required this.items,
    required this.conflictCopies,
    required this.locks,
  });

  final List<SaveSyncItem> items;
  final List<CloudConflictCopy> conflictCopies;
  final List<SaveSyncLock> locks;

  SaveSyncItem? item(String saveFolderName) =>
      items.where((i) => i.saveFolderName == saveFolderName).firstOrNull;
}

enum SaveSyncConflictChoice { keepLocal, keepSynced, keepBoth, skip }

/// The sync steps, with no UI. [SaveSyncNotifier] decides when to run them
/// and asks the user when needed.
class SaveSyncEngine {
  SaveSyncEngine({
    required this.backend,
    required this.savesFolder,
    required this.backups,
    required this.machine,
    required this.stateStore,
    required this.tempFolder,
    this.gameVersion,
    this.triosVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SaveSyncBackend backend;
  final Directory savesFolder;
  final SaveSyncBackups backups;
  final SaveSyncMachine machine;
  final SaveSyncStateStore stateStore;

  /// Local folder for zips on their way in or out.
  final Directory tempFolder;
  final String? gameVersion;
  final String? triosVersion;
  final DateTime Function() _clock;

  static final _folderTimestamp = DateFormat('yyyy-MM-dd_HH-mm-ss');

  /// Looks at both sides and works out each save's status. Only saves in
  /// [selectedSaveNames] are hashed.
  Future<SaveSyncOverview> loadOverview(Set<String> selectedSaveNames) async {
    await backend.prepare();
    final listing = await backend.listSaves();
    final locks = await backend.readLocks();
    final state = await stateStore.read();

    final localNames = <String>{
      if (savesFolder.existsSync())
        for (final dir in savesFolder.listSync().whereType<Directory>())
          if (p.basename(dir.path).startsWith('save')) p.basename(dir.path),
    };
    final allNames = {
      ...localNames,
      ...listing.manifests.keys,
      ...listing.archiveNames,
      ...listing.unreadableManifests.keys,
      ...selectedSaveNames,
    };
    final caseClashes = findCaseClashes(allNames);
    final namesWithConflictCopies = listing.saveNamesWithConflictCopies;

    final items = <SaveSyncItem>[];
    for (final name in allNames.toList()..sort()) {
      final isLocal = localNames.contains(name);
      final manifest = listing.manifests[name];
      final record = state.recordFor(savesFolder.path, name);
      final localSave = isLocal ? await _tryReadSave(name) : null;

      SaveSyncItem item(
        SaveSyncItemStatus status, {
        String? hash,
        String? problem,
      }) => SaveSyncItem(
        saveFolderName: name,
        isSelected: selectedSaveNames.contains(name),
        status: status,
        localSave: localSave,
        localHash: hash,
        remoteManifest: manifest,
        record: record,
        problem: problem,
      );

      final nameProblem = caseClashes.contains(name)
          ? SaveNameProblem.caseClash
          : checkSaveFolderName(name);

      if (!selectedSaveNames.contains(name)) {
        items.add(
          item(SaveSyncItemStatus.notSelected, problem: nameProblem?.message),
        );
      } else if (nameProblem != null) {
        items.add(
          item(SaveSyncItemStatus.nameProblem, problem: nameProblem.message),
        );
      } else if (namesWithConflictCopies.contains(name)) {
        items.add(item(SaveSyncItemStatus.cloudConflictCopy));
      } else if (listing.unreadableManifests[name] case final reason?) {
        items.add(item(SaveSyncItemStatus.error, problem: reason));
      } else if ((manifest != null) != listing.archiveNames.contains(name)) {
        // Zip without manifest, or manifest without zip: an upload or
        // download is still in progress.
        items.add(item(SaveSyncItemStatus.waitingForCloud));
      } else {
        final localHash = isLocal
            ? await computeSaveContentHash(_localFolder(name))
            : null;
        final decision = decideSaveSync(
          localHash: localHash,
          remoteHash: manifest?.contentHash,
          recordHash: record?.contentHash,
        );
        items.add(
          item(switch (decision) {
            SaveSyncDecision.upToDate => SaveSyncItemStatus.upToDate,
            SaveSyncDecision.push => SaveSyncItemStatus.willPush,
            SaveSyncDecision.pull => SaveSyncItemStatus.willPull,
            SaveSyncDecision.conflict => SaveSyncItemStatus.conflict,
            SaveSyncDecision.missingLocally =>
              SaveSyncItemStatus.missingLocally,
            SaveSyncDecision.notFound => SaveSyncItemStatus.notFound,
          }, hash: localHash),
        );
      }
    }

    return SaveSyncOverview(
      items: items,
      conflictCopies: listing.conflictCopies,
      locks: locks,
    );
  }

  /// Writes this PC's copy of the save to the sync location.
  Future<void> push(String saveFolderName) async {
    await backend.prepare();
    final folder = _localFolder(saveFolderName);
    final localSave = await readSaveFolder(folder);
    // Hash again now; the save may have changed since the overview.
    final contentHash = await computeSaveContentHash(folder);

    tempFolder.createSync(recursive: true);
    final zip = File(p.join(tempFolder.path, '$saveFolderName.zip'));
    try {
      await archiveSaveFolder(folder, zip);
      final manifest = SaveSyncManifest(
        saveFolderName: saveFolderName,
        characterName: localSave.characterName,
        characterLevel: localSave.characterLevel,
        gameTimestamp: localSave.gameTimestamp,
        difficulty: localSave.difficulty,
        isIronMode: localSave.isIronMode,
        credits: await readSaveCredits(folder),
        contentHash: contentHash,
        archiveHash: await computeFileHash(zip),
        archiveSizeBytes: await zip.length(),
        saveDate: localSave.saveDate?.toUtc(),
        syncedAt: _clock().toUtc(),
        machineId: machine.id,
        machineName: machine.name,
        os: machine.os,
        gameVersion: localSave.gameVersion ?? gameVersion,
        triosVersion: triosVersion,
        mods: localSave.mods.map((m) => m.toShallowModVariant()).toList(),
      );
      await backend.uploadSave(zip, manifest);
      await _saveRecord(saveFolderName, contentHash, manifest);
      Fimber.i('Save sync: pushed $saveFolderName.');
    } finally {
      if (zip.existsSync()) zip.deleteSync();
    }
  }

  /// Replaces this PC's copy with the synced one. The current local copy is
  /// moved to backups with [reason].
  ///
  /// With [asFolderName], the synced save is put in that folder instead and
  /// nothing local is replaced or recorded (used by "Keep both").
  Future<void> pull(
    SaveSyncItem item, {
    SaveSyncBackupReason reason = SaveSyncBackupReason.beforePull,
    String? asFolderName,
  }) async {
    final manifest = item.remoteManifest;
    if (manifest == null) {
      throw SaveSyncException(
        'There is no synced copy of ${item.saveFolderName} to pull.',
      );
    }

    await backend.prepare();
    tempFolder.createSync(recursive: true);
    final zip = File(p.join(tempFolder.path, '${item.saveFolderName}.zip'));
    try {
      await backend.downloadArchive(item.saveFolderName, zip);
      if (await computeFileHash(zip) != manifest.archiveHash) {
        throw SaveSyncException(
          'The synced zip for ${item.saveFolderName} does not match its '
          'manifest yet. Your cloud client may still be uploading or '
          'downloading it. Try again in a minute.',
        );
      }

      final targetName = asFolderName ?? item.saveFolderName;
      await installSaveFromArchive(
        zipFile: zip,
        savesFolder: savesFolder,
        saveFolderName: targetName,
        moveReplacedSave: (replaced) =>
            backups.backUpSaveFolder(replaced, item.saveFolderName, reason),
      );

      final installedHash = await computeSaveContentHash(
        _localFolder(targetName),
      );
      if (installedHash != manifest.contentHash) {
        Fimber.w(
          'Save sync: $targetName was pulled but its content hash differs '
          'from the manifest. It will show as changed on this PC.',
        );
      }
      if (asFolderName == null) {
        await _saveRecord(item.saveFolderName, manifest.contentHash, manifest);
      }
      Fimber.i('Save sync: pulled ${item.saveFolderName} as $targetName.');
    } finally {
      if (zip.existsSync()) zip.deleteSync();
    }
  }

  /// Both copies already match; remember that.
  Future<void> recordUpToDate(SaveSyncItem item) async {
    final manifest = item.remoteManifest;
    final hash = item.localHash;
    if (manifest == null || hash == null) return;
    if (item.record?.contentHash == hash && item.record?.manifest == manifest) {
      return;
    }
    await _saveRecord(item.saveFolderName, hash, manifest);
  }

  Future<void> resolveConflict(
    SaveSyncItem item,
    SaveSyncConflictChoice choice,
  ) async {
    switch (choice) {
      case SaveSyncConflictChoice.keepLocal:
        await backUpSyncedCopy(item, SaveSyncBackupReason.conflictSynced);
        await push(item.saveFolderName);
      case SaveSyncConflictChoice.keepSynced:
        await pull(item, reason: SaveSyncBackupReason.conflictLocal);
      case SaveSyncConflictChoice.keepBoth:
        await pull(item, asFolderName: keepBothFolderName(item.saveFolderName));
        await push(item.saveFolderName);
      case SaveSyncConflictChoice.skip:
        break;
    }
  }

  /// Name for the synced copy when the user keeps both.
  String keepBothFolderName(String saveFolderName) =>
      '${saveFolderName}_synced_${_folderTimestamp.format(_clock())}';

  /// Copies the synced zip and manifest into a local backup folder.
  Future<Directory> backUpSyncedCopy(
    SaveSyncItem item,
    SaveSyncBackupReason reason,
  ) async {
    final folder = backups.createBackupFolder(item.saveFolderName, reason);
    await backend.downloadArchive(
      item.saveFolderName,
      File(p.join(folder.path, '${item.saveFolderName}.zip')),
    );
    if (item.remoteManifest case final manifest?) {
      await File(p.join(folder.path, '${item.saveFolderName}.manifest.json'))
          .writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(manifest.toMap())}\n',
            encoding: utf8,
          );
    }
    return folder;
  }

  /// Moves cloud-client conflict copies out of the sync location into local
  /// backups.
  Future<void> takeConflictCopies(List<CloudConflictCopy> copies) async {
    for (final copy in copies) {
      final saveName =
          saveFolderNameFromSyncFileName(copy.originalFileName) ??
          copy.originalFileName;
      final folder = backups.createBackupFolder(
        saveName,
        SaveSyncBackupReason.cloudConflictCopy,
      );
      await backend.takeConflictCopy(
        copy,
        File(p.join(folder.path, copy.fileName)),
      );
    }
  }

  /// Lock files from other machines.
  List<SaveSyncLock> otherMachinesLocks(List<SaveSyncLock> locks) =>
      locks.where((lock) => !lock.isOwnedBy(machine.id)).toList();

  bool hasOwnLock(List<SaveSyncLock> locks) =>
      locks.any((lock) => lock.isOwnedBy(machine.id));

  Future<void> writeLock() async {
    await backend.prepare();
    await backend.writeLock(
      SaveSyncLock(
        machineId: machine.id,
        machineName: machine.name,
        os: machine.os,
        triosVersion: triosVersion,
        startedAt: _clock().toUtc(),
      ),
    );
  }

  Future<void> removeLock() => backend.removeLock(machine.id);

  Directory _localFolder(String saveFolderName) =>
      Directory(p.join(savesFolder.path, saveFolderName));

  Future<SaveFile?> _tryReadSave(String saveFolderName) async {
    try {
      return await readSaveFolder(_localFolder(saveFolderName));
    } catch (e) {
      Fimber.w('Save sync: could not read $saveFolderName: $e');
      return null;
    }
  }

  Future<void> _saveRecord(
    String saveFolderName,
    String contentHash,
    SaveSyncManifest manifest,
  ) => stateStore.update(
    (state) => state.copyWith(
      records: {
        ...state.records,
        SaveSyncState.recordKey(
          savesFolder.path,
          saveFolderName,
        ): SaveSyncRecord(
          saveFolderName: saveFolderName,
          contentHash: contentHash,
          manifest: manifest,
          syncedAt: _clock().toUtc(),
        ),
      },
    ),
  );
}
