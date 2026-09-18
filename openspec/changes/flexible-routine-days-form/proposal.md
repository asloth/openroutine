## Why

A user picked Flexible on the routine form and found she couldn't choose any days. The day chips and
the start-time row are both wrapped in the same `if (_mode == ScheduleMode.scheduled)` block in
`app/lib/screens/routine_form/routine_form_screen.dart`, so switching to Flexible hides both at once.
On save, the schedule is built with `days: _mode == ScheduleMode.scheduled ? _days.toList() : const []`
— so editing an existing scheduled routine and switching it to Flexible silently wipes the days it
already had.

The product rule she chose: a flexible routine has days but no start time. A routine still needs to
know which days it belongs to; it just doesn't pin a clock time to them. Only the start time is
genuinely scheduled-only.

## What Changes

- Show the day chips (and their validation error) in both Scheduled and Flexible mode. The start-time
  row stays Scheduled-only.
- Require at least one day in both modes. The start-time requirement stays Scheduled-only.
- Persist `_days` unconditionally on save, instead of forcing it to `const []` for Flexible.

## Capabilities

### New Capabilities

- `routine-form-schedule` — what the Create/Edit routine form requires and persists for each
  schedule mode.

## Impact

**Code.** `app/lib/screens/routine_form/routine_form_screen.dart` only. No new i18n strings — the
existing `routineFormDaysRequired` string already reads as mode-neutral ("Pick at least one day").

**Storage and schema.** None. `schemas/routine.schema.json` never gated `days` on `mode`, and
`scheduleDays` is already a column in `app/lib/services/storage/drift/tables.dart`. Flexible
routines with days were always a valid stored shape; the form just never let anyone produce one.

**Existing users.** A Flexible routine saved before this change has `days: []`. It stays valid and
loads normally — it just now needs at least one day the next time someone edits and saves it. An
in-progress edit that switches Scheduled to Flexible now keeps its days instead of losing them.

**i18n.** None.

**Rollback.** Reverting restores the old (broken) behavior. Nothing persisted changes shape, so
there's nothing to unwind.
