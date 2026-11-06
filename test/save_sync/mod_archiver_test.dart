import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_sync/mod_sync_items.dart';
import 'package:trios/save_sync/save_archiver.dart';

void main() {
  late Directory temp;
  late Directory mods;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mod_archiver_test');
    mods = Directory(p.join(temp.path, 'mods'))..createSync();
  });
  tearDown(() => temp.delete(recursive: true));

  Directory makeMod(Directory parent, String name, Map<String, String> files) {
    final folder = Directory(p.join(parent.path, name))
      ..createSync(recursive: true);
    for (final entry in files.entries) {
      File(p.join(folder.path, entry.key))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(entry.value);
    }
    return folder;
  }

  Future<File> zipOf(Directory folder) async {
    final zip = File(p.join(temp.path, '${p.basename(folder.path)}.zip'));
    await archiveModFolder(folder, zip);
    return zip;
  }

  test(
    'round trip keeps contents; disabled mod_info is zipped enabled',
    () async {
      final source = makeMod(temp, 'Mod', {
        'mod_info.json.disabled-by-TriOS': '{"id":"m"}',
        'data/a.csv': 'x',
      });
      final zip = await zipOf(source);

      await installModFromArchive(
        zipFile: zip,
        modsFolder: mods,
        folderName: 'Mod',
        moveReplacedMod: (_) async => fail('nothing to replace'),
      );

      final installed = Directory(p.join(mods.path, 'Mod'));
      expect(currentModInfoFileName(installed), 'mod_info.json');
      expect(
        await computeModContentHash(installed),
        await computeModContentHash(source),
      );
      expect(
        Directory(p.join(mods.path, modSyncTempFolderName, 'in', 'Mod'))
            .existsSync(),
        isFalse,
      );
    },
  );

  test("replacing keeps this PC's disabled mod_info name", () async {
    makeMod(mods, 'Mod', {
      'mod_info.json.disabled-by-TriOS': '{"id":"m"}',
      'old.txt': 'old',
    });
    final zip = await zipOf(
      makeMod(temp, 'Mod', {'mod_info.json': '{"id":"m"}', 'new.txt': 'new'}),
    );

    Directory? replaced;
    await installModFromArchive(
      zipFile: zip,
      modsFolder: mods,
      folderName: 'Mod',
      modInfoFileName: 'mod_info.json.disabled-by-TriOS',
      moveReplacedMod: (folder) async {
        replaced = Directory(p.join(temp.path, 'backup'));
        folder.renameSync(replaced!.path);
      },
    );

    final installed = Directory(p.join(mods.path, 'Mod'));
    expect(
      currentModInfoFileName(installed),
      'mod_info.json.disabled-by-TriOS',
    );
    expect(File(p.join(installed.path, 'new.txt')).existsSync(), isTrue);
    expect(File(p.join(installed.path, 'old.txt')).existsSync(), isFalse);
    expect(File(p.join(replaced!.path, 'old.txt')).existsSync(), isTrue);
  });

  test('a damaged zip leaves the mod unchanged', () async {
    makeMod(mods, 'Mod', {'mod_info.json': '{}', 'keep.txt': 'keep'});
    final zip = File(p.join(temp.path, 'bad.zip'))
      ..writeAsStringSync('not a zip');

    await expectLater(
      installModFromArchive(
        zipFile: zip,
        modsFolder: mods,
        folderName: 'Mod',
        moveReplacedMod: (_) async => fail('must not replace'),
      ),
      throwsA(anything),
    );
    expect(File(p.join(mods.path, 'Mod', 'keep.txt')).existsSync(), isTrue);
    expect(
      Directory(p.join(mods.path, modSyncTempFolderName, 'in', 'Mod'))
          .existsSync(),
      isFalse,
    );
  });
}
