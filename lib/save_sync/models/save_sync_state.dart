import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';

part 'save_sync_state.mapper.dart';

/// What this PC knows about past syncs. Stored in
/// `trios_save_sync_state-v1.json` in the TriOS config folder.
@MappableClass()
class SaveSyncState with SaveSyncStateMappable {
  const SaveSyncState({this.machineId, this.records = const {}});

  /// Created once per TriOS install. Identifies this PC's lock file and
  /// manifests. The machine name is only for display.
  final String? machineId;

  /// Keyed by [recordKey].
  final Map<String, SaveSyncRecord> records;

  /// Records are keyed by saves folder as well as save name, so two game
  /// installs (or two test saves folders) on one PC don't share records.
  static String recordKey(String savesFolderPath, String saveFolderName) =>
      "${savesFolderPath.replaceAll('\\', '/')}|$saveFolderName";

  SaveSyncRecord? recordFor(String savesFolderPath, String saveFolderName) =>
      records[recordKey(savesFolderPath, saveFolderName)];
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
