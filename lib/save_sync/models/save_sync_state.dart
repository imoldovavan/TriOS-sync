import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/save_sync/models/mod_sync_manifest.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';

part 'save_sync_state.mapper.dart';

/// What this PC knows about past syncs. Stored in
/// `trios_save_sync_state-v1.json` in the TriOS config folder.
@MappableClass()
class SaveSyncState with SaveSyncStateMappable {
  const SaveSyncState({
    this.machineId,
    this.records = const {},
    this.modRecords = const {},
    this.modHashes = const {},
    this.enabledModListRecords = const {},
  });

  /// Created once per TriOS install. Identifies this PC's lock file and
  /// manifests. The machine name is only for display.
  final String? machineId;

  /// Keyed by [recordKey].
  final Map<String, SaveSyncRecord> records;

  /// Mod folders, keyed by [recordKey] with the mods folder path.
  final Map<String, ModSyncRecord> modRecords;

  /// The last content hash computed for each mod folder, so unchanged folders
  /// aren't read again. Keyed like [modRecords]. Kept apart from the records
  /// because mods are hashed before their first sync too.
  final Map<String, ModFolderHash> modHashes;

  /// Keyed by the mods folder path (see [folderKey]).
  final Map<String, EnabledModListRecord> enabledModListRecords;

  /// Records are keyed by saves folder as well as save name, so two game
  /// installs (or two test saves folders) on one PC don't share records.
  static String recordKey(String savesFolderPath, String saveFolderName) =>
      "${savesFolderPath.replaceAll('\\', '/')}|$saveFolderName";

  SaveSyncRecord? recordFor(String savesFolderPath, String saveFolderName) =>
      records[recordKey(savesFolderPath, saveFolderName)];

  static String folderKey(String folderPath) =>
      folderPath.replaceAll('\\', '/');
}

/// The state of one save right after its last successful sync.
@MappableClass()
class SaveSyncRecord with SaveSyncRecordMappable {
  const SaveSyncRecord({
    required this.saveFolderName,
    required this.contentHash,
    required this.manifest,
    required this.syncedAt,
  });

  final String saveFolderName;

  /// Content hash both copies had at the last sync.
  final String contentHash;

  /// The manifest in the sync folder at the last sync.
  final SaveSyncManifest manifest;

  /// UTC.
  final DateTime syncedAt;
}

/// The state of one mod folder right after its last successful sync.
@MappableClass()
class ModSyncRecord with ModSyncRecordMappable {
  const ModSyncRecord({
    required this.folderName,
    required this.contentHash,
    required this.manifest,
    required this.syncedAt,
  });

  final String folderName;

  /// Content hash both copies had at the last sync.
  final String contentHash;

  /// The manifest in the sync folder at the last sync.
  final ModSyncManifest manifest;

  /// UTC.
  final DateTime syncedAt;
}

/// File count, total size, and newest file time of a mod folder. If none of
/// these changed, the folder's files are assumed unchanged.
@MappableClass()
class ModFolderFingerprint with ModFolderFingerprintMappable {
  const ModFolderFingerprint({
    required this.fileCount,
    required this.totalBytes,
    required this.newestModifiedMs,
  });

  final int fileCount;
  final int totalBytes;

  /// Milliseconds since the epoch.
  final int newestModifiedMs;
}

/// A mod folder's content hash and the fingerprint it had when hashed.
@MappableClass()
class ModFolderHash with ModFolderHashMappable {
  const ModFolderHash({required this.fingerprint, required this.contentHash});

  final ModFolderFingerprint fingerprint;
  final String contentHash;
}

/// The enabled-mods list right after its last successful sync.
@MappableClass()
class EnabledModListRecord with EnabledModListRecordMappable {
  const EnabledModListRecord({
    required this.contentHash,
    required this.manifest,
    required this.syncedAt,
  });

  final String contentHash;
  final EnabledModListManifest manifest;

  /// UTC.
  final DateTime syncedAt;
}
