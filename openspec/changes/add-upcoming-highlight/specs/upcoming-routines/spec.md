## Purpose

Defines when a routine counts as "coming up soon" and how its card on the routines list
communicates that, in both color and words.

## ADDED Requirements

### Requirement: A routine is upcoming from 15 minutes before its start until its estimate ends

A scheduled routine with a valid start time on today's weekday SHALL be considered upcoming
from `lead` (15 minutes by default) before its start time until its start time plus its
estimated duration, whichever of "estimate ends" or "already finished today" comes first. A
routine that is flexible, has no valid start time, or isn't scheduled on today's weekday SHALL
NOT be considered upcoming, regardless of the current time.

#### Scenario: Well before the start time

- **GIVEN** a scheduled routine starting in 16 minutes
- **WHEN** its upcoming state is computed with the default 15-minute lead
- **THEN** the result is not upcoming

#### Scenario: Inside the lead window

- **GIVEN** a scheduled routine starting in 15 minutes
- **WHEN** its upcoming state is computed with the default 15-minute lead
- **THEN** the result is "starts in 15 minutes"

#### Scenario: At the start time

- **GIVEN** a scheduled routine whose start time is now, with a nonzero estimated duration
- **WHEN** its upcoming state is computed
- **THEN** the result is "in progress"

#### Scenario: Just before the estimate ends

- **GIVEN** a scheduled routine whose start time plus estimated duration is one second from now
- **WHEN** its upcoming state is computed
- **THEN** the result is "in progress"

#### Scenario: The estimate has ended

- **GIVEN** a scheduled routine whose start time plus estimated duration is exactly now
- **WHEN** its upcoming state is computed
- **THEN** the result is not upcoming

#### Scenario: A zero estimate ends the window at the start time

- **GIVEN** a scheduled routine with a zero estimated duration
- **WHEN** its upcoming state is computed at exactly its start time
- **THEN** the result is not upcoming

#### Scenario: Not scheduled today

- **GIVEN** a scheduled routine whose days don't include today's weekday
- **WHEN** its upcoming state is computed
- **THEN** the result is not upcoming

#### Scenario: A flexible routine is never upcoming

- **GIVEN** a routine in flexible mode
- **WHEN** its upcoming state is computed
- **THEN** the result is not upcoming

#### Scenario: A missing or malformed start time is never upcoming

- **GIVEN** a scheduled routine whose start time is missing or fails to parse
- **WHEN** its upcoming state is computed
- **THEN** the result is not upcoming

#### Scenario: A window that crosses midnight

- **GIVEN** a scheduled routine starting at 22:50 with a 30-minute estimate
- **WHEN** its upcoming state is computed at 23:10 the same day
- **THEN** the result is "in progress"

#### Scenario: Past midnight, on a day the routine isn't scheduled

- **GIVEN** the same routine from the previous scenario, scheduled only on the day that has now
  ended
- **WHEN** its upcoming state is computed at 00:05 the next day
- **THEN** the result is not upcoming

### Requirement: Finishing a routine today ends its upcoming state early

A routine already completed today SHALL NOT be considered upcoming, even if the current time
still falls inside its lead-to-estimate window.

#### Scenario: Completed today, still inside the window

- **GIVEN** a scheduled routine completed earlier today, with the current time inside its
  lead-to-estimate window
- **WHEN** its upcoming state is computed
- **THEN** the result is not upcoming

### Requirement: A routine's estimated duration sums its timed steps

A routine's estimated duration SHALL be the sum of `durationSeconds` over its steps whose
`noExplicitTime` is `false`. Steps with `noExplicitTime` set to `true`, a `null` duration, or an
empty step list SHALL contribute zero.

#### Scenario: A step with no explicit time is excluded

- **GIVEN** a routine with one 60-second timed step and one step marked `noExplicitTime`
- **WHEN** its estimated duration is computed
- **THEN** the result is 60 seconds

#### Scenario: No steps

- **GIVEN** a routine with no steps
- **WHEN** its estimated duration is computed
- **THEN** the result is zero

### Requirement: An upcoming card is filled with the fixed upcoming color

A routine card in an upcoming state SHALL use `context.routineCardColors.upcomingFill` as its
fill and `context.routineCardColors.onUpcomingFill` as its foreground, instead of the accent.
A card that is not upcoming SHALL keep using the accent
(`context.routineCardColors.fill`/`onFill`), unchanged from today.

#### Scenario: An upcoming card is green

- **GIVEN** a routine card in an upcoming state
- **WHEN** it renders
- **THEN** its fill equals `context.routineCardColors.upcomingFill` and its foreground equals
  `context.routineCardColors.onUpcomingFill`

#### Scenario: A non-upcoming card keeps the accent

- **GIVEN** a routine card that is not in an upcoming state
- **WHEN** it renders
- **THEN** its fill equals `context.routineCardColors.fill` and its foreground equals
  `context.routineCardColors.onFill`

### Requirement: The card says its upcoming state in words, not only in color

When a routine card is counting down to its start, its step-count line SHALL append "in
{minutes} min", where minutes is the remaining time rounded up to the next whole minute, with a
minimum of 1. When a routine card has started and is still inside its window, its step-count
line SHALL append "Now" instead. A screen reader SHALL be able to hear the same state through a
semantics hint on the card.

#### Scenario: Counting down

- **GIVEN** a routine card 10 minutes and 20 seconds from its start
- **WHEN** it renders
- **THEN** its step-count line reads "{n} steps · in 11 min"

#### Scenario: Under a minute never shows zero

- **GIVEN** a routine card 40 seconds from its start
- **WHEN** it renders
- **THEN** its step-count line reads "{n} steps · in 1 min"

#### Scenario: In progress

- **GIVEN** a routine card whose routine has started and is still inside its window
- **WHEN** it renders
- **THEN** its step-count line reads "{n} steps · Now"
