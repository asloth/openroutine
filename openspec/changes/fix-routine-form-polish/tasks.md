## 1. Time picker seeds from the stored start time

- [x] 1.1 Add a widget test asserting that editing a routine with a stored 07:30 start time opens
      `showTimePicker` with `initialTime` at 7:30, and verify it fails against `TimeOfDay.now()`
- [x] 1.2 Add `_parseStartTime` and pass `_parseStartTime(_startTime) ?? TimeOfDay.now()` as
      `initialTime`, and verify 1.1 passes

## 2. Start-time display follows the phone's clock format

- [x] 2.1 Add widget tests asserting a stored 07:30 start time displays as "7:30 AM" under a
      12-hour `MediaQuery` and "07:30" under a 24-hour one, and verify the 12-hour case fails
      against the raw stored string
- [x] 2.2 Add `_startTimeText(BuildContext)` using `MaterialLocalizations.formatTimeOfDay` and
      `MediaQuery.alwaysUse24HourFormatOf`, and use it in the start-time tile's subtitle, and
      verify 2.1 passes

## 3. Scheduled mode requires a day and a start time

- [x] 3.1 Add `routineFormDaysRequired` / `routineFormStartTimeRequired` to `app_en.arb` and
      `app_es.arb` next to the other `routineForm*` keys, and run `flutter gen-l10n`
- [x] 3.2 Add a widget test asserting a Scheduled save with a time but no day is blocked and shows
      the days error under the chips, and verify it fails
- [x] 3.3 Add a widget test asserting a Scheduled save with a day but no time is blocked and shows
      the start-time error under the tile, and verify it fails
- [x] 3.4 Add a widget test asserting selecting a day clears the days error, and verify it fails
- [x] 3.5 In `_save`, check `_mode == ScheduleMode.scheduled` after form validation passes; set
      `_daysError`/`_startTimeError` and return before building `Schedule` when either check fails;
      clear `_daysError` when a chip selection leaves `_days` non-empty and `_startTimeError` when
      a time is picked; render each error in `colorScheme.error`/`bodySmall` under its control; and
      verify 3.2–3.4 pass
- [x] 3.6 Confirm the existing "submitting with a name persists a new routine" test (Flexible mode,
      no days, no start time) still passes unmodified, proving Flexible saves are unaffected

## 4. Low-mode setup guidance moves to Routine detail

- [x] 4.1 Update the routines-list test asserting the guidance appears on a card with no essential
      step to instead assert it does not, and verify it fails against the current card
- [x] 4.2 Remove the guidance `Text` from `_RoutineCard` in `routines_list_screen.dart`, keeping
      the step-count line and chevron, and verify 4.1 passes
- [x] 4.3 Add widget tests on Routine detail asserting the guidance shows under the Steps header
      when steps exist and none is essential, and stays hidden when a step is essential or when
      there are no steps, and verify the "shows" case fails
- [x] 4.4 Add the guidance `Text` under the Steps header row in `routine_detail_screen.dart`, with
      `bodySmall`/`onSurfaceVariant` and left padding matching the Steps label, and verify 4.3
      passes

## 5. Verification

- [x] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
      above the current 571 baseline
- [x] 5.3 Run `openspec validate fix-routine-form-polish --type change --strict` and verify it
      passes
