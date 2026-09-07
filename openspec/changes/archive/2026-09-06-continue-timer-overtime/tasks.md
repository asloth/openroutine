# Tasks: Continue Timer into Overtime

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 260–340 |
| 400-line budget risk | Low |
| 400-line budget at risk | No |
| Chained PRs recommended | No |
| Suggested split | Single PR: timer overtime behavior and its tests |
| Delivery strategy | auto-chain |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Continuous timer, yellow boundary, and completion state | Single PR | `cd app && flutter test test/services/timer/timer_machine_test.dart test/screens/timer/timer_screen_test.dart` | N/A: no integration/E2E harness exists; controlled widget timestamps exercise the UI | Revert the four timer source/test files |

## Phase 1: Timer Machine TDD

- [x] 1.1 RED — In `app/test/services/timer/timer_machine_test.dart`, add fixed-time tests for green at estimate-1s, yellow at estimate and later, no reachable orange, and paused elapsed preservation.
- [x] 1.2 GREEN — In `app/lib/services/timer/timer_machine.dart`, make `EstimateZone` green/yellow/unbounded and return yellow when timed elapsed is at least the estimate.
- [x] 1.3 RED — In `app/test/services/timer/timer_machine_test.dart`, test Done before/at/after estimate (`completed`/`completed`/`overrun`), untimed completion, and existing overrun JSON keys/value round-trip.
- [x] 1.4 GREEN — In `app/lib/services/timer/timer_machine.dart`, classify only timed `spent.inSeconds > durationSeconds` completions as `overrun`; retain existing JSON fields and other outcomes.
- [x] 1.5 REFACTOR — Simplify timer boundary/completion helpers in `app/lib/services/timer/timer_machine.dart` while all Phase 1 tests remain green.

## Phase 2: Timer Screen TDD

- [x] 2.1 RED — In `app/test/screens/timer/timer_screen_test.dart`, drive controlled timestamps and assert timed text `1:59`, `2:00`, `2:01` appears continuously with elapsed semantics.
- [x] 2.2 RED — In `app/test/screens/timer/timer_screen_test.dart`, assert tertiary clock/full ring at and after `2:00`, no orange, label, or `+` visually or semantically, and unchanged untimed “No set time” UI.
- [x] 2.3 GREEN — In `app/lib/screens/timer/timer_screen.dart`, render timed `TimerState.elapsed(now)`, remove zone/live-region labels, and apply tertiary to clock/ring at and after the boundary.
- [x] 2.4 REFACTOR — Consolidate the `_Running` snapshot and `_Clock` styling in `app/lib/screens/timer/timer_screen.dart` without changing untimed or paused behavior.

## Phase 3: Verification

- [x] 3.1 Run the two focused timer suites from `app/` and confirm every continuous-display, boundary, completion, JSON, and untimed scenario passes.
- [x] 3.2 Run `cd app && flutter analyze --fatal-infos && flutter test`; record that no schema, storage, i18n, or generated-file changes are required.
