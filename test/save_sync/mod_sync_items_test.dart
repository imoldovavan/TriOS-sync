import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/save_sync/mod_sync_items.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('mod_sync_items_test');
  });
  tearDown(() => temp.delete(recursive: true));

  Directory makeMod(String name, Map<String, String> files) {
    final folder = Directory(p.join(temp.path, name))
      ..createSync(recursive: true);
    for (final entry in files.entries) {
      File(p.join(folder.path, entry.key))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(entry.value);
    }
    return folder;
  }

  test('lists mod folders and skips hidden ones', () {
    makeMod('B mod', {'a.txt': '1'});
    makeMod('A mod', {'a.txt': '1'});
    makeMod('.trios-sync-incoming', {'x': '1'});
    File(p.join(temp.path, 'enabled_mods.json')).writeAsStringSync('{}');
    expect(listModFolderNames(temp), ['A mod', 'B mod']);
  });

  test('disabling mod_info.json does not change the hash', () async {
    final mod = makeMod('Mod', {
      'mod_info.json': '{"id":"m"}',
      'data/x.csv': 'a,b',
    });
    final before = await computeModContentHash(mod);
    File(p.join(mod.path, 'mod_info.json'))
        .renameSync(p.join(mod.path, 'mod_info.json.disabled-by-TriOS'));
    expect(await computeModContentHash(mod), before);
    expect(currentModInfoFileName(mod), 'mod_info.json.disabled-by-TriOS');
  });

  test('a nested mod_info.json keeps its name', () {
    final mod = makeMod('Mod', {
      'mod_info.json.disabled': '{}',
      'sub/mod_info.json.disabled': '{}',
    });
    expect(listModFiles(mod).keys, [
      'mod_info.json',
      'sub/mod_info.json.disabled',
    ]);
  });

  test('editing a file changes the hash', () async {
    final mod = makeMod('Mod', {'mod_info.json': '{}', 'a.txt': 'one'});
    final before = await computeModContentHash(mod);
    File(p.join(mod.path, 'a.txt')).writeAsStringSync('two');
    expect(await computeModContentHash(mod), isNot(before));
  });

  test(
    'fingerprint changes when a file is added, removed, or edited',
    () async {
      final mod = makeMod('Mod', {'a.txt': 'one'});
      final start = await computeModFingerprint(mod);
      expect(start.fileCount, 1);
      expect(start.totalBytes, 3);

      File(p.join(mod.path, 'b.txt')).writeAsStringSync('xx');
      final added = await computeModFingerprint(mod);
      expect(added, isNot(start));

      File(p.join(mod.path, 'b.txt')).deleteSync();
      final file = File(p.join(mod.path, 'a.txt'))..writeAsStringSync('three');
      file.setLastModifiedSync(DateTime(2030));
      final edited = await computeModFingerprint(mod);
      expect(edited, isNot(start));
      expect(edited.totalBytes, 5);
    },
  );

  test('fingerprint is stable when nothing changed', () async {
    final mod = makeMod('Mod', {'a.txt': 'one', 'mod_info.json': '{}'});
    expect(await computeModFingerprint(mod), await computeModFingerprint(mod));
  });

  test('enabled list hash ignores order and duplicates', () {
    const a = ShallowModVariant(modId: 'a', smolVariantId: 'a-1');
    const b = ShallowModVariant(modId: 'b', smolVariantId: 'b-2');
    expect(
      computeEnabledModListHash([a, b]),
      computeEnabledModListHash([b, a, b]),
    );
    expect(
      computeEnabledModListHash([a]),
      isNot(computeEnabledModListHash([a, b])),
    );
  });
}
