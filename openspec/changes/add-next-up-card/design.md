## Context

See `proposal.md` — Why. `restyle-routines-list` gave the routines list its `TintedCard` surfaces
and moment groups; `add-upcoming-highlight` added `upcomingState(...)`, the shared `clockProvider`,
and `routineEstimate(...)` that decide when a card turns green. This change adds a second,
independent read of the same routines: not "is this one coming up," but "which one is next," and
puts that answer in a hero card above the existing groups.

## Goals / Non-Goals

**Goals:**

- A pure, tested function, `nextUpRoutine(...)`, that picks the single routine most worth
  showing right now, given `now` and per-routine estimate/completed-today lookups — the same
  shape `upcomingState` already uses, so a fake clock is enough to test it.
- Reuse `upcomingState`, `routineEstimate`, `routinesUpcomingIn`/`routinesUpcomingNow`,
  `routinesStepCount`, and `routineDetailEstimateMinutes`/`routineDetailStartTimer` rather than
  re-deriving any of that math or copying those strings.
- Keep the change additive: the routine picked still renders in its moment group exactly as
  before, and every other control on the screen keeps its current behavior.

**Non-Goals:**

- Reworking `upcoming.dart` or the list card. This change only adds a second, separate read of
  the same routines and colors the new card the same two ways the list card already can be.
- A Flexible-tab equivalent. Flexible routines have no start time, so there's no "earliest" to
  rank them by; the brief scopes this card to Scheduled only.
- A new spacing token or color role. The hero card reuses `AppRadius.hero`,
  `context.routineCardColors`, and literals already established by the two changes this builds
  on.

## Decisions

### `nextUpRoutine` takes `now` and two lookups, not providers — same shape as `upcomingState`

`app/lib/services/routines/next_up.dart` has no import of Riverpod, Drift, or anything
stateful. It takes the candidate `routines`, `now`, and an `estimateFor`/`completedTodayFor`
pair of callbacks, exactly the parameters `upcomingState` already needs per-routine. The screen
is the only caller that assembles those from `routineStepsProvider` and
`routineCompletionsProvider`. This keeps the selection deterministic and directly testable with
a fixed clock, with no fake provider harness.

### A window is "hasn't ended," not "coming up soon"

`nextUpRoutine` doesn't reuse `upcomingState`'s 15-minute lead — a routine two hours away is
still the next thing on the list even though it isn't "coming up soon" yet by that function's
rule. Instead, a scheduled routine with a valid start time on today's weekday qualifies whenever
`now` is before `start + estimate` (its window hasn't ended) and it isn't completed today. Among
qualifying routines, the earliest `start` wins — which means a routine already in progress
(`now` past `start` but still before `start + estimate`) still outranks one that hasn't started,
because its `start` is earlier. No occurrence besides today's is considered: the brief is
explicit that this card never looks at tomorrow, so unlike `upcomingState` there's no ±1-day
occurrence search for a window crossing midnight.

### The hero card is its own private widget in the screen file

`_NextUpCard` sits in `routines_list_screen.dart`, next to `_RoutineCard`, rather than a new
file — it's small, it only exists on this screen, and splitting it out would add an import for
no reuse. It takes the already-selected `Routine` plus the same steps/estimate/completedToday
values `_RoutineCard` computes for that routine, so the two widgets agree without either
recomputing the other's inputs. It reuses `_LowModePill`'s pattern (a `TintedCard`'s foreground
color driving an inner filled pill) for "Start Timer," but inverted: the pill's fill is the
card's foreground and its label is the card's fill color, per the mockup.

### The Scheduled tab computes `nextUpRoutine` once, in `_RoutineSectionList`

`_RoutineSectionList` already receives the tab's routine list and is the natural place to also
watch `clockProvider` and, for each routine, `routineStepsProvider`/`routineCompletionsProvider`
— the same providers `_RoutineCard` already watches per card. A new `isScheduledTab` flag (only
`true` for the Scheduled tab's instance) gates both the computation and the card, so the
Flexible tab's identical widget never runs it.

## Data flow

```
_RoutineSectionList (Scheduled tab only)
        │  routines, clockProvider, routineStepsProvider × n, routineCompletionsProvider × n
        ▼
nextUpRoutine(routines, now: now, estimateFor: ..., completedTodayFor: ...)
        │  Routine? winner
        ▼
_NextUpCard(routine: winner, steps, estimate, completedToday)
        │  upcomingState(...) again, for color/label only
        ▼
TintedCard: upcomingFill/onUpcomingFill when non-null, fill/onFill otherwise
```

## Risks / Trade-offs

**`upcomingState` runs twice for the winning routine** — once inside `_NextUpCard` for its own
color/label, and again inside that routine's `_RoutineCard` in its moment group. Accepted: it's
a pure function over values already in hand, and keeping the hero card self-contained (it only
needs a `Routine` plus the same three inputs `_RoutineCard` needs) is simpler than threading a
precomputed `UpcomingState?` through an extra parameter.

**`_RoutineSectionList` now watches more providers than it used to.** Accepted: it already
receives the full routine list for the tab, and computing "next up" needs the same
steps/completions data every visible `_RoutineCard` already fetches for itself — nothing new is
queried that wasn't already being read somewhere on the same frame.

## Migration Plan

None. No persisted data changes shape, and the new card is additive: nothing existing changes
behavior except gaining a new sibling above it on the Scheduled tab.
