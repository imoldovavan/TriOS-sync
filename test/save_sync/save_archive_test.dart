import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_sync/save_archiver.dart';
import 'package:trios/save_sync/save_content_hash.dart';
import 'package:trios/save_sync/save_sync_backups.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trios_save_sync_test');
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// A fake save folder. Real save folders are never touched by these tests.
  Directory makeSave(String parent, String name, {String campaign = 'c1'}) {
    final folder = Directory(p.join(parent, name))..createSync(recursive: true);
    File(p.join(folder.path, 'descriptor.xml')).writeAsStringSync('<d/>');
    File(p.join(folder.path, 'campaign.xml')).writeAsStringSync(campaign);
    Directory(p.join(folder.path, 'sub dir')).createSync();
    File(p.join(folder.path, 'sub dir', 'extra.txt')).writeAsStringSync('x');
    return folder;
  }

  group("content hash", () {
    test("same content in different folders gives the same hash", () async {
      final a = makeSave(p.join(temp.path, 'a'), 'save_one');
      final b = makeSave(p.join(temp.path, 'b with space'), 'save_one');
      expect(await computeSaveContentHash(a), await computeSaveContentHash(b));
    });

    test("changed content or a renamed file changes the hash", () async {
      final a = makeSave(temp.path, 'save_a');
      final b = makeSave(temp.path, 'save_b', campaign: 'c2');
      final original = await computeSaveContentHash(a);
      expect(await computeSaveContentHash(b), isNot(original));

      File(p.join(a.path, 'campaign.xml'))
          .renameSync(p.join(a.path, 'campaign2.xml'));
      expect(await computeSaveContentHash(a), isNot(original));
    });

    test("file times and OS junk files don't change the hash", () async {
      final a = makeSave(temp.path, 'save_a');
      final original = await computeSaveContentHash(a);
      File(p.join(a.path, 'campaign.xml')).setLastModifiedSync(DateTime(2001));
      File(p.join(a.path, 'Thumbs.db')).writeAsStringSync('junk');
      File(p.join(a.path, '.DS_Store')).writeAsStringSync('junk');
      expect(await computeSaveContentHash(a), original);
    });

    test("relative paths use forward slashes", () {
      final a = makeSave(temp.path, 'save_a');
      expect(listSaveFiles(a).keys, [
        'campaign.xml',
        'descriptor.xml',
        'sub dir/extra.txt',
      ]);
    });
  });

  group("archive round trip", () {
    test("zip and extract keeps every file and the hash", () async {
      final save = makeSave(temp.path, 'save_a');
      final zip = File(p.join(temp.path, 'save_a.zip'));
      await archiveSaveFolder(save, zip);

      expect(zip.existsSync(), isTrue);
      expect(File('${zip.path}.tmp').existsSync(), isFalse);

      final names = ZipDecoder()
          .decodeBytes(zip.readAsBytesSync())
          .files
          .map((f) => f.name)
          .toList();
      expect(names, everyElement(isNot(contains('\\'))));

      final extracted = Directory(p.join(temp.path, 'out'));
      await extractSaveArchive(zip, extracted);
      expect(
        await computeSaveContentHash(extracted),
        await computeSaveContentHash(save),
      );
    });

    test(
      "unsafe entry names are rejected before anything is written",
      () async {
        expect(isSafeArchiveEntryName('campaign.xml'), isTrue);
        expect(isSafeArchiveEntryName('a/b.xml'), isTrue);
        expect(isSafeArchiveEntryName('../evil.xml'), isFalse);
        expect(isSafeArchiveEntryName('a/../../evil.xml'), isFalse);
        expect(isSafeArchiveEntryName('/etc/passwd'), isFalse);
        expect(isSafeArchiveEntryName('C:/evil.xml'), isFalse);
        expect(isSafeArchiveEntryName('a\\..\\evil.xml'), isFalse);

        final archive = Archive()
          ..addFile(ArchiveFile.string('../evil.txt', 'bad'));
        final zip = File(p.join(temp.path, 'evil.zip'))
          ..writeAsBytesSync(ZipEncoder().encode(archive));
        final out = Directory(p.join(temp.path, 'out'));

        await expectLater(
          extractSaveArchive(zip, out),
          throwsA(isA<UnsafeArchiveEntryException>()),
        );
        expect(File(p.join(temp.path, 'evil.txt')).existsSync(), isFalse);
      },
    );
  });

  group("installSaveFromArchive", () {
    late Directory saves;
    late SaveSyncBackups backups;

    setUp(() {
      saves = Directory(p.join(temp.path, 'saves'))..createSync();
      backups = SaveSyncBackups(Directory(p.join(temp.path, 'backups')));
    });

    Future<void> moveToBackups(Directory replaced) => backups.backUpSaveFolder(
      replaced,
      'save_a',
      SaveSyncBackupReason.beforePull,
    );

    test("replaces the local save and backs up the old one", () async {
      final remote = makeSave(
        p.join(temp.path, 'remote'),
        'save_a',
        campaign: 'new',
      );
      final zip = File(p.join(temp.path, 'save_a.zip'));
      await archiveSaveFolder(remote, zip);
      makeSave(saves.path, 'save_a', campaign: 'old');

      await installSaveFromArchive(
        zipFile: zip,
        savesFolder: saves,
        saveFolderName: 'save_a',
        moveReplacedSave: moveToBackups,
      );

      expect(
        File(p.join(saves.path, 'save_a', 'campaign.xml')).readAsStringSync(),
        'new',
      );
      // Only the save itself is left in the saves folder; no temp folders.
      expect(saves.listSync().map((e) => p.basename(e.path)), ['save_a']);

      final backedUp = backups.root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => p.basename(f.path) == 'campaign.xml')
          .single;
      expect(backedUp.readAsStringSync(), 'old');
    });

    test("a broken zip leaves the local save unchanged", () async {
      final local = makeSave(saves.path, 'save_a', campaign: 'old');
      final hashBefore = await computeSaveContentHash(local);
      final zip = File(p.join(temp.path, 'broken.zip'))
        ..writeAsStringSync('this is not a zip');

      await expectLater(
        installSaveFromArchive(
          zipFile: zip,
          savesFolder: saves,
          saveFolderName: 'save_a',
          moveReplacedSave: moveToBackups,
        ),
        throwsA(anything),
      );

      expect(await computeSaveContentHash(local), hashBefore);
      expect(saves.listSync().map((e) => p.basename(e.path)), ['save_a']);
      expect(backups.root.existsSync(), isFalse);
    });

    test("installs a save that doesn't exist locally yet", () async {
      final remote = makeSave(p.join(temp.path, 'remote'), 'save_a');
      final zip = File(p.join(temp.path, 'save_a.zip'));
      await archiveSaveFolder(remote, zip);

      await installSaveFromArchive(
        zipFile: zip,
        savesFolder: saves,
        saveFolderName: 'save_a',
        moveReplacedSave: (_) async => fail('nothing should be replaced'),
      );

      expect(
        await computeSaveContentHash(Directory(p.join(saves.path, 'save_a'))),
        await computeSaveContentHash(remote),
      );
    });
  });

  group("backups", () {
    test("backup folder names are timestamped and never reused", () {
      final backups = SaveSyncBackups(temp);
      final now = DateTime(2026, 11, 4, 15, 20, 0);
      final first = backups.createBackupFolder(
        'save_a',
        SaveSyncBackupReason.conflictLocal,
        now: now,
      );
      final second = backups.createBackupFolder(
        'save_a',
        SaveSyncBackupReason.conflictLocal,
        now: now,
      );
      expect(p.basename(first.path), '2026-11-04_15-20-00_conflict-local');
      expect(p.basename(second.path), '2026-11-04_15-20-00_conflict-local_2');
    });

    test("copying files keeps the originals; moving removes them", () async {
      final backups = SaveSyncBackups(Directory(p.join(temp.path, 'b')));
      final zip = File(p.join(temp.path, 'save_a.zip'))
        ..writeAsStringSync('zip');

      final copied = await backups.backUpFiles(
        [zip],
        'save_a',
        SaveSyncBackupReason.conflictSynced,
      );
      expect(zip.existsSync(), isTrue);
      expect(File(p.join(copied.path, 'save_a.zip')).readAsStringSync(), 'zip');

      await backups.backUpFiles(
        [zip],
        'save_a',
        SaveSyncBackupReason.cloudConflictCopy,
        move: true,
      );
      expect(zip.existsSync(), isFalse);
    });
  });
}
