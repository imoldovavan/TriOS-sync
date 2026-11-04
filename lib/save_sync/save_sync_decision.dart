/// What to do with one save, comparing this PC's copy, the sync folder's
/// copy, and the sync record from the last successful sync.
enum SaveSyncDecision {
  /// Both copies match. The record may still need updating to match them.
  upToDate,

  /// This PC's copy is newer. Write it to the sync folder.
  push,

  /// The sync folder's copy is newer. Replace this PC's copy with it.
  pull,

  /// Both copies changed since the last sync. Ask the user.
  conflict,

  /// The save was synced before but is gone from this PC. Nothing is pushed
  /// or deleted; deletions are never passed between machines.
  missingLocally,

  /// Neither copy exists.
  notFound,
}

/// Decides what to do with one save. Hashes are content hashes
/// (see `computeSaveContentHash`); null means that copy doesn't exist.
///
/// [recordHash] is the content hash both copies had at the last sync, or null
/// if this save was never synced from this PC.
SaveSyncDecision decideSaveSync({
  required String? localHash,
  required String? remoteHash,
  required String? recordHash,
}) {
  if (localHash == null && remoteHash == null) {
    return SaveSyncDecision.notFound;
  }

  if (recordHash == null) {
    if (remoteHash == null) return SaveSyncDecision.push;
    if (localHash == null) return SaveSyncDecision.pull;
    return localHash == remoteHash
        ? SaveSyncDecision.upToDate
        : SaveSyncDecision.conflict;
  }

  if (localHash == null) return SaveSyncDecision.missingLocally;
  if (remoteHash == null) return SaveSyncDecision.push;

  final localChanged = localHash != recordHash;
  final remoteChanged = remoteHash != recordHash;

  if (!localChanged && !remoteChanged) return SaveSyncDecision.upToDate;
  if (localChanged && !remoteChanged) return SaveSyncDecision.push;
  if (!localChanged && remoteChanged) return SaveSyncDecision.pull;
  // Both changed, but possibly to the same content (e.g. the same zip was
  // pulled by hand).
  return localHash == remoteHash
      ? SaveSyncDecision.upToDate
      : SaveSyncDecision.conflict;
}
