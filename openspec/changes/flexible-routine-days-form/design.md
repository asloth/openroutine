## Context

See `proposal.md` — Why. `_RoutineFormScreenState.build` renders the day chips, the days error, the
start-time `ListTile`, and its error all inside one `if (_mode == ScheduleMode.scheduled) ...[` block
(around line 234 before this change). `_save()` mirrors the same gating for validation (around lines
91–100) and for the `Schedule` it builds (around lines 111–112).

## Goals / Non-Goals

**Goals:**

- Days are available and required in both Scheduled and Flexible mode.
- Start time stays Scheduled-only, in the UI, in validation, and in what gets saved.
- Switching an existing routine's mode never silently drops data the user already entered.

**Non-Goals:**

- Changing `schemas/routine.schema.json` or the Drift table shape. Neither gates `days` on `mode`
  today, so no schema or migration work is needed.
- Restyling the form, reordering sections, or touching the segmented mode control itself.
- Changing how `days` behaves for routines created before this change — a stored Flexible routine
  with `days: []` still loads; it only needs at least one day the next time it's saved.

## Decisions

### Split one `if` block into two

The day chips (and `_daysError`) move above the mode check and always render. The start-time
`ListTile` (and `_startTimeError`) stay inside `if (_mode == ScheduleMode.scheduled)`. This keeps the
visual order exactly as it was — days, then start time — for Scheduled mode, and just removes the
start-time section for Flexible.

*Alternative considered:* two separate conditionals with duplicated `SizedBox` spacers, one gating
days-only and one gating start-time-only, kept as two independent `if` blocks from the start rather
than splitting one. Rejected only for phrasing — the end structure is the same either way; the
change is easiest to review as "days come out of the block, start time stays."

### Validation always checks days; start time check stays conditional

`_save()`'s single `if (_mode == ScheduleMode.scheduled) { ... }` validation block becomes an
unconditional days check plus a start-time check that's still gated on mode. Both errors can now be
set independently of each other in a single `setState`, same as before.

### Save always persists `_days`; start time still nulls out for Flexible

`Schedule(mode: _mode, days: _days.toList(), startTime: _mode == ScheduleMode.scheduled ? _startTime
: null)`. This is the one-line fix for the data-loss bug: switching an existing Scheduled routine to
Flexible and saving now keeps its days instead of forcing them to `const []`.

### `_startTime` state isn't cleared on a mode switch

Switching from Scheduled to Flexible in the UI leaves `_startTime` untouched in widget state — only
what gets saved is forced to `null` for Flexible. If someone flips Scheduled → Flexible → Scheduled
in one editing session, the time they'd already picked is still there instead of making them re-pick
it. The start-time row is hidden while in Flexible mode, so nothing stale is visible; it only matters
if they switch back. This mirrors how `_days` already behaves for the reverse direction — nothing
here clears `_days` on a mode switch either.

*Alternative considered:* clearing `_startTime` (and its error) whenever `_mode` changes away from
Scheduled, so state never outlives its visible row. Rejected: it adds a `setState` side effect to the
segmented button's `onSelectionChanged` for no behavioral gain — the saved value is already forced
to `null` regardless of what widget state holds — and it would make a Scheduled → Flexible →
Scheduled round trip lose a start time the user never asked to remove.

## Risks / Trade-offs

**A Flexible routine saved before this change has `days: []`.** → Intended. It stays valid to load;
`_loadFrom` just populates an empty `_days` set, and the days-required error surfaces the next time
someone tries to save it, same as an incomplete Scheduled routine already does.

**Reusing `routineFormDaysRequired` for both modes.** → The string already reads as mode-neutral
("Pick at least one day" / "Elige al menos un día"), so no new ARB key is needed for either
language.

## Migration Plan

None. No schema or Drift table change; existing rows already satisfy the new shape (a Flexible row
with `days: []` is a possible, if now newly-invalid-to-resave, value — not a possible-to-crash-on
one).
