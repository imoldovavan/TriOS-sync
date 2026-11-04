import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/extensions.dart';

/// Why something was moved into backups. Used in the backup folder's name.
enum SaveSyncBackupReason {
  beforePull('before-pull'),
  conflictLocal('conflict-local'),
  conflictSynced('conflict-synced'),
  cloudConflictCopy('cloud-conflict-copy');

  const SaveSyncBackupReason(this.folderSuffix);

  final String folderSuffix;
}

/// Local backups of anything save sync replaces, at
/// `<root>/<save folder name>/<yyyy-MM-dd_HH-mm-ss>_<reason>/`.
///
/// Backups stay on this PC, outside the sync folder, so they are never
/// uploaded. Nothing here deletes a backup.
class SaveSyncBackups {
  SaveSyncBackups(this.root);

  final Directory root;

  static final _timestampFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  /// Creates and returns a new, empty backup folder.
  Directory createBackupFolder(
    String saveFolderName,
    SaveSyncBackupReason reason, {
    DateTime? now,
  }) {
    final baseName =
        '${_timestampFormat.format(now ?? DateTime.now())}_${reason.folderSuffix}';
    final parent = Directory(p.join(root.path, saveFolderName));
    var folder = Directory(p.join(parent.path, baseName));
    for (var i = 2; folder.existsSync(); i++) {
      folder = Directory(p.join(parent.path, '${baseName}_$i'));
    }
    folder.createSync(recursive: true);
    return folder;
  }

  /// Moves [saveFolder] into a new backup folder as `<backup>/<saveFolderName>`,
  /// so it can be copied straight back into the saves folder to restore it.
  Future<Directory> backUpSaveFolder(
    Directory saveFolder,
    String saveFolderName,
    SaveSyncBackupReason reason,
  ) async {
    final backupFolder = createBackupFolder(saveFolderName, reason);
    final destination = Directory(p.join(backupFolder.path, saveFolderName));
    await moveDirectoryVerified(saveFolder, destination);
    return destination;
  }

  /// Copies (or, with [move], moves) [files] into one new backup folder.
  Future<Directory> backUpFiles(
    List<File> files,
    String saveFolderName,
    SaveSyncBackupReason reason, {
    bool move = false,
  }) async {
    final backupFolder = createBackupFolder(saveFolderName, reason);
    for (final file in files) {
      final destination = File(
        p.join(backupFolder.path, p.basename(file.path)),
      );
      await file.copy(destination.path);
      if (await destination.length() != await file.length()) {
        throw FileSystemException(
          'Backup copy is incomplete; the original was kept.',
          file.path,
        );
      }
      if (move) await file.delete();
    }
    return backupFolder;
  }
}

/// Moves [source] to [destination]. Tries a rename first. If that fails
/// (e.g. different drives), copies, checks that every file arrived with the
/// same size, and only then deletes [source].
Future<void> moveDirectoryVerified(
  Directory source,
  Directory destination,
) async {
  try {
    source.renameSync(destination.path);
    return;
  } on FileSystemException {
    // Fall through to copy.
  }

  await source.copyDirectory(destination);
  final sourceSizes = _fileSizes(source);
  final copiedSizes = _fileSizes(destination);
  final complete =
      sourceSizes.length == copiedSizes.length &&
      sourceSizes.entries.every((e) => copiedSizes[e.key] == e.value);
  if (!complete) {
    throw FileSystemException(
      'Copy to backups is incomplete; the original was kept.',
      source.path,
    );
  }
  source.deleteSync(recursive: true);
}

Map<String, int> _fileSizes(Directory folder) => {
  for (final file in folder.listSync(recursive: true).whereType<File>())
    p.relative(file.path, from: folder.path): file.lengthSync(),
};
