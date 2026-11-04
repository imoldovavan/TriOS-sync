import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/save_sync/cloud_conflict_files.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';
import 'package:trios/save_sync/save_sync_backend.dart';
import 'package:trios/utils/logging.dart';

/// Stores synced saves in a folder that an external cloud client (SeaDrive,
/// Dropbox, OneDrive, Google Drive, Syncthing, ...) keeps the same on every PC.
///
/// Layout:
/// ```
/// <folder>/trios-save-sync.json
/// <folder>/saves/<save>.zip
/// <folder>/saves/<save>.manifest.json
/// <folder>/locks/<machine id>.lock.json
/// ```
///
/// Cloud drives may keep files online-only and download them when opened, so
/// every read gives up if no data arrives for [stallTimeout].
class FolderSaveSyncBackend implements SaveSyncBackend {
  FolderSaveSyncBackend(
    this.folder, {
    this.stallTimeout = const Duration(seconds: 60),
  });

  final Directory folder;
  final Duration stallTimeout;

  static const markerFileName = 'trios-save-sync.json';
  static const _tempSuffix = '.tmp';

  Directory get _savesDir => Directory(p.join(folder.path, 'saves'));

  Directory get _locksDir => Directory(p.join(folder.path, 'locks'));

  File _zipFile(String saveFolderName) =>
      File(p.join(_savesDir.path, '$saveFolderName.zip'));

  File _manifestFile(String saveFolderName) =>
      File(p.join(_savesDir.path, '$saveFolderName.manifest.json'));

  File _lockFile(String machineId) =>
      File(p.join(_locksDir.path, '$machineId.lock.json'));

  @override
  String get displayName => folder.path;

  @override
  Future<void> prepare() async {
    // Never create the sync folder itself. If a cloud drive isn't mounted,
    // creating the folder would put saves on the local disk instead.
    if (!await folder.exists()) {
      throw SaveSyncException(
        'The sync folder was not found: ${folder.path}. '
        'Check that your cloud drive is running and the folder still exists.',
      );
    }

    final marker = File(p.join(folder.path, markerFileName));
    if (await marker.exists()) {
      final contents = await _readString(marker);
      final SaveSyncFolderInfo info;
      try {
        info = SaveSyncFolderInfoMapper.fromMap(
          jsonDecode(contents) as Map<String, dynamic>,
        );
      } catch (e) {
        throw SaveSyncException(
          'The file $markerFileName in the sync folder is damaged. '
          'Delete it and TriOS will recreate it.',
          cause: e,
        );
      }
      if (info.layoutVersion > saveSyncLayoutVersion) {
        throw SaveSyncException(
          'This sync folder was written by a newer version of TriOS. '
          'Update TriOS on this PC.',
        );
      }
    } else {
      await _writeStringAtomically(
        marker,
        _encodeJson(const SaveSyncFolderInfo().toMap()),
      );
    }

    await _savesDir.create();
    await _locksDir.create();
  }

  @override
  Future<RemoteSaveListing> listSaves() async {
    final manifests = <String, SaveSyncManifest>{};
    final unreadable = <String, String>{};
    final archiveNames = <String>{};
    final conflictCopies = <CloudConflictCopy>[];

    final entries = await _guard(
      'list the sync folder',
      () => _savesDir.list().toList(),
    );
    for (final file in entries.whereType<File>()) {
      final fileName = p.basename(file.path);
      if (fileName.endsWith(_tempSuffix)) continue;

      final conflictCopy = parseCloudConflictCopy(fileName);
      if (conflictCopy != null) {
        conflictCopies.add(conflictCopy);
        continue;
      }

      final saveName = saveFolderNameFromSyncFileName(fileName);
      if (saveName == null) continue;

      if (fileName.endsWith('.zip')) {
        archiveNames.add(saveName);
      } else {
        try {
          manifests[saveName] = SaveSyncManifestMapper.fromMap(
            jsonDecode(await _readString(file)) as Map<String, dynamic>,
          );
        } catch (e) {
          Fimber.w('Could not read save sync manifest ${file.path}: $e');
          unreadable[saveName] = e is SaveSyncException
              ? e.message
              : 'The manifest file is damaged.';
        }
      }
    }

    return RemoteSaveListing(
      manifests: manifests,
      archiveNames: archiveNames,
      unreadableManifests: unreadable,
      conflictCopies: conflictCopies,
    );
  }

  @override
  Future<void> downloadArchive(String saveFolderName, File destination) =>
      _copyFile(_zipFile(saveFolderName), destination);

  @override
  Future<void> uploadSave(File zip, SaveSyncManifest manifest) async {
    // Zip first, then manifest. Another PC that sees the new manifest with
    // the old zip notices because the zip's hash won't match.
    final zipTarget = _zipFile(manifest.saveFolderName);
    final zipTemp = File('${zipTarget.path}$_tempSuffix');
    await _copyFile(zip, zipTemp);
    await _guard('finish writing ${p.basename(zipTarget.path)}', () async {
      await zipTemp.rename(zipTarget.path);
    });

    await _writeStringAtomically(
      _manifestFile(manifest.saveFolderName),
      _encodeJson(manifest.toMap()),
    );
  }

  @override
  Future<List<SaveSyncLock>> readLocks() async {
    if (!await _locksDir.exists()) return [];
    final entries = await _guard(
      'list lock files',
      () => _locksDir.list().toList(),
    );
    final locks = <SaveSyncLock>[];
    for (final file in entries.whereType<File>()) {
      final fileName = p.basename(file.path);
      if (!fileName.endsWith('.lock.json')) continue;
      if (parseCloudConflictCopy(fileName) != null) continue;
      try {
        locks.add(
          SaveSyncLockMapper.fromMap(
            jsonDecode(await _readString(file)) as Map<String, dynamic>,
          ),
        );
      } catch (e) {
        Fimber.w('Ignoring unreadable save sync lock ${file.path}: $e');
      }
    }
    return locks;
  }

  @override
  Future<void> writeLock(SaveSyncLock lock) => _writeStringAtomically(
    _lockFile(lock.machineId),
    _encodeJson(lock.toMap()),
  );

  @override
  Future<void> removeLock(String machineId) async {
    final file = _lockFile(machineId);
    await _guard('remove the lock file', () async {
      if (await file.exists()) await file.delete();
    });
  }

  @override
  Future<void> takeConflictCopy(
    CloudConflictCopy copy,
    File destination,
  ) async {
    final source = File(p.join(_savesDir.path, copy.fileName));
    await _copyFile(source, destination);
    await _guard('remove ${copy.fileName}', () => source.delete());
  }

  /// UTF-8 JSON with `\n` line endings on every OS.
  String _encodeJson(Map<String, dynamic> map) =>
      '${const JsonEncoder.withIndent('  ').convert(map)}\n';

  Future<String> _readString(File file) => _guard(
    'read ${p.basename(file.path)}',
    () => file.readAsString(encoding: utf8).timeout(stallTimeout),
  );

  Future<void> _writeStringAtomically(File target, String contents) async {
    final temp = File('${target.path}$_tempSuffix');
    await _guard('write ${p.basename(target.path)}', () async {
      await temp.writeAsString(contents, encoding: utf8, flush: true);
      await temp.rename(target.path);
    });
  }

  Future<void> _copyFile(File source, File destination) => _guard(
    'copy ${p.basename(source.path)}',
    () => copyWithStallTimeout(source.openRead(), destination, stallTimeout),
  );

  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on SaveSyncException {
      rethrow;
    } on TimeoutException catch (e) {
      throw SaveSyncException(
        'Could not $action in the sync folder: no data arrived for '
        '${stallTimeout.inSeconds} seconds. Your cloud client may be offline '
        'or still downloading the file.',
        cause: e,
      );
    } on FileSystemException catch (e) {
      throw SaveSyncException(
        'Could not $action in the sync folder: '
        '${e.osError?.message ?? e.message}. Your cloud client may be offline '
        'or still downloading the file.',
        cause: e,
      );
    }
  }
}

/// Copies [source] into [destination], failing with a [TimeoutException] if
/// no data arrives for [stallTimeout]. A partly written [destination] is
/// removed on failure.
Future<void> copyWithStallTimeout(
  Stream<List<int>> source,
  File destination,
  Duration stallTimeout,
) async {
  final sink = destination.openWrite();
  try {
    await sink.addStream(source.timeout(stallTimeout));
    await sink.flush();
    await sink.close();
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {}
    if (await destination.exists()) await destination.delete();
    rethrow;
  }
}
