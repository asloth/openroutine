## Context

See `proposal.md` — Why. The routines list (`restyle-routines-list`, merged) renders every
`_RoutineCard` as a `TintedCard` filled with `context.routineCardColors.fill`/`onFill` — the
accent. `add-accent-color` (merged) already put a fixed, palette-independent green on the theme
as `RoutineCardColors.upcomingFill`/`onUpcomingFill`. Nothing computes *when* a card should use
that green; this change adds that computation and wires the card to it.

## Goals / Non-Goals

**Goals:**

- A pure, clock-free function that decides whether a routine counts as "coming up" right now,
  and if so, how — still counting down, or already running.
- Reuse the start-time parsing and weekday mapping `ReminderSchedule` already has, instead of a
  second copy that can drift from it.
- Wire the routines list card to that function through a small, testable clock, without touching
  any other part of the card or screen.

**Non-Goals:**

- Touching `routine_detail_screen.dart`. It was just restyled by a parallel change and has its
  own copy of the estimate math (`_estimatedDuration`); this change adds an equivalent pure
  function elsewhere and leaves the screen's copy alone. A later change can switch the screen
  over.
- A new spacing token, color, or shared widget. `TintedCard` already takes a fill/foreground
  pair; this change only decides which pair to pass it.
- Any change to how reminders are scheduled. `ReminderSchedule` keeps deciding when a
  notification fires; `upcoming.dart` only decides how a card looks right now.

## Decisions

### The shared start-time/weekday helpers move to `app/lib/services/routines/schedule_time.dart`

`ReminderSchedule._parseStartTime` and `ReminderSchedule._weekday` are private today.
`upcoming.dart` needs the same two computations — parsing `Schedule.startTime` and mapping
`DayOfWeek` to `DateTime.weekday` — and copying them would let the two drift apart on the next
edit. Both move, unchanged, to a new `abstract final class ScheduleTime` in a shared file that
both `routine_reminders.dart` and `upcoming.dart` import. `ReminderSchedule.occurrences` and
`.build` keep their exact behavior; only where the two helpers live changes, so
`routine_reminders_test.dart` (which only calls the public API) needs no edit.

### `upcomingState` takes `now`, `estimate`, and `completedToday` as parameters, not providers

The function lives in `app/lib/services/routines/`, next to `estimate.dart`, with no import of
Riverpod, Drift, or anything else stateful — the same "pure date maths, no plugin and no I/O"
shape `ReminderSchedule` already uses, for the same reason: a fake `now` is how the 16
test cases stay deterministic without a fake clock harness. The routines list screen is the only
caller that has to assemble `now`, `estimate`, and `completedToday` from providers.

### One shared clock provider, not a `Timer` inside each card

Every visible `_RoutineCard` needs the same `now` to decide its state, and a `Timer` per card
would mean as many timers as routines on screen, all firing at slightly different offsets. A
single `@Riverpod(keepAlive: true)` notifier in `app/lib/state/clock_provider.dart` holds
`DateTime.now()` as its state, refreshed by one `Timer.periodic(Duration(seconds: 30))` started
in `build()` and cancelled via `ref.onDispose`. Every card watches the same provider, so they all
re-evaluate together on the same tick. `keepAlive` matches the pattern
`app_prefs_provider.dart` already uses for a value that should outlive any one screen watching
it. Widget tests override it by overriding the generated `Clock` class with a build that returns
a fixed `DateTime`, the same way other codegen notifiers are overridden in tests.

### `completedToday` is derived from `routineCompletionsProvider`, not a new query

`routineCompletionsProvider(routineId)` already returns `CompletionLogView`s with a `localDay`
and a `completed` flag, fetched for the detail screen's history dots. The card asks the same
provider and checks whether any entry's `localDay` equals today's local date and `completed` is
true — no new storage method, no new provider.

### Minutes round up, and 0 minutes never displays

`StartsIn(Duration remaining)` holds the raw duration; the card converts it to whole minutes with
`.inSeconds / 60` ceiling-divided, then clamps the display to a minimum of 1. A 40-second remainder
should read "in 1 min", not "in 0 min" — showing zero would claim the routine has already started
when it hasn't.

## Data flow

```
Clock (30s Timer.periodic)
        │  DateTime now
        ▼
_RoutineCard (watches clockProvider, routineStepsProvider, routineCompletionsProvider)
        │  estimate = routineEstimate(steps)
        │  completedToday = any completion today with outcome == completed
        ▼
upcomingState(routine, now: now, estimate: estimate, completedToday: completedToday)
        │  null | StartsIn(remaining) | InProgress
        ▼
TintedCard color/foregroundColor: upcomingFill/onUpcomingFill when non-null, accent otherwise
step-count line: "{count} steps · in {minutes} min" | "{count} steps · Now" | "{count} steps"
```

## Risks / Trade-offs

**The estimate math now exists in two places** (`routine_detail_screen.dart`'s
`_estimatedDuration` and the new `routineEstimate`). Accepted per the brief: the detail screen is
mid-restyle under a parallel change, and touching it here would create a merge conflict neither
change owns. The coordinator switches the detail screen over once both land.

**A 30-second clock tick means a card's "in {minutes} min" text can lag by up to 30 seconds.**
Accepted: the routines list isn't a countdown timer, and re-rendering the whole visible list more
often than that buys nothing a user would notice.

## Migration Plan

None. No persisted data changes shape, and the new clock provider and pure functions are
additive — nothing existing changes behavior except the routine card, which gains a new visual
state it previously couldn't enter.
