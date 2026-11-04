import 'dart:io';

import 'package:trios/save_sync/cloud_conflict_files.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';

/// A problem with save sync, with a message that can be shown to the user
/// as-is.
class SaveSyncException implements Exception {
  SaveSyncException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? message : '$message ($cause)';
}

/// What the sync location holds right now.
class RemoteSaveListing {
  const RemoteSaveListing({
    this.manifests = const {},
    this.archiveNames = const {},
    this.unreadableManifests = const {},
    this.conflictCopies = const [],
  });

  /// Readable manifests, keyed by save folder name.
  final Map<String, SaveSyncManifest> manifests;

  /// Save folder names that have a zip.
  final Set<String> archiveNames;

  /// Manifests that exist but couldn't be read, keyed by save folder name,
  /// with the reason.
  final Map<String, String> unreadableManifests;

  /// Copies a cloud client made after two machines changed the same file.
  /// Never read as saves.
  final List<CloudConflictCopy> conflictCopies;

  /// Save folder names that have conflict copies.
  Set<String> get saveNamesWithConflictCopies => {
    for (final copy in conflictCopies)
      ?saveFolderNameFromSyncFileName(copy.originalFileName),
  };
}

/// Returns the save folder name for a file in the sync location's `saves`
/// folder (`<save>.zip` or `<save>.manifest.json`), or null for other files.
String? saveFolderNameFromSyncFileName(String fileName) {
  for (final suffix in const ['.manifest.json', '.zip']) {
    if (fileName.endsWith(suffix)) {
      return fileName.substring(0, fileName.length - suffix.length);
    }
  }
  return null;
}

/// Where synced saves are stored. v1 has one implementation: a folder kept in
/// sync by an external cloud client ([FolderSaveSyncBackend]). Services with
/// their own API can be added as further implementations.
///
/// Every method throws [SaveSyncException] on failure.
abstract class SaveSyncBackend {
  /// Shown in messages, e.g. the folder path.
  String get displayName;

  /// Checks the location is usable and sets it up on first use. Throws if it
  /// is missing or was written by a newer TriOS.
  Future<void> prepare();

  Future<RemoteSaveListing> listSaves();

  /// Copies the save's zip to [destination] on this PC.
  Future<void> downloadArchive(String saveFolderName, File destination);

  /// Stores [zip] and then [manifest]. Each is written completely under a
  /// temporary name before it replaces the previous one.
  Future<void> uploadSave(File zip, SaveSyncManifest manifest);

  /// Lock files from every machine, including this one.
  Future<List<SaveSyncLock>> readLocks();

  Future<void> writeLock(SaveSyncLock lock);

  Future<void> removeLock(String machineId);

  /// Moves a cloud client's conflict copy to [destination] on this PC,
  /// removing it from the sync location.
  Future<void> takeConflictCopy(CloudConflictCopy copy, File destination);
}
