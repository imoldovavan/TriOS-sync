import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_sync/folder_save_sync_backend.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/models/save_sync_manifest.dart';
import 'package:trios/save_sync/save_sync_backend.dart';

void main() {
  late Directory temp;
  late Directory syncFolder;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trios_save_sync_backend');
    syncFolder = Directory(p.join(temp.path, 'My Libraries', 'trios-sync'))
      ..createSync(recursive: true);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  SaveSyncManifest manifest(String name, {String hash = 'h1'}) =>
      SaveSyncManifest(
        saveFolderName: name,
        characterName: 'Ionut',
        contentHash: hash,
        archiveHash: 'zip-$hash',
        archiveSizeBytes: 3,
        syncedAt: DateTime.utc(2026, 11, 4),
        machineId: 'machine-a',
        machineName: 'DESKTOP',
        os: 'windows',
      );

  File localFile(String name, String contents) =>
      File(p.join(temp.path, name))..writeAsStringSync(contents);

  test(
    "refuses a sync folder that doesn't exist, without creating it",
    () async {
      final missing = Directory(p.join(temp.path, 'not mounted'));
      await expectLater(
        FolderSaveSyncBackend(missing).prepare(),
        throwsA(isA<SaveSyncException>()),
      );
      expect(missing.existsSync(), isFalse);
    },
  );

  test("first use creates the marker and subfolders", () async {
    await FolderSaveSyncBackend(syncFolder).prepare();
    expect(
      File(p.join(syncFolder.path, 'trios-save-sync.json')).existsSync(),
      isTrue,
    );
    expect(Directory(p.join(syncFolder.path, 'saves')).existsSync(), isTrue);
    expect(Directory(p.join(syncFolder.path, 'locks')).existsSync(), isTrue);
  });

  test("refuses a folder written by a newer layout", () async {
    File(p.join(syncFolder.path, 'trios-save-sync.json'))
        .writeAsStringSync('{"layoutVersion": 99}');
    await expectLater(
      FolderSaveSyncBackend(syncFolder).prepare(),
      throwsA(
        isA<SaveSyncException>().having(
          (e) => e.message,
          'message',
          contains('newer version of TriOS'),
        ),
      ),
    );
  });

  test("one machine uploads, another downloads", () async {
    final machineA = FolderSaveSyncBackend(syncFolder);
    final machineB = FolderSaveSyncBackend(syncFolder);
    await machineA.prepare();
    await machineB.prepare();

    await machineA.uploadSave(
      localFile('a.zip', 'zip'),
      manifest('save_my campaign_1'),
    );

    final listing = await machineB.listSaves();
    expect(listing.manifests.keys, ['save_my campaign_1']);
    expect(listing.archiveNames, {'save_my campaign_1'});
    expect(
      listing.manifests['save_my campaign_1'],
      manifest('save_my campaign_1'),
    );

    final downloaded = File(p.join(temp.path, 'downloaded.zip'));
    await machineB.downloadArchive('save_my campaign_1', downloaded);
    expect(downloaded.readAsStringSync(), 'zip');

    // No temp files left behind for the cloud client to upload.
    final names = Directory(p.join(syncFolder.path, 'saves'))
        .listSync()
        .map((e) => p.basename(e.path));
    expect(names, everyElement(isNot(endsWith('.tmp'))));
  });

  test("manifests are UTF-8 JSON with \\n line endings", () async {
    final backend = FolderSaveSyncBackend(syncFolder);
    await backend.prepare();
    await backend.uploadSave(
      localFile('a.zip', 'zip'),
      manifest('save_Ünïcödé_1'),
    );
    final bytes = File(
      p.join(syncFolder.path, 'saves', 'save_Ünïcödé_1.manifest.json'),
    ).readAsBytesSync();
    expect(bytes, isNot(contains(13))); // no \r
    expect((await backend.listSaves()).manifests.keys, ['save_Ünïcödé_1']);
  });

  test(
    "listing skips temp files and reports conflict copies separately",
    () async {
      final backend = FolderSaveSyncBackend(syncFolder);
      await backend.prepare();
      await backend.uploadSave(localFile('a.zip', 'zip'), manifest('save_a_1'));

      final saves = p.join(syncFolder.path, 'saves');
      File(p.join(saves, 'save_b_2.zip.tmp')).writeAsStringSync('partial');
      File(p.join(saves, 'save_a_1 (SFConflict ionut 2026-11-04-15-20-00).zip'))
          .writeAsStringSync('other');
      File(
        p.join(
          saves,
          'save_a_1.manifest (SFConflict ionut 2026-11-04-15-20-00).json',
        ),
      ).writeAsStringSync('{}');
      File(p.join(saves, 'save_c_3.manifest.json')).writeAsStringSync('{oops');

      final listing = await backend.listSaves();
      expect(listing.manifests.keys, ['save_a_1']);
      expect(listing.archiveNames, {'save_a_1'});
      expect(listing.conflictCopies, hasLength(2));
      expect(listing.saveNamesWithConflictCopies, {'save_a_1'});
      expect(listing.unreadableManifests.keys, ['save_c_3']);
    },
  );

  test("taking a conflict copy moves it out of the sync folder", () async {
    final backend = FolderSaveSyncBackend(syncFolder);
    await backend.prepare();
    final copyName = 'save_a_1 (SFConflict ionut 2026-11-04-15-20-00).zip';
    final copyFile = File(p.join(syncFolder.path, 'saves', copyName))
      ..writeAsStringSync('other');

    final listing = await backend.listSaves();
    final destination = File(p.join(temp.path, 'backup.zip'));
    await backend.takeConflictCopy(listing.conflictCopies.single, destination);

    expect(destination.readAsStringSync(), 'other');
    expect(copyFile.existsSync(), isFalse);
  });

  test("each machine writes and removes only its own lock file", () async {
    final backend = FolderSaveSyncBackend(syncFolder);
    await backend.prepare();
    final lockA = SaveSyncLock(
      machineId: 'machine-a',
      machineName: 'DESKTOP',
      os: 'windows',
      startedAt: DateTime.utc(2026, 11, 4, 10),
    );
    final lockB = SaveSyncLock(
      machineId: 'machine-b',
      machineName: 'linux-box',
      os: 'linux',
      startedAt: DateTime.utc(2026, 11, 4, 11),
    );
    await backend.writeLock(lockA);
    await backend.writeLock(lockB);
    expect(await backend.readLocks(), unorderedEquals([lockA, lockB]));

    await backend.removeLock('machine-a');
    expect(await backend.readLocks(), [lockB]);
  });

  test("a stalled read fails and leaves no partial file", () async {
    final destination = File(p.join(temp.path, 'partial.zip'));
    final controller = StreamController<List<int>>();
    controller.add([1, 2, 3]); // then nothing more ever arrives

    await expectLater(
      copyWithStallTimeout(
        controller.stream,
        destination,
        const Duration(milliseconds: 100),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(destination.existsSync(), isFalse);
    await controller.close();
  });

  test("stall errors become a readable message", () async {
    final backend = FolderSaveSyncBackend(syncFolder);
    await backend.prepare();
    await expectLater(
      backend.downloadArchive('save_missing', File(p.join(temp.path, 'x.zip'))),
      throwsA(
        isA<SaveSyncException>().having(
          (e) => e.message,
          'message',
          contains('cloud client may be offline'),
        ),
      ),
    );
  });
}
