import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/folder_save_sync_backend.dart';
import 'package:trios/save_sync/mod_sync_engine.dart';
import 'package:trios/save_sync/mod_sync_items.dart';
import 'package:trios/save_sync/models/save_sync_state.dart';
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

/// One simulated PC with its own mods folder, sharing the sync folder.
class _Pc {
  _Pc(Directory root, String id, Directory syncFolder)
    : modsFolder = Directory(p.join(root.path, id, 'mods'))
        ..createSync(recursive: true),
      backupsFolder = Directory(p.join(root.path, id, 'backups')),
      store = _MemoryStateStore() {
    engine = ModSyncEngine(
      backend: FolderSaveSyncBackend(syncFolder),
      modsFolder: modsFolder,
      backups: SaveSyncBackups(backupsFolder),
      machine: SaveSyncMachine(id: id, name: 'PC $id', os: 'test'),
      stateStore: store,
      tempFolder: Directory(p.join(root.path, id, 'temp')),
    );
  }

  final Directory modsFolder;
  final Directory backupsFolder;
  final _MemoryStateStore store;
  late final ModSyncEngine engine;

  Directory mod(String name) => Directory(p.join(modsFolder.path, name));

  void writeMod(
    String name, {
    String id = 'mod',
    String version = '1.0',
    String data = 'x',
    String modInfoName = 'mod_info.json',
  }) {
    final folder = mod(name)..createSync(recursive: true);
    File(p.join(folder.path, modInfoName)).writeAsStringSync(
      '{"id": "$id", "name": "Mod $id", "version": "$version"}',
    );
    File(p.join(folder.path, 'data.txt')).writeAsStringSync(data);
  }

  Future<ModSyncOverview> overview([
    List<ShallowModVariant> enabled = const [],
  ]) => engine.loadOverview(enabled);

  Future<SaveSyncItemStatus> status(String name) async =>
      (await overview()).item(name)!.status;

  /// Pushes and pulls everything, like a sync run with no conflicts.
  Future<void> sync() async {
    for (final item in (await overview()).items) {
      switch (item.status) {
        case SaveSyncItemStatus.willPush:
          await engine.push(item.folderName);
        case SaveSyncItemStatus.willPull:
          await engine.pull(item);
        case SaveSyncItemStatus.upToDate:
          await engine.recordUpToDate(item);
        default:
          break;
      }
    }
  }
}

void main() {
  late Directory temp;
  late Directory syncFolder;
  late _Pc a;
  late _Pc b;

  setUpAll(() => configureLogging(LoggingSettings(consoleOnly: true)));

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('trios_mod_sync_engine');
    syncFolder = Directory(p.join(temp.path, 'sync'))..createSync();
    a = _Pc(temp, 'a', syncFolder);
    b = _Pc(temp, 'b', syncFolder);
  });
  tearDown(() => temp.delete(recursive: true));

  test('a new PC gets every mod, including two versions of one', () async {
    a.writeMod('Nex', id: 'nex', version: '1');
    a.writeMod(
      'Nex-2',
      id: 'nex',
      version: '2',
      modInfoName: 'mod_info.json.disabled',
    );
    a.writeMod('Lazy', id: 'lazy');
    await a.sync();

    expect(await b.status('Nex'), SaveSyncItemStatus.willPull);
    await b.sync();

    expect(listModFolderNames(b.modsFolder), ['Lazy', 'Nex', 'Nex-2']);
    // Only one version of nex is active on B: the second one to arrive comes in
    // disabled.
    final active = [
      currentModInfoFileName(b.mod('Nex')),
      currentModInfoFileName(b.mod('Nex-2')),
    ].where((name) => name == 'mod_info.json');
    expect(active, hasLength(1));
    for (final pc in [a, b]) {
      for (final item in (await pc.overview()).items) {
        expect(
          item.status,
          SaveSyncItemStatus.upToDate,
          reason: item.folderName,
        );
      }
    }
  });

  test('the manifest has the mod id, name, and version', () async {
    a.writeMod('Nex', id: 'nex', version: '0.12.1e');
    await a.sync();
    final manifest = (await b.overview()).item('Nex')!.remoteManifest!;
    expect(manifest.modId, 'nex');
    expect(manifest.modName, 'Mod nex');
    expect(manifest.modVersion, '0.12.1e');
    expect(manifest.machineName, 'PC a');
  });

  test(
    'a changed mod is pushed and then pulled; the old copy is backed up',
    () async {
      a.writeMod('Nex', data: 'v1');
      await a.sync();
      await b.sync();

      a.writeMod('Nex', data: 'v2');
      expect(await a.status('Nex'), SaveSyncItemStatus.willPush);
      await a.sync();
      expect(await b.status('Nex'), SaveSyncItemStatus.willPull);
      await b.sync();

      expect(
        File(p.join(b.mod('Nex').path, 'data.txt')).readAsStringSync(),
        'v2',
      );
      final backedUp = b.backupsFolder
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => p.basename(f.path) == 'data.txt');
      expect(backedUp.single.readAsStringSync(), 'v1');
    },
  );

  test("switching the active version alone isn't a change", () async {
    a.writeMod('Nex');
    await a.sync();
    File(
      p.join(a.mod('Nex').path, 'mod_info.json'),
    ).renameSync(p.join(a.mod('Nex').path, 'mod_info.json.disabled-by-TriOS'));
    expect(await a.status('Nex'), SaveSyncItemStatus.upToDate);
  });

  test("a pull keeps this PC's disabled mod_info name", () async {
    a.writeMod('Nex', data: 'v1');
    await a.sync();
    await b.sync();
    File(
      p.join(b.mod('Nex').path, 'mod_info.json'),
    ).renameSync(p.join(b.mod('Nex').path, 'mod_info.json.disabled-by-TriOS'));

    a.writeMod('Nex', data: 'v2');
    await a.sync();
    await b.sync();

    expect(
      currentModInfoFileName(b.mod('Nex')),
      'mod_info.json.disabled-by-TriOS',
    );
    expect(
      File(p.join(b.mod('Nex').path, 'data.txt')).readAsStringSync(),
      'v2',
    );
  });

  test("deleting a mod on A doesn't touch B or the sync folder", () async {
    a.writeMod('Nex');
    await a.sync();
    await b.sync();

    a.mod('Nex').deleteSync(recursive: true);
    expect(await a.status('Nex'), SaveSyncItemStatus.missingLocally);
    await a.sync();
    await b.sync();

    expect(b.mod('Nex').existsSync(), isTrue);
    expect(await b.status('Nex'), SaveSyncItemStatus.upToDate);
    expect(await a.status('Nex'), SaveSyncItemStatus.missingLocally);
    expect(a.mod('Nex').existsSync(), isFalse);
  });

  test('restore puts a deleted mod back', () async {
    a.writeMod('Nex');
    await a.sync();
    a.mod('Nex').deleteSync(recursive: true);

    await a.engine.pull((await a.overview()).item('Nex')!);
    expect(await a.status('Nex'), SaveSyncItemStatus.upToDate);
  });

  test('remove from sync folder moves the files to backups', () async {
    a.writeMod('Nex');
    await a.sync();
    await b.sync();
    a.mod('Nex').deleteSync(recursive: true);

    await a.engine.removeFromSyncFolder((await a.overview()).item('Nex')!);

    expect((await a.overview()).item('Nex'), isNull);
    expect(
      a.backupsFolder.listSync(recursive: true).map((e) => p.basename(e.path)),
      contains('Nex.zip'),
    );
    // B still has it, so B writes it back.
    expect(await b.status('Nex'), SaveSyncItemStatus.willPush);
  });

  test(
    'both PCs changing a mod is a conflict; keep synced backs up local',
    () async {
      a.writeMod('Nex', data: 'v1');
      await a.sync();
      await b.sync();
      a.writeMod('Nex', data: 'a');
      await a.sync();
      b.writeMod('Nex', data: 'b');

      final item = (await b.overview()).item('Nex')!;
      expect(item.status, SaveSyncItemStatus.conflict);
      await b.engine.resolveConflict(item, ModSyncConflictChoice.keepSynced);
      expect(
        File(p.join(b.mod('Nex').path, 'data.txt')).readAsStringSync(),
        'a',
      );
      expect(
        b.backupsFolder
            .listSync(recursive: true)
            .whereType<File>()
            .any(
              (f) =>
                  p.basename(f.path) == 'data.txt' &&
                  f.readAsStringSync() == 'b',
            ),
        isTrue,
      );
    },
  );

  test('unchanged mods are not read again', () async {
    a.writeMod('Nex');
    await a.overview();
    final stored = a.store.state.modHashes.values.single;
    // Same fingerprint, different stored hash: the stored one must be used.
    a.store.state = a.store.state.copyWith(
      modHashes: {
        a.store.state.modHashes.keys.single: stored.copyWith(
          contentHash: 'stored',
        ),
      },
    );
    expect((await a.overview()).item('Nex')!.localHash, 'stored');

    a.writeMod('Nex', data: 'changed!');
    expect((await a.overview()).item('Nex')!.localHash, isNot('stored'));
  });

  group('enabled-mods list', () {
    const nex1 = ShallowModVariant(modId: 'nex', smolVariantId: 'nex-1');
    const nex2 = ShallowModVariant(modId: 'nex', smolVariantId: 'nex-2');
    const lazy = ShallowModVariant(modId: 'lazy', smolVariantId: 'lazy-1');

    test('push from A, pull on B', () async {
      final first = (await a.overview([nex1, lazy])).enabledList;
      expect(first.status, SaveSyncItemStatus.willPush);
      await a.engine.pushEnabledList(first.localMods);

      // B has never synced the list and has its own: ask, don't overwrite.
      expect(
        (await b.overview([nex1])).enabledList.status,
        SaveSyncItemStatus.conflict,
      );
      // The same list in a different order is already up to date.
      final same = (await b.overview([lazy, nex1])).enabledList;
      expect(same.status, SaveSyncItemStatus.upToDate);
      await b.engine.recordEnabledListSynced(same);

      await a.engine.pushEnabledList([nex2]);
      final onB = (await b.overview([lazy, nex1])).enabledList;
      expect(onB.status, SaveSyncItemStatus.willPull);
      expect(onB.remote!.mods.map((m) => m.smolVariantId), ['nex-2']);
      await b.engine.recordEnabledListSynced(onB);
      expect(
        (await b.overview([nex2])).enabledList.status,
        SaveSyncItemStatus.upToDate,
      );
    });

    test('both PCs changing the list is a conflict', () async {
      await a.engine.pushEnabledList([nex1]);
      await b.engine.recordEnabledListSynced(
        (await b.overview([nex1])).enabledList,
      );

      await a.engine.pushEnabledList([nex2]);
      final onB = (await b.overview([nex1, lazy])).enabledList;
      expect(onB.status, SaveSyncItemStatus.conflict);

      await b.engine.keepLocalEnabledList(onB);
      expect(
        (await a.overview([nex2])).enabledList.status,
        SaveSyncItemStatus.willPull,
      );
      expect(
        a.store.state.enabledModListRecords.isNotEmpty &&
            b.backupsFolder.existsSync(),
        isTrue,
      );
    });
  });
}
