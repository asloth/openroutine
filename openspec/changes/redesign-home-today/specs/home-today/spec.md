## Purpose

Defines what the home screen shows for the current day, and how each routine on it can be started or reached.

## ADDED Requirements

### Requirement: Home greets the day

Home SHALL show today's date and a greeting that matches the time of day. It SHALL show the current streak, which opens Statistics, and a way into Settings.

#### Scenario: Morning

- **WHEN** home opens before noon
- **THEN** it shows today's date and a morning greeting

#### Scenario: Streak pill

- **WHEN** the user selects the streak pill
- **THEN** Statistics opens

### Requirement: The mascot nudges the next routine

When a scheduled routine is about to start or is under way, home SHALL show a nudge card with the mascot, when the routine starts, and a Start action that opens its timer. With nothing upcoming, the card SHALL NOT appear.

#### Scenario: A routine starts soon

- **GIVEN** a routine scheduled to start in 12 minutes
- **WHEN** home opens
- **THEN** the nudge card says it starts in 12 minutes
- **AND** Start opens that routine's timer

#### Scenario: Nothing upcoming

- **WHEN** no scheduled routine is upcoming
- **THEN** no nudge card appears

### Requirement: Today's routines are laid out by time

Home SHALL list flexible routines under Anytime today, each startable directly. It SHALL list routines scheduled for today on a timeline sorted by start time, each showing today's progress. Scheduled routines not due today SHALL remain reachable under Other days.

#### Scenario: A run was stopped partway

- **GIVEN** a three-step routine whose run today was stopped after two steps
- **WHEN** home opens
- **THEN** its card shows 2 of 3

#### Scenario: A run finished today

- **GIVEN** a routine completed today
- **WHEN** home opens
- **THEN** its card shows Done

#### Scenario: Not due today

- **GIVEN** a routine scheduled only on days other than today
- **WHEN** home opens
- **THEN** it doesn't appear on the timeline
- **AND** it appears under Other days
