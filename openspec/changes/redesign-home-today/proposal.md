## Why

The app is getting a full redesign, one screen at a time, from the Claude Design project `OpenRoutine.dc.html`. Home is first. Today's home is a list sorted into Scheduled and Flexible tabs and grouped by moment. The design answers a different question: what does my day look like, and what's next? It's a single timeline for today, a strip of routines you can start any time, and a nudge from the mascot when something is about to start.

The design uses a green palette and a placeholder blob mascot. Neither ships. Colours come from the user's own palette, and the mascot is the Rive pet from `add-rive-mascot`.

## What Changes

- Swap the bundled typefaces app-wide: Bricolage Grotesque replaces Lexend for structure and actions, and Plus Jakarta Sans replaces Inter for prose.
- Replace the home header with the date, a time-of-day greeting, a streak pill that opens Statistics, and the Settings gear.
- Replace the Next up hero with a nudge card: the mascot, when the next routine starts, and a Start button that opens the timer.
- Replace the Scheduled and Flexible tabs and the moment headings with:
  - **Anytime today**, a pinned, collapsible strip of flexible routines, each with Start.
  - A **timeline** of routines scheduled for today, sorted by start time, each card showing today's progress.
  - **Other days**, a collapsed list of scheduled routines not due today, so none of them becomes unreachable.
- Keep the Low mode shortcut on routines with core steps.
- Turn the round add button into an **Add a routine** pill.

## Capabilities

### New Capabilities

- `home-today` — what the home screen shows for today and how each routine on it can be started.

## Impact

**Code.** `app/lib/theme/typography.dart`, `app/pubspec.yaml`, the bundled fonts, and `app/lib/screens/routines_list/`. `DESIGN.md` and `docs/SPEC.md` name the new typefaces.

**Storage and schema.** None. Progress comes from today's completion logs, which already record the steps a stopped run got through. No file under `schemas/` changes, and routines gain no colour field; dots use the palette's accent.

**i18n.** New strings for the greeting, the nudge card, Anytime today, progress, and Other days, in both `app_en.arb` and `app_es.arb`.

**Out of scope.** The bottom navigation (the design's Today, Routines, and Streaks tabs) and the other screens come in later changes.

**Rollback.** Reverting restores the tabbed list and the previous typefaces. Nothing is persisted differently.
