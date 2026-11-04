import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';

part 'save_sync_manifest.mapper.dart';

/// Layout version of the sync folder. Bump when the folder layout or the
/// manifest format changes in a way older TriOS versions can't read.
const saveSyncLayoutVersion = 1;

/// `trios-save-sync.json` at the root of the sync folder.
@MappableClass()
class SaveSyncFolderInfo with SaveSyncFolderInfoMappable {
  const SaveSyncFolderInfo({this.layoutVersion = saveSyncLayoutVersion});

  final int layoutVersion;
}

/// Written next to each save's zip in the sync folder, as
/// `saves/<saveFolderName>.manifest.json`.
@MappableClass()
class SaveSyncManifest with SaveSyncManifestMappable {
  const SaveSyncManifest({
    this.layoutVersion = saveSyncLayoutVersion,
    required this.saveFolderName,
    required this.characterName,
    required this.contentHash,
    required this.archiveHash,
    required this.archiveSizeBytes,
    this.saveDate,
    required this.syncedAt,
    required this.machineId,
    required this.machineName,
    required this.os,
    this.gameVersion,
    this.triosVersion,
    this.mods = const [],
  });

  final int layoutVersion;

  /// Name of the save's folder inside the saves folder, e.g. `save_foo_123`.
  final String saveFolderName;
  final String characterName;

  /// Hash of the save's files. See `computeSaveContentHash`.
  final String contentHash;

  /// SHA-256 of the zip file itself. A mismatch means the zip and manifest
  /// don't belong together yet (usually the cloud client is mid-upload).
  final String archiveHash;
  final int archiveSizeBytes;

  /// When the game wrote the save, from `descriptor.xml` (UTC).
  final DateTime? saveDate;

  /// When TriOS wrote the save to the sync folder (UTC).
  final DateTime syncedAt;
  final String machineId;
  final String machineName;
  final String os;
  final String? gameVersion;
  final String? triosVersion;

  /// Mods enabled in the save.
  final List<ShallowModVariant> mods;
}
