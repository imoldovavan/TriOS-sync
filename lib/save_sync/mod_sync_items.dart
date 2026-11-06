import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/models/save_sync_state.dart';
import 'package:trios/save_sync/save_content_hash.dart';
import 'package:trios/trios/constants.dart';

/// Folders inside the mods folder that mod sync handles. Names starting with
/// `.` are skipped; TriOS's own temp folder is one of them.
List<String> listModFolderNames(Directory modsFolder) {
  if (!modsFolder.existsSync()) return [];
  return [
    for (final dir in modsFolder.listSync().whereType<Directory>())
      if (!p.basename(dir.path).startsWith('.')) p.basename(dir.path),
  ]..sort();
}

/// Every file in [modFolder] that belongs in a hash or zip, keyed by its path
/// relative to the folder with `/` separators, sorted by that path.
///
/// TriOS switches a mod's active version by renaming its top-level
/// `mod_info.json` (see [Constants.modInfoFileDisabledNames]). If the folder
/// has exactly one of those names, it is listed as `mod_info.json`, so the
/// switch doesn't count as a change to the folder.
Map<String, File> listModFiles(Directory modFolder) {
  final files = listSaveFiles(modFolder);
  final modInfoNames = files.keys
      .where(Constants.modInfoFileNames.contains)
      .toList();
  if (modInfoNames.length != 1 ||
      modInfoNames.single == Constants.modInfoFileName) {
    return files;
  }
  final renamed = {
    for (final entry in files.entries)
      entry.key == modInfoNames.single ? Constants.modInfoFileName : entry.key:
          entry.value,
  };
  final sortedKeys = renamed.keys.toList()..sort();
  return {for (final key in sortedKeys) key: renamed[key]!};
}

/// The name of [modFolder]'s top-level `mod_info.json`, enabled or disabled.
/// Null if it has none.
String? currentModInfoFileName(Directory modFolder) {
  for (final name in Constants.modInfoFileNames) {
    if (File(p.join(modFolder.path, name)).existsSync()) return name;
  }
  return null;
}

/// File count, total size, and newest file time of [modFolder]. Only reads
/// file sizes and times, not contents.
Future<ModFolderFingerprint> computeModFingerprint(Directory modFolder) {
  final path = modFolder.path;
  return Isolate.run(() {
    var count = 0;
    var bytes = 0;
    var newest = 0;
    for (final file in listModFiles(Directory(path)).values) {
      final stat = file.statSync();
      count++;
      bytes += stat.size;
      final modified = stat.modified.millisecondsSinceEpoch;
      if (modified > newest) newest = modified;
    }
    return ModFolderFingerprint(
      fileCount: count,
      totalBytes: bytes,
      newestModifiedMs: newest,
    );
  });
}

/// Same as `computeSaveContentHash`, over [listModFiles].
Future<String> computeModContentHash(Directory modFolder) {
  final path = modFolder.path;
  return Isolate.run(() async {
    final buffer = StringBuffer();
    for (final entry in listModFiles(Directory(path)).entries) {
      final fileHash = await sha256.bind(entry.value.openRead()).first;
      buffer.write('${entry.key}\u0000$fileHash\n');
    }
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  });
}

/// Hash of an enabled-mods list. Order and duplicates don't matter.
String computeEnabledModListHash(List<ShallowModVariant> mods) {
  final ids = mods.map((m) => m.smolVariantId).toSet().toList()..sort();
  return sha256.convert(utf8.encode(ids.join('\n'))).toString();
}
