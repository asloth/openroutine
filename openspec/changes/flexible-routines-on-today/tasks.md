## 1. Flexible routines respect their days

- [x] 1.1 Add a widget test asserting a flexible routine due today appears under Anytime today, and
  verify it passes without changes (the empty-days default already covers it)
- [x] 1.2 Add a widget test asserting a flexible routine due only on another day does not appear
  under Anytime today, and verify it fails against the mode-only filter
- [x] 1.3 Add the day check to the `anytime` list in `_buildDay`, with the empty-days fallback and a
  comment explaining why it's there, and verify 1.2 passes
- [x] 1.4 Add a widget test asserting a flexible routine with no days set still appears, and verify
  it passes

## 2. Anytime today shares the timeline's rail

- [x] 2.1 Add a widget test asserting the Anytime row's rail dot and the timeline row's rail dot sit
  at the same horizontal position, and verify it fails (Anytime has no rail yet)
- [x] 2.2 Extract `HomeRail` from `_TimelineRow` in `timeline.dart`, with an optional `time` slot that
  leaves the 56px column empty rather than removing it, and repoint `_TimelineRow` at it
- [x] 2.3 Wrap each row in `AnytimeSection` in `HomeRail`, with no time
- [x] 2.4 Align `AnytimeSection`'s list padding with the timeline's outer inset so the two rails land
  on the same x, and verify 2.1 passes
- [x] 2.5 Confirm `HomeRoutineRow` itself is unchanged and the Routines tab's test suite
  (`routines_library_screen_test.dart`) still passes unmodified

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
  issues
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
  above the current 571 baseline
- [x] 3.3 Format only the touched files with
  `/home/sabera/fvm/bin/fvm dart format <touched files>`
