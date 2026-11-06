import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/folder_save_sync_backend.dart';
import 'package:trios/save_sync/models/mod_sync_manifest.dart';
import 'package:trios/save_sync/save_sync_backend.dart';

void main() {
  late Directory temp;
  late Directory syncFolder;
  late FolderSaveSyncBackend backend;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trios_mod_sync_backend');
    syncFolder = Directory(p.join(temp.path, 'sync'))..createSync();
    backend = FolderSaveSyncBackend(syncFolder);
    await backend.prepare();
  });
  tearDown(() => temp.delete(recursive: true));

  ModSyncManifest manifest(String folderName) => ModSyncManifest(
    folderName: folderName,
    modId: 'nexerelin',
    modName: 'Nexerelin',
    modVersion: '0.12.1e',
    contentHash: 'h1',
    archiveHash: 'z1',
    archiveSizeBytes: 3,
    syncedAt: DateTime.utc(2026, 11, 6),
    machineId: 'machine-a',
    machineName: 'DESKTOP',
    os: 'windows',
  );

  File localFile(String name, String contents) =>
      File(p.join(temp.path, name))..writeAsStringSync(contents);

  test('an untouched sync folder has no mods and no list', () async {
    final listing = await backend.listMods();
    expect(listing.manifests, isEmpty);
    expect(listing.enabledModList, isNull);
    expect(Directory(p.join(syncFolder.path, 'mods')).existsSync(), isFalse);
  });

  test('upload, list, and download a mod', () async {
    await backend.uploadMod(localFile('a.zip', 'zip'), manifest('Nexerelin'));

    final listing = await backend.listMods();
    expect(listing.manifests['Nexerelin']?.modVersion, '0.12.1e');
    expect(listing.archiveNames, {'Nexerelin'});
    expect(
      syncFolder
          .listSync(recursive: true)
          .where((e) => e.path.endsWith('.tmp')),
      isEmpty,
    );

    final copy = File(p.join(temp.path, 'copy.zip'));
    await backend.downloadModArchive('Nexerelin', copy);
    expect(copy.readAsStringSync(), 'zip');
  });

  test('takeMod moves the zip and manifest out of the sync folder', () async {
    await backend.uploadMod(localFile('a.zip', 'zip'), manifest('Nexerelin'));
    final backup = Directory(p.join(temp.path, 'backup'));

    await backend.takeMod('Nexerelin', backup);

    expect((await backend.listMods()).manifests, isEmpty);
    expect(File(p.join(backup.path, 'Nexerelin.zip')).existsSync(), isTrue);
    expect(
      File(p.join(backup.path, 'Nexerelin.manifest.json')).existsSync(),
      isTrue,
    );
  });

  test('writes and reads the enabled-mods list', () async {
    await backend.writeEnabledModList(
      EnabledModListManifest(
        contentHash: 'list-hash',
        mods: const [ShallowModVariant(modId: 'a', smolVariantId: 'a-1')],
        syncedAt: DateTime.utc(2026, 11, 6),
        machineId: 'machine-a',
        machineName: 'DESKTOP',
        os: 'windows',
      ),
    );
    final file = File(p.join(syncFolder.path, enabledModListFileName));
    expect(file.readAsStringSync(), isNot(contains('\r\n')));

    final list = (await backend.listMods()).enabledModList;
    expect(list?.contentHash, 'list-hash');
    expect(list?.mods.single.smolVariantId, 'a-1');
  });

  test('a damaged enabled-mods list is reported, not thrown', () async {
    File(p.join(syncFolder.path, enabledModListFileName))
        .writeAsStringSync('{not json');
    final listing = await backend.listMods();
    expect(listing.enabledModList, isNull);
    expect(listing.enabledModListProblem, isNotNull);
  });

  test('finds conflict copies under mods/ and of the list', () async {
    await backend.uploadMod(localFile('a.zip', 'zip'), manifest('Nexerelin'));
    File(
      p.join(
        syncFolder.path,
        'mods',
        'Nexerelin (SFConflict ionut 2026-11-06-10-00-00).zip',
      ),
    ).writeAsStringSync('other');
    File(
      p.join(
        syncFolder.path,
        'enabled-mods (SFConflict ionut 2026-11-06-10-00-00).json',
      ),
    ).writeAsStringSync('{}');

    final listing = await backend.listMods();
    expect(listing.modNamesWithConflictCopies, {'Nexerelin'});
    expect(listing.enabledModListHasConflictCopy, isTrue);
    expect(listing.archiveNames, {'Nexerelin'});

    final listCopy = listing.conflictCopies.firstWhere(
      (c) => c.originalFileName == enabledModListFileName,
    );
    final moved = File(p.join(temp.path, 'moved.json'));
    await backend.takeModConflictCopy(listCopy, moved);
    expect(moved.existsSync(), isTrue);
    expect((await backend.listMods()).enabledModListHasConflictCopy, isFalse);
  });

  test('two PCs see the same mods through one folder', () async {
    await backend.uploadMod(localFile('a.zip', 'zip'), manifest('Nexerelin'));
    final otherPc = FolderSaveSyncBackend(syncFolder);
    await otherPc.prepare();
    expect((await otherPc.listMods()).manifests.keys, ['Nexerelin']);
  });
}
