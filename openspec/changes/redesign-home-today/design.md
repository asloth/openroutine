## Context

See `proposal.md`. The source is the `isHome` branch of `OpenRoutine.dc.html` in the Claude Design project. The data it needs already exists: `nextUpRoutine` and `upcomingState` rank today's scheduled routines, `routineCompletionsProvider` holds today's runs, and `statisticsProvider` has the overall streak.

## Goals / Non-Goals

**Goals:**

- Match the design's layout, type, and spacing on home.
- Keep every routine reachable from home.
- Work in every palette and in dark mode by reading colour roles, never literals.

**Non-Goals:**

- The design's green and its blob mascot.
- Live progress from a running timer. The timer's state is scoped to its screen and is gone once you leave it.
- The bottom navigation.

## Decisions

### Progress comes from today's latest run

A card shows **Done** and full pips when a run finished today. When the latest run today was stopped partway, the card shows how many steps it got through, such as "2 of 3". Otherwise the pips are empty and there's no badge.

*Alternative considered:* keeping the timer session alive to show live progress. Rejected for this change: it needs new state that outlives the timer screen, and the logs already answer "how far did I get today".

### Every dot uses the palette accent

The design gives each routine its own colour. Routines have no colour field, and adding one changes the public schema. The accent keeps the local palette and needs no schema decision.

### Other days stays collapsed

The timeline shows today only. Scheduled routines that aren't due today go into a collapsed **Other days** row at the bottom, until a dedicated Routines screen exists.

### Typefaces are cut to static weights

Both families ship from Google Fonts as variable fonts. Flutter doesn't pick a weight from a variable asset on its own, so the change bundles static 400, 500, 600, and 700 instances. Bricolage Grotesque is cut at an optical size of 28 and normal width.
