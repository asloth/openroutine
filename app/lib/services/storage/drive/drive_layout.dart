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

/// Written into the folder the first time we create it.
///
/// This file is the whole point of storing routines as plain JSON in a folder
/// the user can see: someone — or some agent — who opens this folder with no
/// idea what OpenRoutine is should be able to work out the format without
/// installing anything (docs/SPEC.md §1).
const driveFolderReadme = '''
# OpenRoutine

This folder holds your routines as plain JSON. OpenRoutine created it, but the
files are yours: you can read them, edit them, back them up, or point a script
or an AI agent at them. Nothing here is encrypted or obfuscated.

## What is in here

| File | What it is |
|---|---|
| `routines.json` | Every routine, step and trigger you have. |
| `completions/YYYY-MM.ndjson` | One line per completed run of a routine, split by month. |
| `meta.json` | Bookkeeping: schema version, which install wrote last, when. |

## Editing these files

You can edit `routines.json` directly. The app reads it on open and merges
changes in. Two rules matter:

1. **`updated_at` decides who wins.** If the same routine is edited here and in
   the app, whichever has the later `updated_at` is kept. If you edit by hand,
   bump `updated_at` to now (UTC, ISO 8601) or your change may be overwritten.
2. **Deletions are soft.** Set `deleted_at` instead of removing the object.
   Deleting the object outright lets another device put it back.

`completions/*.ndjson` is append-only — one JSON object per line. Readers
deduplicate by `id`, so appending the same line twice is harmless, but
rewriting or reordering existing lines is not supported.

## The schemas

Every file here validates against the JSON schemas published with the app:

https://github.com/asloth/openroutine/tree/main/schemas

`schema_version` in `meta.json` and `routines.json` tells you which version
these files were written against.

## If you break something

Nothing here is the app's only copy — your device keeps its own database and
will merge back on the next sync. If a file ends up invalid, the app skips it
and keeps using local data rather than throwing your routines away.
''';
