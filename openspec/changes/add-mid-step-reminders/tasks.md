Chained delivery. Each numbered group is a review point; the suite must be green at the end of every one, not only at the end.

**This change is being delivered in slices. Phase 1 — the storage foundation — and phase 2 — the notification channel and scheduling — are done.** Phase 3 puts the control on screen and is not started; nothing in phases 1 and 2 lets a user turn the flag on, so the feature is still reachable only by a step whose stored value is already true.

## 1. Storage foundation — review point — **DONE**

- [x] 1.1 Add a failing `schema_version_test` case asserting `1.2.0` parses to the current version and that `1.1.1`, `1.2.1`, `1.3.0` and `2.0.0` still reject as newer, and verify it fails while 1.2.0 is rejected
- [x] 1.2 Add a failing `local_adapter_test` case round-tripping `remindDuring` through `saveStep`/`getSteps`, plus one asserting a step JSON with no `remind_during` reads back false, and verify both fail to compile because the field does not exist
- [x] 1.3 Extend `migration_test`'s raw v1 and raw v3 blocks to assert the new column defaults to false on migrated rows, and move the v3 block's `user_version` assertion from 5 to 6, and verify they fail
- [x] 1.4 Add `@Default(false) bool remindDuring` to `RoutineStep` beside `isCore`, and the defaulted `BoolColumn` to the `RoutineSteps` drift table
- [x] 1.5 Bump `schemaVersion` 5 → 6, add the `if (from < 6)` `addColumn` branch, and extend the doc comment above `schemaVersion` in its established style
- [x] 1.6 Carry the field through `LocalAdapter.saveStep` and `_stepFromRow`
- [x] 1.7 Add the `remind_during` property to `schemas/step.schema.json` with `"default": false`, deliberately absent from `required`, and mirror it byte-identically into `app/assets/schemas/step.schema.json` — `schema_validator_test` enforces the two files match
- [x] 1.8 Add `v1_2('1.2.0')`, move `current`/`currentValue` to it, and rewrite `parseSupported`'s accept/reject arithmetic and `isNewer` classification so the accepted set is stated once rather than hardcoded a third time
- [x] 1.9 Update the collateral version literals the bump invalidates: `drive_sync_test`'s cutover approval and written authority move to 1.2.0 and its "newer remote" fixture to 1.3.0; `local_adapter_test`'s and `import_screen_test`'s "newer bundle" fixtures move to 1.3.0
- [x] 1.10 Re-run code generation and commit the regenerated `.freezed.dart` and `.g.dart`, verifying the generated `fromJson` reads `json['remind_during'] as bool? ?? false`
- [x] 1.11 Run `flutter analyze --fatal-infos` and the full suite from `app/` and verify both are clean

## 2. Notification channel and scheduling — review point — **THIS SLICE**

- [x] 2.1 Add a mid-step notification channel with sound and vibration enabled, on a new immutable channel id (`step_progress_nudge_v1`), leaving the silent boundary channel untouched — the two existing silence assertions are a deliberate regression guard and still pass
- [x] 2.2 Add failing tests for the 50% and 80% schedule times of an opted-in step, then implement and verify — the marks are computed relative to `now` in the pure `TimerState.remainingUntilFraction`, never from `stepStartedAt + fraction × estimate`, so a pause cannot leave a stale absolute alarm
- [x] 2.3 Add a failing test asserting a step estimated under 120 seconds schedules neither nudge, then implement and verify
- [x] 2.4 Add a failing test asserting a step with no explicit time schedules neither nudge, then implement and verify
- [x] 2.5 Add failing tests asserting both nudges are cancelled when a step ends, is skipped, is deferred, and when a run is abandoned, then implement and verify — covered by extending `cancelPending()` to all three ids, which every lifecycle path already routes through, including `ref.onDispose`
- [x] 2.6 Add a failing test asserting pause cancels both and resume reschedules them against the recomputed remaining time, then implement and verify — including a step already past its 50% mark when it resumes, whose passed mark is dropped rather than fired late
- [x] 2.7 Add the channel name and description to `app_en.arb` and `app_es.arb` together, plus the two nudge bodies
- [x] 2.8 Fix the iOS sound permission: it was requested as `sound: false`, which would have played nothing on iOS whatever the channel said

## 3. Step form control — NOT IN THIS SLICE

- [ ] 3.1 Add a failing widget test asserting a newly created step starts with the toggle on while an existing step reflects what is stored, then implement and verify — the model default stays false; this is form state only
- [ ] 3.2 Add a failing widget test asserting the toggle is unavailable or inert for a step with no explicit time, then implement and verify
- [ ] 3.3 Add the toggle label and its explanatory text to `app_en.arb` and `app_es.arb` together

## 4. Verification — NOT IN THIS SLICE

- [ ] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [ ] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or above the then-current baseline
- [ ] 4.3 Confirm on device that a mid-step nudge sounds and vibrates while the step-end nudge stays silent
- [ ] 4.4 Run `openspec validate add-mid-step-reminders --type change --strict` and verify it passes
