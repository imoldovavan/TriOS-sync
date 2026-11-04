/// A copy a cloud client made when two machines changed the same file,
/// e.g. Seafile's `save_foo.zip` -> `save_foo (SFConflict ionut 2026-11-04-15-20-00).zip`.
class CloudConflictCopy {
  const CloudConflictCopy({
    required this.fileName,
    required this.originalFileName,
    required this.clientName,
  });

  /// The conflict copy's file name.
  final String fileName;

  /// The name of the file it is a copy of.
  final String originalFileName;

  /// Which cloud client made it, for display.
  final String clientName;
}

typedef _ConflictPattern = ({String clientName, RegExp regex});

// Each pattern captures `base` and `ext` so the original name is base + ext.
final List<_ConflictPattern> _patterns = [
  (
    clientName: "Seafile",
    regex: RegExp(
      r'^(?<base>.*) \(SFConflict .+? \d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}\)(?<ext>\.[^.]*)?$',
    ),
  ),
  (
    clientName: "Dropbox",
    regex: RegExp(
      r"^(?<base>.*) \(.+?'s conflicted copy \d{4}-\d{2}-\d{2}(?: \(\d+\))?\)(?<ext>\.[^.]*)?$",
    ),
  ),
  (
    clientName: "Syncthing",
    regex: RegExp(
      r'^(?<base>.*)\.sync-conflict-\d{8}-\d{6}-[A-Z0-9]{7}(?<ext>\.[^.]*)?$',
    ),
  ),
];

/// Returns the conflict-copy details if [fileName] is a cloud client's
/// conflict copy, otherwise null.
CloudConflictCopy? parseCloudConflictCopy(String fileName) {
  for (final pattern in _patterns) {
    final match = pattern.regex.firstMatch(fileName);
    if (match == null) continue;
    return CloudConflictCopy(
      fileName: fileName,
      originalFileName:
          match.namedGroup('base')! + (match.namedGroup('ext') ?? ''),
      clientName: pattern.clientName,
    );
  }
  return null;
}
