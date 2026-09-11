## 1. Next-up selection service (slice 1)

- [x] 1.1 Add `test/services/routines/next_up_test.dart` covering all 8 cases from
      `specs/next-up/spec.md`, and verify it fails (no such file yet)
- [x] 1.2 Add `app/lib/services/routines/next_up.dart` with `nextUpRoutine(...)`, reusing
      `ScheduleTime`, and verify 1.1 passes

## 2. ARB string (slice 2)

- [x] 2.1 Add `routinesNextUp` ("Next up", with a description) to `app_en.arb`
- [x] 2.2 Add the Spanish translation ("Lo siguiente") to `app_es.arb`
- [x] 2.3 Run `flutter gen-l10n`

## 3. Hero card (slice 3)

- [x] 3.1 Add widget-test coverage in `routines_list_screen_test.dart` (clock overridden): the
      card shows for the earliest-remaining routine; green when upcoming with "in N min", accent
      otherwise; Start Timer navigates to the timer route; tapping the card elsewhere opens
      detail; no card when nothing is left today; not shown on the Flexible tab; the routine
      still appears in its moment group; no overflow at 2.0x text scale; verify each new
      assertion fails against the current screen
- [x] 3.2 Adjust the small number of existing "upcoming state" tests whose single-routine fixture
      now also qualifies as next up, so their finders target the moment-group card specifically
      instead of assuming only one `TintedCard`/matching text exists on screen; verify they still
      pass and still assert the same behavior they did before
- [x] 3.3 Add `_NextUpCard` and wire `_RoutineSectionList` (Scheduled tab only) to compute
      `nextUpRoutine(...)` from its routines, `clockProvider`, and each candidate's
      `routineStepsProvider`/`routineCompletionsProvider`, rendering the card above the moment
      groups when a winner exists; verify 3.1 passes and every existing test in the file still
      passes

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite
      passes (571 pass)
- [x] 4.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')`
