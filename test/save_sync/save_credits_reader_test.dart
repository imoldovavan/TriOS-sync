import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/save_sync/save_credits_reader.dart';

void main() {
  group('readPlayerCredits', () {
    test('player fleet written before the reference to it', () {
      const xml = '''<?xml version="1.0" ?>
<CampaignEngine z="1">
<Flt z="10" n="Player Fleet">
<members z="11"><rT z="12" cr="0.5"><cargo z="13"><c z="14"><value>5.0</value></c></cargo></rT></members>
<fD z="15" nSf="player">
<cargo z="20" mC="100.0">
<s z="21">
<CIStack z="22" s="10.0"><d cl="st">supplies</d><c ref="20"></c></CIStack>
</s>
<c z="23">
<value>1563872.0</value>
</c>
</cargo>
</fD>
</Flt>
<playerFleet cl="Flt" ref="10"></playerFleet>
</CampaignEngine>''';
      expect(readPlayerCredits(xml), 1563872.0);
    });

    test('player fleet written in place', () {
      const xml = '''<CampaignEngine z="1">
<playerFleet cl="Flt" z="10"><fD z="11"><cargo z="20"><c z="23"><value>42.5</value></c></cargo></fD></playerFleet>
</CampaignEngine>''';
      expect(readPlayerCredits(xml), 42.5);
    });

    test('cargo and credits written elsewhere', () {
      const xml = '''<CampaignEngine z="1">
<x><cargo z="20"><c ref="30"/></cargo><v z="30"><value>7.0</value></v></x>
<playerFleet z="10"><fD z="11"><cargo ref="20"/></fD></playerFleet>
</CampaignEngine>''';
      expect(readPlayerCredits(xml), 7.0);
    });

    test('no player fleet', () {
      expect(
        readPlayerCredits('<CampaignEngine z="1"></CampaignEngine>'),
        null,
      );
    });
  });

  test('readSaveCredits reads gzip-compressed campaign.xml', () async {
    final dir = await Directory.systemTemp.createTemp('save_credits_test');
    addTearDown(() => dir.delete(recursive: true));
    const xml =
        '<CampaignEngine z="1"><playerFleet z="10"><fD z="11"><cargo z="20">'
        '<c z="23"><value>99.0</value></c></cargo></fD></playerFleet>'
        '</CampaignEngine>';
    await File('${dir.path}/campaign.xml')
        .writeAsBytes(gzip.encode(xml.codeUnits));
    expect(await readSaveCredits(dir), 99.0);
  });
}
