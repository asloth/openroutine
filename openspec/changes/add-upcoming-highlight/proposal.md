## Why

`restyle-routines-list` gave every routine card a flat accent fill, and
`add-accent-color` reserved a fixed green for "this is coming up soon" — but
nothing on the Routines list actually turns a card green yet. Someone
glancing at the list right now can't tell which routine is about to start
without opening it.

## What changes

- A routine card turns the fixed upcoming green from 15 minutes before its
  start time until its start time plus its estimated duration, or until it's
  finished today, whichever comes first.
- The card also says so in words — "in {minutes} min" before the start,
  "Now" once it's started — so the state never rides on color alone.
- Everything else about the card (fill and colors when it's not upcoming,
  layout, navigation, Low Mode) is unchanged.

## Capabilities

### New Capabilities

- `upcoming-routines` — when a routine counts as "coming up," and how its
  card communicates that in color and text.

## Impact

**Code.** Two new pure services
(`app/lib/services/routines/upcoming.dart`,
`app/lib/services/routines/estimate.dart`), a new clock provider in
`app/lib/state/`, and `app/lib/screens/routines_list/routines_list_screen.dart`
(`_RoutineCard` only). The start-time parsing and weekday mapping that
`app/lib/services/notifications/routine_reminders.dart` already has move to a
small shared file so `upcoming.dart` reuses them instead of copying them;
`routine_reminders.dart`'s own behavior and tests are unchanged.

**Screens.** Only the routines list, and only its card. No other screen, and
nothing else on this screen (header, segmented control, section labels, FAB)
changes.

**Storage and schema.** None. This reads existing routine, step, and
completion data; nothing new is persisted.

**i18n.** Two new strings in both `app_en.arb` and `app_es.arb`:
`routinesUpcomingIn` and `routinesUpcomingNow`.

**Rollback.** Reverting this change removes the green highlight and the two
new strings; every card goes back to always showing the accent fill. Nothing
persisted changes shape, so there's nothing to migrate either direction.
