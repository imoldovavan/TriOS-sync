import 'package:dart_mappable/dart_mappable.dart';

part 'save_sync_lock.mapper.dart';

/// Written to `locks/<machineId>.lock.json` in the sync folder while the game
/// runs on that machine. Each machine only ever writes its own lock file, so
/// cloud clients never see two machines editing the same file.
@MappableClass()
class SaveSyncLock with SaveSyncLockMappable {
  /// A lock older than this is probably left over from a crash.
  static const staleAfter = Duration(hours: 24);

  const SaveSyncLock({
    required this.machineId,
    required this.machineName,
    required this.os,
    this.triosVersion,
    required this.startedAt,
  });

  final String machineId;
  final String machineName;
  final String os;
  final String? triosVersion;

  /// UTC.
  final DateTime startedAt;

  bool isStale(DateTime now) => now.difference(startedAt) > staleAfter;

  bool isOwnedBy(String otherMachineId) => machineId == otherMachineId;
}
