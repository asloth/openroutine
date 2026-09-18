## Why

Two defects on the Today screen, both reported by the user after using the app.

Flexible routines never leave Anytime today. The user picks no days for a flexible routine on
purpose — that's what "flexible" means — but a second, unrelated change lets flexible routines take
days too, the same way scheduled routines already do. Once a flexible routine has days, Today keeps
showing it every day regardless: `_buildDay`'s `anytime` list filters on `schedule.mode` alone,
while the `today` list right below it filters scheduled routines through `_dueToday`. A routine
scheduled for Tuesdays only shows up on Tuesdays; a flexible routine scheduled the same way shows up
forever. The user's own words: "if i not choose a date then its never scheduled for today ... so how
its showing in the today screen?"

Anytime routines also read as unrelated to the rest of the screen. `AnytimeSection` lays each one out
as a detached `HomeRoutineRow` — its own hairline border, its own 20px radius, separated by 8px gaps.
`Timeline` threads its cards onto a rail instead: a fixed-width column holding a 1px line with a dot
at each stop. Two visual languages on one screen, so Anytime reads as a pile of loose cards sitting
above the real timeline rather than the same list continuing downward. The user's words: "i dont like
the way flexible routines are displayed ... they seem two separate cards."

## What Changes

- Filter the `anytime` list in `_buildDay` through the same day check the `today` list already uses,
  with one exception: a flexible routine with no days set still shows, because empty days can mean
  "hasn't been migrated yet" (a Drive sync from another device, or a local database migration that
  hasn't run), not "never." Silently dropping those routines off Today would be worse than the bug
  this fixes.
- Extract the timeline's rail — the fixed-width time column, the line, and the dot — into a widget
  the Anytime section can share, and thread Anytime's rows onto it without a time value, so the two
  sections read as one spine down the screen instead of two unrelated layouts.

`HomeRoutineRow` itself is untouched; it's still what the Routines tab renders for every routine, and
this change doesn't touch that screen.

## Capabilities

### Modified Capabilities

- `home-today` — Anytime today now respects the days a flexible routine is scheduled for, the same
  way the timeline already does for scheduled routines, and its rows share the timeline's rail rather
  than standing apart from it.

## Impact

**Code.** `app/lib/screens/routines_list/routines_list_screen.dart` (the `anytime` filter),
`app/lib/screens/routines_list/home/timeline.dart` (new shared `HomeRail` widget),
`app/lib/screens/routines_list/home/anytime_section.dart` (rows wrapped in the rail, padding aligned
to the timeline's). Widget tests in
`app/test/screens/routines_list/routines_list_screen_test.dart`.

**Storage and schema.** None. `Schedule.days` already exists; this only changes how the Today screen
reads it for flexible routines.

**Other screens.** None. The Routines tab renders `HomeRoutineRow` directly, outside this change, and
its own test suite is unchanged and still green.

**i18n.** None. No new user-facing strings.

**Rollback.** Reverting restores the mode-only filter and the two separate layouts. Nothing persisted
changes shape, so there's nothing to unwind.
