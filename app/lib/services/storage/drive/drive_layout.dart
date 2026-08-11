/// Names of everything OpenRoutine writes into the user's Drive, per the
/// layout in docs/SPEC.md §5. Kept in one place because these strings are a
/// public contract: agents and humans open this folder by name.
class DriveLayout {
  const DriveLayout._();

  static const folderName = 'OpenRoutine';
  static const routinesFile = 'routines.json';
  static const metaFile = 'meta.json';
  static const readmeFile = 'README.md';
  static const completionsFolder = 'completions';

  /// `completions/YYYY-MM.ndjson`. Deterministic on purpose: two clients that
  /// finish a routine in the same month must target the same file for the
  /// append-and-dedupe merge to work (§5).
  static String completionsFileFor(DateTime instant) {
    final utc = instant.toUtc();
    return '${monthKeyFor(utc)}.ndjson';
  }

  /// `YYYY-MM`, the key the sync queue tracks dirty shards by.
  static String monthKeyFor(DateTime instant) {
    final utc = instant.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}';
  }
}
