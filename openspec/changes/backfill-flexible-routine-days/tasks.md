## 1. Migration test

- [x] 1.1 Read `app/test/services/storage/migration_test.dart` and follow its pattern: a hand-written
      fixture at the prior schema version, upgraded by opening the real `AppDatabase`
- [x] 1.2 Add a v7 → v8 fixture and test group covering: a flexible routine with an empty day list
      ends up with all seven days; a flexible routine that already has days is left alone; a
      scheduled routine with an empty day list is left alone; other columns (name, schedule mode,
      start time, timestamps) and other tables (steps, completion logs) are undisturbed
- [x] 1.3 Run the new tests and confirm they fail against the unmodified `schemaVersion => 7`

## 2. Migration

- [x] 2.1 Bump `AppDatabase.schemaVersion` from 7 to 8
- [x] 2.2 Add an `if (from < 8)` branch to `onUpgrade` that backfills `schedule_days` to all seven
      days for every routine where `schedule_mode = 'flexible'` and `schedule_days = ''`, using
      `DayOfWeek.values` and `ScheduleMode.flexible.name` rather than string literals
- [x] 2.3 Update the doc comment above `schemaVersion` to describe v8 in the same voice as the
      existing v2–v7 history
- [x] 2.4 Re-run the tests from 1.2 and confirm they pass

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm dart run build_runner build --delete-conflicting-outputs`
      from `app/` after the `AppDatabase` edit
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.3 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
      above the pre-change baseline
- [x] 3.4 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format app/lib/services/storage/drift/app_database.dart app/test/services/storage/migration_test.dart`
