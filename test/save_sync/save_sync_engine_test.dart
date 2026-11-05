import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_sync/folder_save_sync_backend.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/models/save_sync_state.dart';
import 'package:trios/save_sync/save_content_hash.dart';
import 'package:trios/save_sync/save_sync_backend.dart';
import 'package:trios/save_sync/save_sync_backups.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/utils/logging.dart';

class _MemoryStateStore implements SaveSyncStateStore {
  SaveSyncState state = const SaveSyncState();

  @override
  Future<SaveSyncState> read() async => state;

  @override
  Future<void> update(SaveSyncState Function(SaveSyncState) mutator) async {
    state = mutator(state);
  }
}

/// One simulated PC: its own saves folder, backups, temp folder and sync
/// records, sharing the sync folder with the other PC. No real saves folder
/// is ever touched.
class _Machine {
  _Machine(Directory root, String id, Directory syncFolder, DateTime now)
    : savesFolder = Directory(p.join(root.path, id, 'saves'))
        ..createSync(recursive: true),
      backups = SaveSyncBackups(Directory(p.join(root.path, id, 'backups'))),
      store = _MemoryStateStore() {
    engine = SaveSyncEngine(
      backend: FolderSaveSyncBackend(syncFolder),
      savesFolder: savesFolder,
      backups: backups,
      machine: SaveSyncMachine(id: id, name: 'PC $id', os: 'test'),
      stateStore: store,
      tempFolder: Directory(p.join(root.path, id, 'temp')),
      gameVersion: '0.98a-RC8',
      clock: () => now,
    );
  }

  final Directory savesFolder;
  final SaveSyncBackups backups;
  final _MemoryStateStore store;
  late final SaveSyncEngine engine;

  Directory save(String name) => Directory(p.join(savesFolder.path, name));

  void writeSave(String name, String campaign) {
    final folder = save(name)..createSync(recursive: true);
    File(p.join(folder.path, 'descriptor.xml')).writeAsStringSync('''
<SaveGameData>
  <characterName>Ionut</characterName>
  <characterLevel>5</characterLevel>
  <saveDate>2026-11-04 15:20:00.00 UTC</saveDate>
  <allModsEverEnabled>
    <EnabledModData><spec z="1"><id>lw_lazylib</id><name>LazyLib</name>
      <versionInfo><string>2.8b</string><major>2</major><minor>8b</minor><patch>0</patch></versionInfo>
    </spec></EnabledModData>
  </allModsEverEnabled>
  <enabledMods><EnabledModData><spec ref="1"/></EnabledModData></enabledMods>
</SaveGameData>''');
    File(p.join(folder.path, 'campaign.xml')).writeAsStringSync(campaign);
  }

  String campaign(String name) =>
      File(p.join(save(name).path, 'campaign.xml')).readAsStringSync();

  Future<SaveSyncItem> status(String name) async =>
      (await engine.loadOverview({name})).item(name)!;

  List<File> backupFiles() => backups.root.existsSync()
      ? backups.root.listSync(recursive: true).whereType<File>().toList()
      : [];
}

void main() {
  late Directory temp;
  late Directory syncFolder;
  late _Machine a;
  late _Machine b;
  final now = DateTime.utc(2026, 11, 4, 15, 30);
  const save = 'save_my campaign_123';

  setUpAll(() => configureLogging(LoggingSettings(consoleOnly: true)));

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trios_save_sync_engine');
    syncFolder = Directory(p.join(temp.path, 'sync'))..createSync();
    a = _Machine(temp, 'a', syncFolder, now);
    b = _Machine(temp, 'b', syncFolder, now);
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  test("a new save is pushed from one PC and pulled on the other", () async {
    a.writeSave(save, 'day 1');
    expect((await a.status(save)).status, SaveSyncItemStatus.willPush);

    await a.engine.push(save);
    expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);

    final onB = await b.status(save);
    expect(onB.status, SaveSyncItemStatus.willPull);
    expect(onB.remoteManifest?.machineName, 'PC a');
    expect(onB.remoteManifest?.characterName, 'Ionut');
    expect(onB.remoteManifest?.mods.single.modId, 'lw_lazylib');

    await b.engine.pull(onB);
    expect(b.campaign(save), 'day 1');
    expect((await b.status(save)).status, SaveSyncItemStatus.upToDate);
  });

  test(
    "playing on one PC pulls on the other and backs up the old save",
    () async {
      a.writeSave(save, 'day 1');
      await a.engine.push(save);
      await b.engine.pull(await b.status(save));

      b.writeSave(save, 'day 2');
      expect((await b.status(save)).status, SaveSyncItemStatus.willPush);
      await b.engine.push(save);

      final onA = await a.status(save);
      expect(onA.status, SaveSyncItemStatus.willPull);
      await a.engine.pull(onA);
      expect(a.campaign(save), 'day 2');

      final backedUp = a.backupFiles().where(
        (f) => p.basename(f.path) == 'campaign.xml',
      );
      expect(backedUp.single.readAsStringSync(), 'day 1');
      expect(backedUp.single.path, contains('before-pull'));
    },
  );

  test("file times changing alone doesn't count as a change", () async {
    a.writeSave(save, 'day 1');
    await a.engine.push(save);
    for (final file in syncFolder.listSync(recursive: true).whereType<File>()) {
      file.setLastModifiedSync(DateTime(2030));
    }
    for (final file in a.save(save).listSync().whereType<File>()) {
      file.setLastModifiedSync(DateTime(2030));
    }
    expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);
  });

  group("conflicts", () {
    setUp(() async {
      a.writeSave(save, 'day 1');
      await a.engine.push(save);
      await b.engine.pull(await b.status(save));
      // Both PCs play without syncing in between.
      b.writeSave(save, 'day 2 on b');
      await b.engine.push(save);
      a.writeSave(save, 'day 2 on a');
    });

    test("both changed is a conflict", () async {
      expect((await a.status(save)).status, SaveSyncItemStatus.conflict);
    });

    test("keep local backs up the synced copy, then pushes", () async {
      await a.engine.resolveConflict(
        await a.status(save),
        SaveSyncConflictChoice.keepLocal,
      );
      expect(a.campaign(save), 'day 2 on a');
      expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);
      expect(
        a.backupFiles().map((f) => p.basename(f.path)),
        containsAll(['$save.zip', '$save.manifest.json']),
      );
      expect(a.backupFiles().first.path, contains('conflict-synced'));
      expect((await b.status(save)).status, SaveSyncItemStatus.willPull);
    });

    test("keep synced backs up the local save, then pulls", () async {
      await a.engine.resolveConflict(
        await a.status(save),
        SaveSyncConflictChoice.keepSynced,
      );
      expect(a.campaign(save), 'day 2 on b');
      expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);
      final backedUp = a.backupFiles().singleWhere(
        (f) => p.basename(f.path) == 'campaign.xml',
      );
      expect(backedUp.readAsStringSync(), 'day 2 on a');
      expect(backedUp.path, contains('conflict-local'));
    });

    test("keep both adds the synced copy as a new save", () async {
      await a.engine.resolveConflict(
        await a.status(save),
        SaveSyncConflictChoice.keepBoth,
      );
      final copyName = '${save}_synced_2026-11-04_15-30-00';
      expect(a.campaign(save), 'day 2 on a');
      expect(a.campaign(copyName), 'day 2 on b');
      expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);
      // The extra copy is not selected for sync.
      final overview = await a.engine.loadOverview({save});
      expect(overview.item(copyName)?.isSelected, isFalse);
    });

    test("skip changes nothing", () async {
      await a.engine.resolveConflict(
        await a.status(save),
        SaveSyncConflictChoice.skip,
      );
      expect(a.campaign(save), 'day 2 on a');
      expect((await a.status(save)).status, SaveSyncItemStatus.conflict);
      expect(a.backupFiles(), isEmpty);
    });
  });

  test("a zip that doesn't match its manifest is not pulled", () async {
    a.writeSave(save, 'day 1');
    await a.engine.push(save);
    b.writeSave(save, 'local on b');
    await b.engine.pull(await b.status(save)).catchError((_) {});

    // Simulate the cloud client delivering a new zip before its manifest.
    a.writeSave(save, 'day 2');
    final zip = File(p.join(syncFolder.path, 'saves', '$save.zip'));
    final manifest = File(
      p.join(syncFolder.path, 'saves', '$save.manifest.json'),
    );
    final oldManifest = manifest.readAsStringSync();
    await a.engine.push(save);
    manifest.writeAsStringSync(oldManifest);
    expect(zip.existsSync(), isTrue);

    final c = _Machine(temp, 'c', syncFolder, now);
    await expectLater(
      c.engine.pull(await c.status(save)),
      throwsA(
        isA<SaveSyncException>().having(
          (e) => e.message,
          'message',
          contains('does not match its manifest'),
        ),
      ),
    );
    expect(c.save(save).existsSync(), isFalse);
  });

  test("a manifest without its zip waits for the cloud client", () async {
    a.writeSave(save, 'day 1');
    await a.engine.push(save);
    File(p.join(syncFolder.path, 'saves', '$save.zip')).deleteSync();
    expect((await b.status(save)).status, SaveSyncItemStatus.waitingForCloud);
  });

  test(
    "Seafile conflict copies pause the save and can be moved to backups",
    () async {
      a.writeSave(save, 'day 1');
      await a.engine.push(save);
      final copy = File(
        p.join(
          syncFolder.path,
          'saves',
          '$save (SFConflict ionut 2026-11-04-15-20-00).zip',
        ),
      )..writeAsStringSync('other');

      final overview = await a.engine.loadOverview({save});
      expect(overview.item(save)?.status, SaveSyncItemStatus.cloudConflictCopy);

      await a.engine.takeConflictCopies(overview.conflictCopies);
      expect(copy.existsSync(), isFalse);
      expect(
        a.backupFiles().single.path,
        allOf(contains('cloud-conflict-copy'), contains('SFConflict')),
      );
      expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);
    },
  );

  test("a save deleted on one PC is never deleted elsewhere", () async {
    a.writeSave(save, 'day 1');
    await a.engine.push(save);
    a.save(save).deleteSync(recursive: true);

    expect((await a.status(save)).status, SaveSyncItemStatus.missingLocally);
    expect(
      File(p.join(syncFolder.path, 'saves', '$save.zip')).existsSync(),
      isTrue,
    );
  });

  test(
    "a save deleted on this PC can be restored from the sync folder",
    () async {
      a.writeSave(save, 'day 1');
      await a.engine.push(save);
      a.save(save).deleteSync(recursive: true);

      await a.engine.pull(await a.status(save));

      expect(a.campaign(save), 'day 1');
      expect((await a.status(save)).status, SaveSyncItemStatus.upToDate);
      // Nothing local was replaced, so nothing went to backups.
      expect(a.backupFiles(), isEmpty);
    },
  );

  test("names differing only by case are refused", () async {
    // Synced from a Linux PC as save_Foo_1; this PC has save_foo_1.
    b.writeSave('save_Foo_1', 'x');
    await b.engine.push('save_Foo_1');
    a.writeSave('save_foo_1', 'y');

    final overview = await a.engine.loadOverview({'save_foo_1', 'save_Foo_1'});
    for (final name in ['save_foo_1', 'save_Foo_1']) {
      expect(overview.item(name)?.status, SaveSyncItemStatus.nameProblem);
      expect(overview.item(name)?.problem, contains('letter case'));
    }
    expect(a.campaign('save_foo_1'), 'y');
  });

  test("records are kept per saves folder", () async {
    a.writeSave(save, 'day 1');
    await a.engine.push(save);
    final key = SaveSyncState.recordKey(a.savesFolder.path, save);
    expect(a.store.state.records.keys, [key]);
    expect(
      a.store.state.records[key]?.contentHash,
      await computeSaveContentHash(a.save(save)),
    );
  });

  group("locks", () {
    test(
      "other machines' locks are reported; own lock is recognized",
      () async {
        await a.engine.backend.prepare();
        await a.engine.writeLock();
        await b.engine.writeLock();

        final locks = await a.engine.backend.readLocks();
        expect(a.engine.hasOwnLock(locks), isTrue);
        expect(a.engine.otherMachinesLocks(locks).single.machineName, 'PC b');

        await b.engine.removeLock();
        final after = await a.engine.backend.readLocks();
        expect(a.engine.otherMachinesLocks(after), isEmpty);
      },
    );

    test("a day-old lock is stale", () async {
      final lock = SaveSyncLock(
        machineId: 'b',
        machineName: 'PC b',
        os: 'linux',
        startedAt: now.subtract(const Duration(hours: 30)),
      );
      expect(lock.isStale(now), isTrue);
    });
  });
}
