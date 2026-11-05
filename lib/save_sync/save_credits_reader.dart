import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/logging.dart';

/// Identifies one version of a save, so the credits are read again after the
/// game writes the save.
class SaveCreditsKey {
  const SaveCreditsKey(this.saveFolderPath, this.saveDate);

  final String saveFolderPath;
  final DateTime? saveDate;

  @override
  bool operator ==(Object other) =>
      other is SaveCreditsKey &&
      other.saveFolderPath == saveFolderPath &&
      other.saveDate == saveDate;

  @override
  int get hashCode => Object.hash(saveFolderPath, saveDate);
}

/// The player's credits in a save on this PC. Null if they can't be read.
final saveCreditsProvider = FutureProvider.family<double?, SaveCreditsKey>(
  (ref, key) => readSaveCredits(Directory(key.saveFolderPath)),
);

/// Reads the player's credits from a save's `campaign.xml`, on a background
/// isolate. The file is several MB or more. Returns null if it can't be read.
Future<double?> readSaveCredits(Directory saveFolder) {
  final path = p.join(saveFolder.path, 'campaign.xml');
  return Isolate.run(() {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final xml = _decodeCampaignFile(file.readAsBytesSync());
      return xml == null ? null : readPlayerCredits(xml);
    } catch (e) {
      return null;
    }
  }).catchError((Object e) {
    Fimber.w('Could not read credits from $path: $e');
    return null;
  });
}

/// Plain XML, or gzip/zlib for saves written with compression on.
String? _decodeCampaignFile(List<int> bytes) {
  final firstChar = bytes.cast<int?>().firstWhere(
    (b) => b != 0x20 && b != 0x0A && b != 0x0D && b != 0x09 && b != 0xEF,
    orElse: () => null,
  );
  if (firstChar == 0x3C) return utf8.decode(bytes, allowMalformed: true);
  for (final codec in [gzip, zlib]) {
    try {
      return utf8.decode(codec.decode(bytes), allowMalformed: true);
    } catch (_) {}
  }
  return null;
}

/// Finds the credits in `campaign.xml`: `<playerFleet>` points to the player's
/// fleet, whose fleet data `<fD>` has a `<cargo>` holding
/// `<c><value>credits</value></c>`. Objects can be
/// written in place (`z="id"`) or point to one written elsewhere (`ref="id"`).
double? readPlayerCredits(String xml) {
  final fleet = RegExp(r'<playerFleet\b[^>]*?\b(z|ref)="(\d+)"')
      .firstMatch(xml);
  if (fleet == null) return null;
  final fleetStart = fleet.group(1) == 'z'
      ? fleet.start
      : _definitionStart(xml, fleet.group(2)!);
  if (fleetStart == null) return null;
  final fleetDataStart = _childStart(xml, fleetStart, 'fD');
  if (fleetDataStart == null) return null;
  final cargoStart = _childStart(xml, fleetDataStart, 'cargo');
  if (cargoStart == null) return null;
  final creditsStart = _childStart(xml, cargoStart, 'c');
  if (creditsStart == null) return null;
  final valueStart = _childStart(xml, creditsStart, 'value');
  if (valueStart == null) return null;
  final textStart = xml.indexOf('>', valueStart) + 1;
  final textEnd = xml.indexOf('<', textStart);
  if (textStart <= 0 || textEnd < 0) return null;
  return double.tryParse(xml.substring(textStart, textEnd).trim());
}

final _tagPattern = RegExp(r'<(/?)([A-Za-z_][\w.\-]*)((?:[^>"]|"[^"]*")*)>');
final _refPattern = RegExp(r'\bref="(\d+)"');

/// Start of the tag that defines object [id].
int? _definitionStart(String xml, String id) {
  final at = xml.indexOf(' z="$id"');
  if (at < 0) return null;
  final start = xml.lastIndexOf('<', at);
  return start < 0 ? null : start;
}

/// Start of the first direct child named [name] of the element whose tag
/// starts at [parentStart], following `ref` to the object's definition.
int? _childStart(String xml, int parentStart, String name) {
  final parent = _tagPattern.matchAsPrefix(xml, parentStart);
  if (parent == null || parent.group(3)!.endsWith('/')) return null;
  var depth = 0;
  for (final tag in _tagPattern.allMatches(xml, parent.end)) {
    final isClose = tag.group(1) == '/';
    final isSelfClosing = tag.group(3)!.endsWith('/');
    if (isClose) {
      if (depth == 0) return null;
      depth--;
      continue;
    }
    if (depth == 0 && tag.group(2) == name) {
      final ref = _refPattern.firstMatch(tag.group(3)!);
      return ref == null ? tag.start : _definitionStart(xml, ref.group(1)!);
    }
    if (!isSelfClosing) depth++;
  }
  return null;
}
