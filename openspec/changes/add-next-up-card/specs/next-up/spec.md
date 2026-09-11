## Purpose

Defines which routine, if any, counts as "next up" today, and how the Scheduled tab's hero card
presents and behaves.

## ADDED Requirements

### Requirement: The next-up routine is the earliest-starting scheduled routine whose window hasn't ended

Among routines in scheduled mode, whose days include today's weekday, and whose start time
parses, the one SHALL be "next up" whose window — from its start time until its start time plus
its estimated duration — has not yet ended, and that has not already been completed today, with
the earliest start time breaking any tie among qualifying routines. A routine already in
progress (started, not yet past its estimate) SHALL still qualify, and SHALL outrank a routine
that starts later. When no routine qualifies, there SHALL be no next-up routine. Only today's
occurrence is considered; a routine's tomorrow is never checked.

#### Scenario: Earliest remaining routine wins

- **GIVEN** two scheduled routines today, one starting later than the other, both still ahead
  of their windows ending
- **WHEN** the next-up routine is computed
- **THEN** the earlier-starting routine is selected

#### Scenario: A routine whose window already ended is skipped

- **GIVEN** a scheduled routine whose start time plus estimated duration is in the past
- **WHEN** the next-up routine is computed
- **THEN** that routine is not selected

#### Scenario: A routine completed today is skipped

- **GIVEN** a scheduled routine already completed today, still inside its window
- **WHEN** the next-up routine is computed
- **THEN** that routine is not selected

#### Scenario: A routine not scheduled today is skipped

- **GIVEN** a routine whose days don't include today's weekday
- **WHEN** the next-up routine is computed
- **THEN** that routine is not selected

#### Scenario: A flexible routine is skipped

- **GIVEN** a routine in flexible mode
- **WHEN** the next-up routine is computed
- **THEN** that routine is not selected

#### Scenario: A missing or malformed start time is skipped

- **GIVEN** a scheduled routine whose start time is missing or fails to parse
- **WHEN** the next-up routine is computed
- **THEN** that routine is not selected

#### Scenario: Nothing qualifies

- **GIVEN** a set of routines where every one is flexible, not scheduled today, already
  finished, or already completed today
- **WHEN** the next-up routine is computed
- **THEN** there is no next-up routine

#### Scenario: An in-progress routine outranks a later one

- **GIVEN** one scheduled routine already started and still inside its estimated window, and
  another scheduled routine starting later the same day
- **WHEN** the next-up routine is computed
- **THEN** the in-progress routine is selected

### Requirement: The next-up card appears only on the Scheduled tab, above the moment groups

The Scheduled tab SHALL show the next-up routine's card, when one exists, above its moment
groups. The Flexible tab SHALL never show this card, regardless of what routines it contains.
The selected routine SHALL still appear in its own moment group below, unchanged.

#### Scenario: The card appears above the moment groups

- **GIVEN** a next-up routine exists on the Scheduled tab
- **WHEN** the tab renders
- **THEN** the hero card appears before the first moment group, and the same routine also
  appears in its moment group

#### Scenario: No card on the Flexible tab

- **GIVEN** the Flexible tab, which has no start times to rank routines by
- **WHEN** the tab renders
- **THEN** no next-up card appears

#### Scenario: No card when nothing qualifies

- **GIVEN** the Scheduled tab where no routine qualifies as next up
- **WHEN** the tab renders
- **THEN** no next-up card appears

### Requirement: The card's fill follows the same upcoming state as a list card

The next-up card SHALL fill with `context.routineCardColors.upcomingFill`/`onUpcomingFill` when
`upcomingState(...)` reports the routine as coming up, and with
`context.routineCardColors.fill`/`onFill` otherwise — the same rule the routine's own list card
already follows.

#### Scenario: Green when upcoming

- **GIVEN** the next-up routine is inside its upcoming window
- **WHEN** its hero card renders
- **THEN** the card's fill is `upcomingFill` and its foreground is `onUpcomingFill`

#### Scenario: Accent otherwise

- **GIVEN** the next-up routine is not inside its upcoming window
- **WHEN** its hero card renders
- **THEN** the card's fill is `fill` and its foreground is `onFill`

### Requirement: The card shows the moment, time, name, steps, and a Start Timer action

The card SHALL show, top to bottom: a row with the routine's moment name (or the existing "no
moment" fallback) plus the upcoming label when present, and the start time on the right,
following the device's 12/24-hour setting; the routine's name; up to five step emoji in order,
when the routine has any steps; and a row with the step count and estimate (the estimate omitted
when no step has a timed duration) plus a "Start Timer" pill, hidden when the routine has no
steps. Pressing "Start Timer" SHALL navigate to the routine's timer route. Pressing anywhere
else on the card SHALL navigate to the routine's detail screen.

#### Scenario: Moment, time, and name render

- **GIVEN** a next-up routine with a trigger and a start time
- **WHEN** its hero card renders
- **THEN** the trigger's name, the formatted start time, and the routine's name are all visible

#### Scenario: No moment falls back

- **GIVEN** a next-up routine with no trigger
- **WHEN** its hero card renders
- **THEN** the existing "no moment" text is shown in place of a trigger name

#### Scenario: Step emoji appear in order, capped at five

- **GIVEN** a next-up routine with seven steps
- **WHEN** its hero card renders
- **THEN** the first five step emoji, in step order, are visible and the rest are not

#### Scenario: No steps hides both the emoji row and Start Timer

- **GIVEN** a next-up routine with no steps
- **WHEN** its hero card renders
- **THEN** neither an emoji row nor a "Start Timer" pill is shown

#### Scenario: No timed steps omits the estimate

- **GIVEN** a next-up routine whose steps are all marked with no explicit time
- **WHEN** its hero card renders
- **THEN** only the step count is shown, with no estimate text

#### Scenario: Start Timer opens the timer

- **GIVEN** a next-up routine with at least one step
- **WHEN** the user presses "Start Timer"
- **THEN** the app navigates to that routine's timer route

#### Scenario: Tapping the card elsewhere opens the routine

- **GIVEN** a next-up routine's hero card
- **WHEN** the user taps the card outside the "Start Timer" pill
- **THEN** the app navigates to that routine's detail screen

### Requirement: The card exposes one semantics summary

The card SHALL expose a single semantics node summarizing the routine's name, moment, and start
time, including the upcoming label when present, so a screen reader announces the same
information sighted users see.

#### Scenario: A screen reader hears the summary

- **GIVEN** a next-up routine's hero card
- **WHEN** a screen reader reaches it
- **THEN** it announces the routine's name, moment, and start time as one summary
