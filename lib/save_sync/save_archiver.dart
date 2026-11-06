import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_sync/mod_sync_items.dart';
import 'package:trios/save_sync/save_content_hash.dart';

/// Prefix for TriOS's temporary folders inside the saves folder. Starsector
/// only lists folders starting with `save`, so these never show up in-game.
const _incomingPrefix = '.trios-sync-incoming-';
const _outgoingPrefix = '.trios-sync-outgoing-';

/// Thrown when a zip holds a path that would land outside the save folder.
class UnsafeArchiveEntryException implements Exception {
  UnsafeArchiveEntryException(this.entryName);

  final String entryName;

  @override
  String toString() =>
      'The archive contains an unsafe path and was not extracted: $entryName';
}

/// Zips the contents of [saveFolder] into [zipFile]. Paths inside the zip are
/// relative to the save folder and use `/`.
///
/// Writes to a `.tmp` file next to [zipFile] and renames it when done, so a
/// failed run never leaves a half-written zip at [zipFile].
Future<void> archiveSaveFolder(Directory saveFolder, File zipFile) =>
    _archiveFolder(saveFolder, zipFile, isMod: false);

/// Same as [archiveSaveFolder], with the files from `listModFiles`, so a
/// disabled `mod_info.json` is stored as `mod_info.json`.
Future<void> archiveModFolder(Directory modFolder, File zipFile) =>
    _archiveFolder(modFolder, zipFile, isMod: true);

Future<void> _archiveFolder(
  Directory folder,
  File zipFile, {
  required bool isMod,
}) {
  final sourcePath = folder.path;
  final zipPath = zipFile.path;
  return Isolate.run(() {
    final tempPath = '$zipPath.tmp';
    final encoder = ZipFileEncoder()..create(tempPath);
    try {
      final files = isMod
          ? listModFiles(Directory(sourcePath))
          : listSaveFiles(Directory(sourcePath));
      for (final entry in files.entries) {
        encoder.addFileSync(entry.value, entry.key);
      }
      encoder.closeSync();
      File(tempPath).renameSync(zipPath);
    } catch (_) {
      final tempFile = File(tempPath);
      if (tempFile.existsSync()) tempFile.deleteSync();
      rethrow;
    }
  });
}

/// True if [entryName] is a relative path that stays inside the folder it is
/// extracted to.
bool isSafeArchiveEntryName(String entryName) {
  final name = entryName.replaceAll('\\', '/');
  if (name.isEmpty || name.startsWith('/')) return false;
  // Windows drive letters, e.g. `C:/...`.
  if (RegExp(r'^[A-Za-z]:').hasMatch(name)) return false;
  return !name.split('/').contains('..');
}

/// Thrown when a zip is unreadable or doesn't hold a Starsector save.
class NotASaveArchiveException implements Exception {
  NotASaveArchiveException(this.zipPath);

  final String zipPath;

  @override
  String toString() =>
      'The archive is damaged or is not a Starsector save (no descriptor.xml): $zipPath';
}

/// Thrown when a zip is unreadable or holds no files.
class DamagedArchiveException implements Exception {
  DamagedArchiveException(this.zipPath);

  final String zipPath;

  @override
  String toString() => 'The archive is damaged or empty: $zipPath';
}

/// Extracts [zipFile] into [destination], which must not exist yet.
/// Checks every path, and that the zip holds a save, before writing anything.
Future<void> extractSaveArchive(File zipFile, Directory destination) =>
    _extractArchive(zipFile, destination, isMod: false);

/// Extracts a mod's zip into [destination], which must not exist yet.
Future<void> extractModArchive(File zipFile, Directory destination) =>
    _extractArchive(zipFile, destination, isMod: true);

Future<void> _extractArchive(
  File zipFile,
  Directory destination, {
  required bool isMod,
}) {
  final zipPath = zipFile.path;
  final destinationPath = destination.path;
  return Isolate.run(() {
    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      for (final entry in archive.files) {
        if (!isSafeArchiveEntryName(entry.name)) {
          throw UnsafeArchiveEntryException(entry.name);
        }
      }
      // The zip reader returns an empty archive for some damaged files
      // instead of throwing. Every save has a top-level descriptor.xml.
      if (!isMod &&
          !archive.files.any((entry) => entry.name == 'descriptor.xml')) {
        throw NotASaveArchiveException(zipPath);
      }
      if (isMod && !archive.files.any((entry) => entry.isFile)) {
        throw DamagedArchiveException(zipPath);
      }
      Directory(destinationPath).createSync(recursive: true);
      // Each entry is read from the zip file as it is written out, so a large
      // mod is never held in memory as a whole.
      for (final entry in archive.files) {
        final outPath = p.joinAll([
          destinationPath,
          ...entry.name.replaceAll('\\', '/').split('/'),
        ]);
        if (!entry.isFile) {
          Directory(outPath).createSync(recursive: true);
          continue;
        }
        Directory(p.dirname(outPath)).createSync(recursive: true);
        final output = OutputFileStream(outPath);
        try {
          entry.writeContent(output);
        } finally {
          output.closeSync();
        }
      }
    } finally {
      input.closeSync();
    }
  });
}

/// Puts the save in [zipFile] into `savesFolder/saveFolderName`.
///
/// The zip is fully extracted to a temp folder first. Only then is the current
/// save (if any) renamed out of the way and the new one renamed into place.
/// Both renames happen inside the saves folder, so neither copies data. If
/// anything fails, the current save is left as it was.
///
/// The replaced save is handed to [moveReplacedSave] (normally: move it to
/// backups). It is never deleted here.
Future<void> installSaveFromArchive({
  required File zipFile,
  required Directory savesFolder,
  required String saveFolderName,
  required Future<void> Function(Directory replacedSave) moveReplacedSave,
}) => _installFolder(
  target: Directory(p.join(savesFolder.path, saveFolderName)),
  incoming: Directory(
    p.join(savesFolder.path, '$_incomingPrefix$saveFolderName'),
  ),
  outgoing: Directory(
    p.join(savesFolder.path, '$_outgoingPrefix$saveFolderName'),
  ),
  extract: (destination) => extractSaveArchive(zipFile, destination),
  moveReplaced: moveReplacedSave,
);

/// Temp folder inside the mods folder for mods on their way in or out. Its
/// name starts with `.`, so mod sync skips it, and each mod's `mod_info.json`
/// sits two levels down, so neither the game nor TriOS loads it as a mod.
const modSyncTempFolderName = '.trios-sync-incoming';

/// Puts the mod in [zipFile] into `modsFolder/folderName`, the same way as
/// [installSaveFromArchive].
///
/// With [modInfoFileName], the top-level `mod_info.json` is renamed to it
/// before the folder is moved into place (e.g. to keep this PC's choice of
/// active version).
Future<void> installModFromArchive({
  required File zipFile,
  required Directory modsFolder,
  required String folderName,
  String? modInfoFileName,
  required Future<void> Function(Directory replacedMod) moveReplacedMod,
}) {
  final temp = p.join(modsFolder.path, modSyncTempFolderName);
  return _installFolder(
    target: Directory(p.join(modsFolder.path, folderName)),
    incoming: Directory(p.join(temp, 'in', folderName)),
    outgoing: Directory(p.join(temp, 'out', folderName)),
    extract: (destination) async {
      await extractModArchive(zipFile, destination);
      if (modInfoFileName == null) return;
      final current = currentModInfoFileName(destination);
      if (current != null && current != modInfoFileName) {
        File(p.join(destination.path, current))
            .renameSync(p.join(destination.path, modInfoFileName));
      }
    },
    moveReplaced: moveReplacedMod,
  );
}

Future<void> _installFolder({
  required Directory target,
  required Directory incoming,
  required Directory outgoing,
  required Future<void> Function(Directory destination) extract,
  required Future<void> Function(Directory replaced) moveReplaced,
}) async {
  // Left over from an earlier run that failed mid-extract. It only ever holds
  // a partial copy of data that still exists in the sync folder.
  if (incoming.existsSync()) incoming.deleteSync(recursive: true);
  // Left over from an earlier run that failed after replacing the folder.
  // This one may be the user's only copy of an older version, so back it up.
  if (outgoing.existsSync()) await moveReplaced(outgoing);
  incoming.parent.createSync(recursive: true);
  outgoing.parent.createSync(recursive: true);

  try {
    await extract(incoming);
  } catch (_) {
    if (incoming.existsSync()) incoming.deleteSync(recursive: true);
    rethrow;
  }

  final hadExisting = target.existsSync();
  if (hadExisting) {
    try {
      target.renameSync(outgoing.path);
    } catch (_) {
      incoming.deleteSync(recursive: true);
      rethrow;
    }
  }

  try {
    incoming.renameSync(target.path);
  } catch (_) {
    if (hadExisting) outgoing.renameSync(target.path);
    incoming.deleteSync(recursive: true);
    rethrow;
  }

  if (hadExisting) await moveReplaced(outgoing);
}
