## Context

See `proposal.md` — Why. `RoutineFormScreen` is a `ConsumerStatefulWidget` that loads a `Routine`
once (`_loadFrom`, guarded by `_loaded`) into local mutable state (`_days`, `_startTime`, `_mode`),
then writes that state back out through `_save`. The routines list already solves the display half
of this problem: `_StartTime` in `routines_list_screen.dart` parses "HH:mm" defensively and formats
it with `MaterialLocalizations.formatTimeOfDay`. The form had never adopted either piece.

## Goals / Non-Goals

**Goals:**

- Make the time picker and the time display both read the routine's actual stored state, the way
  every other field on this form already does.
- Make a Scheduled routine that can never remind or show as upcoming impossible to save silently.
- Move the low-mode setup guidance to the one place a person is actually adding steps, instead of
  repeating it on every card that lacks one.

**Non-Goals:**

- Changing the stored `Schedule` shape, or `Schedule.days/startTime`'s validity as JSON. A schema
  file with no days and no start time was and remains a valid Scheduled routine — this only stops
  the form from producing a new one.
- Retroactively fixing routines that already have no days or no start time. They keep loading and
  editing normally; the form just won't let a *save* leave them that way.
- Changing what "essential step" means or how `isCore` is set. This only relocates where its
  absence is explained.

## Decisions

### The picker's `initialTime` comes from the same parse `_StartTime` uses

`RoutineFormScreen` gets its own private `_parseStartTime`, copying `_StartTime._parse`'s logic
(split on ":", `int.tryParse` both halves, range-check 0–23/0–59, `null` on anything else) rather
than importing the routines-list private class.

*Alternative considered:* making `_StartTime._parse` public and importing it. Rejected — the two
screens don't otherwise share code, and a routine schedule's stored format is small and stable
enough (it's the schema's own field) that duplicating the seven-line parse costs less than adding a
cross-screen dependency for it.

### Display formatting is a method, not a field, so it stays live against `MediaQuery`

`_startTimeText(BuildContext)` is computed at build time from `_startTime`, not cached in state.
The stored field never changes shape — only what `build` shows for it does, and that must track
`MediaQuery.alwaysUse24HourFormatOf(context)` on every rebuild, including a locale or settings
change mid-session.

### Validation lives in `_save`, not in `FormState.validator`s

The day chips and the start-time tile aren't `FormField`s — chips are a `Wrap` of `FilterChip`, and
the time tile is a `ListTile` with an `onTap`. Retrofitting both into `FormField` wrappers just to
reuse `_formKey.currentState.validate()` would touch more of the layout than the defect calls for.
Instead, `_save` checks `_mode == ScheduleMode.scheduled` after the existing form validation passes,
sets `_daysError`/`_startTimeError` strings in state when a check fails, and returns before ever
building the `Schedule` — so a save that fails validation never reaches storage.

*Alternative considered:* a single combined error under the mode toggle ("Scheduled routines need a
day and a start time"). Rejected — the two fields are independent and can fail independently (one
set, one missing), and pointing the error at the specific control that needs attention is more
useful than a single message the user has to map back onto two separate widgets themselves.

### Each error clears itself, not both together

Selecting a day clears `_daysError` only when `_days` is then non-empty; picking a time clears
`_startTimeError` unconditionally (picking *is* setting it). Neither touches the other's error.
Fixing one field while the other is still blank leaves that field's message in place, which is
correct — it's still true.

### The guidance line's placement condition mirrors the list card's old one

The old card check was `steps != null && !hasCoreSteps` (`hasCoreSteps = steps?.any((s) =>
s.isCore) ?? false`), which happens to read as "false while steps hasn't loaded yet." Routine
detail loads `steps` synchronously off `stepsAsync.requireValue` by the time this section renders
(the loading/error branches return earlier), so the new condition is exactly `steps.isNotEmpty &&
!steps.any((step) => step.isCore))` — no additional null-guard needed, and it naturally hides for
an empty routine, where "no steps are essential" isn't a useful thing to say yet.

## Risks / Trade-offs

**Duplicated parse logic between two screens.** → Both copies read the same seven lines against the
same documented format (`schemas/routine.schema.json`). A future format change is a schema change
either way, and `schema_validator_test.dart` already forces both `schemas/*.json` copies to move
together — this doesn't add a third place that could drift silently, since neither copy has its own
independent notion of what's valid.

**A person editing an old Scheduled routine with no days or no time sees new errors on their first
save attempt, for a state they didn't just create.** → Intended: the routine was already silently
broken (never upcoming, never reminding), and this is the first time the form says so. The fix is
one tap away — pick a day, or pick a time — and nothing about the existing routine's other fields
is disturbed.

## Migration Plan

None. Presentation and form-level validation only; nothing persisted changes shape, and a routine
already saved with no days or no start time keeps loading exactly as it does today.
