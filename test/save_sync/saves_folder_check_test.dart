import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_sync/saves_folder_check.dart';

void main() {
  group('reading the saves path from vmparams', () {
    test('Windows vmparams (one line, relative path)', () {
      const content =
          'java.exe -XX:CompilerThreadPriority=1 -Xms4096m -Xmx4096m '
          '-Djava.library.path=native\\windows '
          '-Dcom.fs.starfarer.settings.paths.saves=../saves '
          '-Dcom.fs.starfarer.settings.paths.screenshots=../screenshots '
          '-classpath janino.jar com.fs.starfarer.StarfarerLauncher\r\n';
      expect(readSavesPathFromVmparams(content), '../saves');
    });

    test('Linux launch script (one argument per line)', () {
      const content =
          './jre_linux/bin/java \\\n'
          '-Xms4096m \\\n'
          '-Dcom.fs.starfarer.settings.paths.saves=./saves \\\n'
          '-Dcom.fs.starfarer.settings.paths.mods=./mods \\\n';
      expect(readSavesPathFromVmparams(content), './saves');
    });

    test('path at the very end of the file', () {
      expect(
        readSavesPathFromVmparams(
          '-Dcom.fs.starfarer.settings.paths.saves=D:/Saves',
        ),
        'D:/Saves',
      );
    });

    test('quoted value with spaces', () {
      expect(
        readSavesPathFromVmparams(
          'java.exe -Dcom.fs.starfarer.settings.paths.saves="C:\\My Saves" -Xmx4g',
        ),
        'C:\\My Saves',
      );
    });

    test('quoted argument with spaces', () {
      expect(
        readSavesPathFromVmparams(
          "java '-Dcom.fs.starfarer.settings.paths.saves=/home/me/My Saves' -Xmx4g",
        ),
        '/home/me/My Saves',
      );
    });

    test('no saves path', () {
      expect(readSavesPathFromVmparams('java.exe -Xms4g -Xmx4g'), isNull);
      expect(
        readSavesPathFromVmparams(
          '-Dcom.fs.starfarer.settings.paths.screenshots=../screenshots',
        ),
        isNull,
      );
    });
  });

  group('resolving the saves path', () {
    final game = p.join(Directory.systemTemp.path, 'Starsector');
    final core = Directory(p.join(game, 'starsector-core'));

    test('relative paths are relative to the game core folder', () {
      expect(
        isSameFolder(
          resolveVmparamsPath('../saves', core),
          Directory(p.join(game, 'saves')),
        ),
        isTrue,
      );
    });

    test('absolute paths are used as they are', () {
      final elsewhere = p.join(Directory.systemTemp.path, 'Elsewhere', 'saves');
      expect(
        isSameFolder(resolveVmparamsPath(elsewhere, core), Directory(elsewhere)),
        isTrue,
      );
    });

    test('a different folder is not the same', () {
      expect(
        isSameFolder(
          resolveVmparamsPath('../my_saves', core),
          Directory(p.join(game, 'saves')),
        ),
        isFalse,
      );
    });

    test('trailing separators and ./ do not matter', () {
      expect(
        isSameFolder(
          Directory('${p.join(game, 'saves')}${p.separator}'),
          Directory(p.join(game, '.', 'saves')),
        ),
        isTrue,
      );
    });
  });
}
