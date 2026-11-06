import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';

part 'mod_sync_manifest.mapper.dart';

/// Written next to each mod's zip in the sync folder, as
/// `mods/<folderName>.manifest.json`.
@MappableClass()
class ModSyncManifest with ModSyncManifestMappable {
  const ModSyncManifest({
    this.layoutVersion = saveSyncLayoutVersion,
    required this.folderName,
    this.modId,
    this.modName,
    this.modVersion,
    required this.contentHash,
    required this.archiveHash,
    required this.archiveSizeBytes,
    required this.syncedAt,
    required this.machineId,
    required this.machineName,
    required this.os,
    this.triosVersion,
  });

  final int layoutVersion;

  /// Name of the folder inside the mods folder, e.g. `Nexerelin-0.12.1e`.
  final String folderName;

  /// From the folder's `mod_info.json`. Null if it has none or it couldn't be
  /// read.
  final String? modId;
  final String? modName;
  final String? modVersion;

  /// Hash of the folder's files. See `computeModContentHash`.
  final String contentHash;

  /// SHA-256 of the zip file itself.
  final String archiveHash;
  final int archiveSizeBytes;

  /// When TriOS wrote the mod to the sync folder (UTC).
  final DateTime syncedAt;
  final String machineId;
  final String machineName;
  final String os;
  final String? triosVersion;

  String get displayName => modName ?? modId ?? folderName;
}

/// `enabled-mods.json` at the root of the sync folder: the mods turned on, with
/// the active version of each.
@MappableClass()
class EnabledModListManifest with EnabledModListManifestMappable {
  const EnabledModListManifest({
    this.layoutVersion = saveSyncLayoutVersion,
    required this.contentHash,
    required this.mods,
    required this.syncedAt,
    required this.machineId,
    required this.machineName,
    required this.os,
    this.triosVersion,
  });

  final int layoutVersion;

  /// See `computeEnabledModListHash`.
  final String contentHash;
  final List<ShallowModVariant> mods;

  /// UTC.
  final DateTime syncedAt;
  final String machineId;
  final String machineName;
  final String os;
  final String? triosVersion;
}
