import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/utils/network_util.dart';

Release _release(String tag) => Release.fromJson({
  'url': '',
  'assets_url': '',
  'upload_url': '',
  'html_url': '',
  'id': 1,
  'tag_name': tag,
  'name': tag,
  'draft': false,
  'prerelease': true,
  'created_at': '2026-11-06T00:00:00Z',
  'published_at': '2026-11-06T00:00:00Z',
  'assets': [],
  'body': '',
});

void main() {
  group('Sync build update check', () {
    test('a newer preview is an update', () {
      expect(
        SelfUpdater.hasNewVersion(
          _release('1.7.1-savesync-preview04'),
          currentVersion: '1.7.1-savesync-preview03',
        ),
        isTrue,
      );
    });

    test('the same or an older preview is not an update', () {
      for (final tag in [
        '1.7.1-savesync-preview03',
        '1.7.1-savesync-preview02',
      ]) {
        expect(
          SelfUpdater.hasNewVersion(
            _release(tag),
            currentVersion: '1.7.1-savesync-preview03',
          ),
          isFalse,
          reason: tag,
        );
      }
    });

    test('the manual check agrees', () {
      Version v(String s) => Version.parse(s, sanitizeInput: true);
      expect(
        v('1.7.1-savesync-preview04') > v('1.7.1-savesync-preview03'),
        isTrue,
      );
      expect(
        v('1.7.1-savesync-preview03') <= v('1.7.1-savesync-preview03'),
        isTrue,
      );
    });
  });
}
