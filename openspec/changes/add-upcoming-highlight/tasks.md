## 1. Shared start-time/weekday helpers (slice 1)

- [ ] 1.1 Extract `ReminderSchedule._parseStartTime` and `._weekday` into a new
      `ScheduleTime` class in `app/lib/services/routines/schedule_time.dart`, unchanged in
      behavior; update `routine_reminders.dart` to call it, and verify
      `routine_reminders_test.dart` still passes unmodified

## 2. Estimate service (slice 2)

- [ ] 2.1 Add `test/services/routines/estimate_test.dart` covering: sums timed steps, skips
      `noExplicitTime` steps, treats a null duration as zero, and returns zero for an empty
      list; verify it fails (no such file yet)
- [ ] 2.2 Add `app/lib/services/routines/estimate.dart` with `routineEstimate`, and verify 2.1
      passes

## 3. Upcoming-state service (slice 3)

- [ ] 3.1 Add `test/services/routines/upcoming_test.dart` covering all 16 cases from
      `specs/upcoming-routines/spec.md`, and verify it fails
- [ ] 3.2 Add `app/lib/services/routines/upcoming.dart` with the `UpcomingState` sealed type
      (`StartsIn`, `InProgress`) and `upcomingState(...)`, reusing `ScheduleTime`, and verify
      3.1 passes

## 4. Clock provider (slice 4)

- [ ] 4.1 Add `app/lib/state/clock_provider.dart`: a `@Riverpod(keepAlive: true)` `Clock`
      notifier emitting `DateTime.now()` immediately, refreshed every 30 seconds by a
      `Timer.periodic` started in `build()` and cancelled via `ref.onDispose`
- [ ] 4.2 Run codegen (`dart run build_runner build --delete-conflicting-outputs`)

## 5. ARB strings (slice 5)

- [ ] 5.1 Add `routinesUpcomingIn` ("in {minutes} min", int placeholder, with a description)
      and `routinesUpcomingNow` ("Now") to `app_en.arb`
- [ ] 5.2 Add the Spanish translations ("en {minutes} min", "Ahora") to `app_es.arb`
- [ ] 5.3 Run `flutter gen-l10n`

## 6. Wire the card (slice 6)

- [ ] 6.1 Add widget-test coverage in `routines_list_screen_test.dart` (clock overridden): a
      routine 10 minutes out is green and shows "in 10 min"; one in progress shows "Now"; one
      completed today stays accent-colored; the green card still navigates on tap; Low Mode
      still works from a green card; no overflow at 2.0x text scale with the new text; verify
      each new assertion fails against the current screen
- [ ] 6.2 In `_RoutineCard`, watch `clockProvider` and `routineCompletionsProvider(routine.id)`
      alongside the existing `routineStepsProvider`; compute `routineEstimate(steps)`,
      `completedToday`, and `upcomingState(...)`; when non-null, fill the `TintedCard` with
      `upcomingFill`/`onUpcomingFill` and append the "in {n} min"/"Now" text to the step-count
      line; add a `Semantics` hint carrying the same words; verify 6.1 passes and every
      existing test in the file still passes

## 7. Verification

- [ ] 7.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify
      no issues
- [ ] 7.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite
      passes
- [ ] 7.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')`
