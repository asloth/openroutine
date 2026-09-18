## 1. Show days in both modes

- [x] 1.1 Add a widget test asserting picking Flexible still shows the day chips, and verify it
      fails against the current `if (_mode == ScheduleMode.scheduled)` block
- [x] 1.2 Move the day-chips `Wrap` and `_daysError` text out of that block so they render for both
      modes, and verify 1.1 passes
- [x] 1.3 Add a widget test asserting picking Flexible hides the start-time row, and verify it
      passes (the `ListTile` stays inside the Scheduled-only block)

## 2. Require and persist days in both modes

- [x] 2.1 Add a widget test asserting saving a Flexible routine with no days shows the
      days-required error and does not save, and verify it fails while validation is still
      Scheduled-only
- [x] 2.2 Make the days check in `_save()` unconditional, keep the start-time check Scheduled-only,
      and verify 2.1 passes
- [x] 2.3 Add a widget test asserting saving a Flexible routine with days selected persists those
      days (and a null start time), and verify it fails while `Schedule.days` is still forced to
      `const []` for Flexible
- [x] 2.4 Change the `Schedule(...)` built in `_save()` to `days: _days.toList()` unconditionally,
      leaving `startTime` Scheduled-only, and verify 2.3 passes
- [x] 2.5 Add a widget test asserting editing a Scheduled routine with days, switching it to
      Flexible, and saving keeps those days, and verify it passes

## 3. Update tests that assumed the old behavior

- [x] 3.1 Update "submitting with a name persists a new routine via the storage adapter" to pick a
      day before saving, since Flexible (the default mode) now requires one
- [x] 3.2 Replace "a Flexible save still works with no days and no time" — that asserted the old,
      now-wrong rule — with the days-required and days-persisted tests from task 2

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [x] 4.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format lib/screens/routine_form/routine_form_screen.dart test/screens/routine_form/routine_form_screen_test.dart`
