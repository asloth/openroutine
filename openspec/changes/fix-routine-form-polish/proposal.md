## Why

Four small defects, all visible on device and none caught by tests.

Editing a Scheduled routine's start time opens the time picker at `TimeOfDay.now()` instead of the
time the routine already has. Pick a routine that starts at 7:30, tap the start-time tile, and the
picker opens on whatever time it happens to be — you have to know your own routine's time and dial
past the current one to confirm it.

The start-time tile then shows the raw stored string, "07:30", while the routines list formats the
same value with `MaterialLocalizations.formatTimeOfDay` and the phone's 12-hour or 24-hour setting.
On a 12-hour phone, the form and the list disagree about what a routine's own start time looks like.

A Scheduled routine saves fine with no days and no start time selected. It then never appears as
upcoming and never reminds — and nothing on the form says why, so the missing behavior reads as a
bug somewhere else entirely.

Last, every routine card without an essential step shows "Choose at least 1 essential step to make
Low Mode available; 2 or 3 is recommended." as a third line. On a fresh install, before anyone has
marked any step essential, every card shows it — cluttering the one screen meant to stay short.

## What Changes

- `_pickStartTime` opens the time picker at the routine's stored start time when it parses, falling
  back to now only when there is none.
- The start-time tile displays with `formatTimeOfDay` and `MediaQuery.alwaysUse24HourFormatOf`,
  matching `_StartTime` on the routines list. The stored "HH:mm" format is unchanged.
- Saving a Scheduled routine with no day selected shows an inline error under the day chips.
  Saving with no start time shows an inline error under the start-time tile. Either blocks the
  save; each clears once its own field is fixed. Flexible mode is unaffected.
- The low-mode setup guidance moves off the routines list card and onto Routine detail, directly
  under the Steps header, shown only when the routine has at least one step and none of them is
  essential.

## Capabilities

### New Capabilities

- `routine-form` — the Scheduled/Flexible routine form's own behavior: how it seeds the time
  picker, how it displays a stored start time, and what it requires before a Scheduled routine can
  save.

## Impact

**Code.** `app/lib/screens/routine_form/routine_form_screen.dart` (time picker seed, time display,
inline validation), `app/lib/screens/routines_list/routines_list_screen.dart` (guidance line
removed from `_RoutineCard`), `app/lib/screens/routine_detail/routine_detail_screen.dart` (guidance
line added under the Steps header). Widget tests in all three screens' test folders.

**Storage and schema.** None. `Schedule.days` and `Schedule.startTime` already exist and already
accept empty/null; this only adds form-level validation before a save reaches storage. No file
under `schemas/` changes.

**i18n.** Two new keys, `routineFormDaysRequired` and `routineFormStartTimeRequired`, added to both
`app_en.arb` and `app_es.arb` next to the other `routineForm*` keys.

**Existing users.** A routine already saved with no days or no start time keeps loading and editing
normally — the validation only blocks a new save, so an existing gap doesn't lock the routine out
of the form. It's still visible as "not upcoming," and the user now gets a clear reason the next
time they open the form to fix it.

**Rollback.** Reverting restores the three defects. Nothing persisted changes shape, so there is
nothing to unwind.
