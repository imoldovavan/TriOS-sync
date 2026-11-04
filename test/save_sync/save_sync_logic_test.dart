import 'package:flutter_test/flutter_test.dart';
import 'package:trios/save_sync/cloud_conflict_files.dart';
import 'package:trios/save_sync/models/save_sync_lock.dart';
import 'package:trios/save_sync/save_sync_decision.dart';
import 'package:trios/save_sync/save_sync_names.dart';

void main() {
  group("decideSaveSync", () {
    SaveSyncDecision decide(String? local, String? remote, String? record) =>
        decideSaveSync(
          localHash: local,
          remoteHash: remote,
          recordHash: record,
        );

    test("nothing anywhere", () {
      expect(decide(null, null, null), SaveSyncDecision.notFound);
      expect(decide(null, null, "r"), SaveSyncDecision.notFound);
    });

    test("never synced", () {
      expect(decide("a", null, null), SaveSyncDecision.push);
      expect(decide(null, "a", null), SaveSyncDecision.pull);
      expect(decide("a", "a", null), SaveSyncDecision.upToDate);
      expect(decide("a", "b", null), SaveSyncDecision.conflict);
    });

    test("synced before", () {
      expect(decide("r", "r", "r"), SaveSyncDecision.upToDate);
      expect(decide("a", "r", "r"), SaveSyncDecision.push);
      expect(decide("r", "b", "r"), SaveSyncDecision.pull);
      expect(decide("a", "b", "r"), SaveSyncDecision.conflict);
      expect(decide("a", "a", "r"), SaveSyncDecision.upToDate);
    });

    test("one copy missing after an earlier sync", () {
      expect(decide(null, "r", "r"), SaveSyncDecision.missingLocally);
      expect(decide(null, "b", "r"), SaveSyncDecision.missingLocally);
      expect(decide("r", null, "r"), SaveSyncDecision.push);
      expect(decide("a", null, "r"), SaveSyncDecision.push);
    });
  });

  group("parseCloudConflictCopy", () {
    test("Seafile zip and manifest", () {
      final zip = parseCloudConflictCopy(
        "save_foo_123 (SFConflict ionut 2026-11-04-15-20-00).zip",
      );
      expect(zip?.originalFileName, "save_foo_123.zip");
      expect(zip?.clientName, "Seafile");

      final manifest = parseCloudConflictCopy(
        "save_foo_123.manifest (SFConflict ionut@example.com 2026-11-04-15-20-00).json",
      );
      expect(manifest?.originalFileName, "save_foo_123.manifest.json");
    });

    test("Seafile copy with spaces in the name", () {
      final copy = parseCloudConflictCopy(
        "save_my campaign_1 (SFConflict ionut 2026-11-04-15-20-00).zip",
      );
      expect(copy?.originalFileName, "save_my campaign_1.zip");
    });

    test("Dropbox", () {
      final copy = parseCloudConflictCopy(
        "save_foo_123 (DESKTOP-1's conflicted copy 2026-11-04).zip",
      );
      expect(copy?.originalFileName, "save_foo_123.zip");
      expect(copy?.clientName, "Dropbox");
      expect(
        parseCloudConflictCopy(
          "save_foo_123 (laptop's conflicted copy 2026-11-04 (1)).zip",
        )?.originalFileName,
        "save_foo_123.zip",
      );
    });

    test("Syncthing", () {
      final copy = parseCloudConflictCopy(
        "save_foo_123.sync-conflict-20261104-152000-ABCDEFG.zip",
      );
      expect(copy?.originalFileName, "save_foo_123.zip");
      expect(copy?.clientName, "Syncthing");
    });

    test("normal files are not conflict copies", () {
      expect(parseCloudConflictCopy("save_foo_123.zip"), isNull);
      expect(parseCloudConflictCopy("save_foo_123.manifest.json"), isNull);
      expect(parseCloudConflictCopy("save_foo (1).zip"), isNull);
      expect(parseCloudConflictCopy("abc.lock.json"), isNull);
    });
  });

  group("save folder names", () {
    test("valid names", () {
      expect(checkSaveFolderName("save_foo_123"), isNull);
      expect(checkSaveFolderName("save_my campaign_1"), isNull);
      expect(checkSaveFolderName("save_Ünïcödé_1"), isNull);
    });

    test("names Windows does not allow", () {
      expect(checkSaveFolderName(""), SaveNameProblem.empty);
      expect(
        checkSaveFolderName("save_a:b"),
        SaveNameProblem.invalidCharacters,
      );
      expect(checkSaveFolderName("save_a?"), SaveNameProblem.invalidCharacters);
      expect(
        checkSaveFolderName("save_a\u0001"),
        SaveNameProblem.invalidCharacters,
      );
      expect(
        checkSaveFolderName("save_a."),
        SaveNameProblem.endsWithDotOrSpace,
      );
      expect(
        checkSaveFolderName("save_a "),
        SaveNameProblem.endsWithDotOrSpace,
      );
      expect(checkSaveFolderName("CON"), SaveNameProblem.reservedName);
      expect(checkSaveFolderName("lpt1.txt"), SaveNameProblem.reservedName);
      expect(checkSaveFolderName("CONSOLE"), isNull);
    });

    test("case clashes", () {
      expect(findCaseClashes(["save_Foo_1", "save_foo_1", "save_bar_2"]), {
        "save_Foo_1",
        "save_foo_1",
      });
      // The same name twice (e.g. local and remote) is not a clash.
      expect(findCaseClashes(["save_foo_1", "save_foo_1"]), isEmpty);
    });
  });

  group("SaveSyncLock", () {
    final startedAt = DateTime.utc(2026, 11, 4, 12);
    final lock = SaveSyncLock(
      machineId: "machine-a",
      machineName: "DESKTOP",
      os: "windows",
      startedAt: startedAt,
    );

    test("stale after 24 hours", () {
      expect(lock.isStale(startedAt.add(const Duration(hours: 23))), isFalse);
      expect(lock.isStale(startedAt.add(const Duration(hours: 25))), isTrue);
    });

    test("ownership", () {
      expect(lock.isOwnedBy("machine-a"), isTrue);
      expect(lock.isOwnedBy("machine-b"), isFalse);
    });

    test("round-trips through JSON in UTC", () {
      final decoded = SaveSyncLockMapper.fromJson(lock.toJson());
      expect(decoded, lock);
      expect(decoded.startedAt.isUtc, isTrue);
    });
  });
}
