/// Why a save folder name can't be synced between Windows and Linux.
enum SaveNameProblem {
  empty("The save folder name is empty."),
  invalidCharacters(
    'The save folder name contains characters Windows does not allow (< > : " / \\ | ? *).',
  ),
  endsWithDotOrSpace(
    "The save folder name ends with a dot or space, which Windows does not allow.",
  ),
  reservedName("The save folder name is reserved by Windows."),
  caseClash("The name differs only by letter case from another save.");

  const SaveNameProblem(this.message);

  final String message;
}

final _invalidCharacters = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
final _reservedNames = RegExp(
  r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$',
  caseSensitive: false,
);

/// Checks one save folder name. Returns null if it can be synced.
SaveNameProblem? checkSaveFolderName(String name) {
  if (name.isEmpty) return SaveNameProblem.empty;
  if (_invalidCharacters.hasMatch(name)) {
    return SaveNameProblem.invalidCharacters;
  }
  if (name.endsWith('.') || name.endsWith(' ')) {
    return SaveNameProblem.endsWithDotOrSpace;
  }
  if (_reservedNames.hasMatch(name)) return SaveNameProblem.reservedName;
  return null;
}

/// Returns every name in [names] that matches a *different* name when letter
/// case is ignored. Such names would land in the same folder on Windows.
Set<String> findCaseClashes(Iterable<String> names) {
  final byLowercase = <String, Set<String>>{};
  for (final name in names) {
    byLowercase.putIfAbsent(name.toLowerCase(), () => {}).add(name);
  }
  return {
    for (final group in byLowercase.values)
      if (group.length > 1) ...group,
  };
}
