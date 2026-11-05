import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vmparams/vmparams_manager.dart';

const _savesPathKey = '-Dcom.fs.starfarer.settings.paths.saves';

/// Matches the saves path argument, e.g.
/// `-Dcom.fs.starfarer.settings.paths.saves=../saves`,
/// `-Dcom.fs.starfarer.settings.paths.saves="C:\My Saves"`, or
/// `"-Dcom.fs.starfarer.settings.paths.saves=C:\My Saves"`.
final _savesPathRegex = RegExp(
  '(["\']?)${RegExp.escape(_savesPathKey)}='
  '(?:"([^"]*)"|\'([^\']*)\'|(.*?)\\1(?=\\s|\$))',
);

/// The saves path written in a vmparams file (or launch script), as written.
/// Null if the file doesn't set one.
String? readSavesPathFromVmparams(String vmparamsContent) {
  final match = _savesPathRegex.firstMatch(vmparamsContent);
  if (match == null) return null;
  final value = (match.group(2) ?? match.group(3) ?? match.group(4))?.trim();
  return value == null || value.isEmpty ? null : value;
}

/// The game runs from its core folder, so relative paths in vmparams are
/// relative to it. This is how TriOS's direct launch reads them too.
Directory resolveVmparamsPath(String value, Directory gameCoreFolder) =>
    Directory(p.normalize(p.join(gameCoreFolder.absolute.path, value)));

bool isSameFolder(Directory a, Directory b) =>
    p.equals(p.normalize(a.absolute.path), p.normalize(b.absolute.path));

/// TriOS and the game use different saves folders.
class SavesFolderMismatch {
  const SavesFolderMismatch({
    required this.triosSavesFolder,
    required this.gameSavesFolder,
    required this.vmparamsFile,
  });

  /// The folder TriOS (and save sync) reads.
  final Directory triosSavesFolder;

  /// The folder the vmparams file tells the game to use.
  final Directory gameSavesFolder;
  final File vmparamsFile;

  String get message =>
      'The game saves to ${gameSavesFolder.path} (set in '
      '${p.basename(vmparamsFile.path)}), but TriOS reads saves from '
      '${triosSavesFolder.path}. Save sync is paused so it does not sync '
      'the wrong folder.';
}

/// Compares the saves folder TriOS uses with the one in the vmparams file
/// TriOS launches with. Null when they match, when the file sets no saves
/// path, or when either can't be read.
final savesFolderMismatchProvider = FutureProvider<SavesFolderMismatch?>((
  ref,
) async {
  final triosSavesFolder = ref.watch(AppState.savesFolder).value;
  final gameCoreFolder = ref.watch(AppState.gameCoreFolder).value;
  final vmparams = await ref.watch(vmparamsManagerProvider.future);
  // The same file TriOS's direct launch uses.
  final vmparamsFile = vmparams.selectedVmparamsFiles.firstOrNull;
  if (triosSavesFolder == null ||
      gameCoreFolder == null ||
      vmparamsFile == null) {
    return null;
  }

  try {
    final value = readSavesPathFromVmparams(
      await vmparamsFile.readAsString(),
    );
    if (value == null) return null;
    final gameSavesFolder = resolveVmparamsPath(value, gameCoreFolder);
    if (isSameFolder(gameSavesFolder, triosSavesFolder)) return null;
    return SavesFolderMismatch(
      triosSavesFolder: triosSavesFolder,
      gameSavesFolder: gameSavesFolder,
      vmparamsFile: vmparamsFile,
    );
  } catch (e) {
    Fimber.w('Could not read the saves path from ${vmparamsFile.path}: $e');
    return null;
  }
});
