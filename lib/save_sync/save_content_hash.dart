import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Files the OS or a file manager drops into folders. They are left out of
/// hashes and archives, so they never make a save look changed.
const _ignoredFileNames = {'.ds_store', 'thumbs.db', 'desktop.ini'};

bool isIgnoredSaveFile(String fileName) =>
    _ignoredFileNames.contains(fileName.toLowerCase());

/// Every file in [saveFolder] that belongs in a hash or archive, keyed by its
/// path relative to [saveFolder] with `/` separators, sorted by that path.
Map<String, File> listSaveFiles(Directory saveFolder) {
  final files = <String, File>{};
  for (final entity in saveFolder.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (isIgnoredSaveFile(p.basename(entity.path))) continue;
    final relative = p
        .relative(entity.path, from: saveFolder.path)
        .replaceAll('\\', '/');
    files[relative] = entity;
  }
  final sortedKeys = files.keys.toList()..sort();
  return {for (final key in sortedKeys) key: files[key]!};
}

/// A hash of the save's contents that is the same on every OS: SHA-256 over
/// each file's relative path (with `/`) and the SHA-256 of its contents,
/// sorted by path. File times are not part of it, because cloud clients
/// change them.
///
/// Runs on a background isolate; saves can be hundreds of MB.
Future<String> computeSaveContentHash(Directory saveFolder) {
  final path = saveFolder.path;
  return Isolate.run(() => _computeSaveContentHashSync(Directory(path)));
}

Future<String> _computeSaveContentHashSync(Directory saveFolder) async {
  final buffer = StringBuffer();
  for (final entry in listSaveFiles(saveFolder).entries) {
    final fileHash = await sha256.bind(entry.value.openRead()).first;
    buffer.write('${entry.key}\u0000$fileHash\n');
  }
  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

/// SHA-256 of one file, read as a stream.
Future<String> computeFileHash(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();
