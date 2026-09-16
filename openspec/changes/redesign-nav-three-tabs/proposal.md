## Why

The redesign's navigation has three destinations: Today, Routines, and Streaks. The app has two, Routines and Statistics, where Routines is really today's view. Home is now a day view, so routines due on other days sit in an Other days fold at the bottom of it. That was a stopgap until the app had a place for every routine.

## What Changes

- The floating nav pill carries three destinations: **Today** (home), **Routines** (new), and **Streaks** (the statistics screen, renamed in the bar).
- Add a Routines screen listing every routine: scheduled ones by start time, then the ones you can start any time, with Add a routine.
- Remove Other days from home, since Routines covers it.
- Let the pill fit a narrow phone at a large text scale with three destinations: it never grows past the screen, and each destination shrinks and wraps its label instead.
- Share the Add a routine pill between Today and Routines.

This supersedes the decision in `float-bottom-nav` to carry two destinations, and the Other days requirement in `redesign-home-today`.

## Capabilities

### New Capabilities

- `app-navigation` — the top-level destinations and what the Routines destination lists.

## Impact

**Code.** `app/lib/main.dart` (a new shell branch at `/library`), `app/lib/screens/shell/`, the new `app/lib/screens/routines_library/`, and home. Today keeps its `/routines` path, so onboarding, the home screen widget, and deep links don't change.

**Storage and schema.** None.

**i18n.** Adds Today and Anytime, renames the Statistics nav label to Streaks, and removes Other days, in both ARB files. The statistics screen's own title doesn't change yet.

**Rollback.** Reverting restores two destinations and the Other days fold.
