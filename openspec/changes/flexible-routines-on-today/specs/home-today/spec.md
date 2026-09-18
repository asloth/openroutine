## MODIFIED Requirements

### Requirement: Today's routines are laid out by time

Home SHALL list flexible routines under Anytime today, each startable directly, and SHALL list
routines scheduled for today on a timeline sorted by start time, each showing today's progress.
Scheduled routines not due today SHALL remain reachable under Other days.

A flexible routine SHALL appear under Anytime today only on the days it's scheduled for. A flexible
routine with no days set SHALL still appear, so a routine that hasn't been given days yet — including
one pulled down by a Drive sync from another device, or one that predates a local database migration
— doesn't silently disappear from Today.

Anytime today's rows SHALL share the timeline's rail: the same fixed-width time column, kept empty
rather than removed since a flexible routine has no start time, and the same line-and-dot column at
the same horizontal position, so the two sections read as one continuous list rather than two
unrelated layouts.

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

#### Scenario: A flexible routine is due today

- **GIVEN** a flexible routine scheduled for today
- **WHEN** home opens
- **THEN** it appears under Anytime today

#### Scenario: A flexible routine is due only on another day

- **GIVEN** a flexible routine scheduled only for a day other than today
- **WHEN** home opens
- **THEN** it doesn't appear under Anytime today

#### Scenario: A flexible routine has no days set

- **GIVEN** a flexible routine with no days stored
- **WHEN** home opens
- **THEN** it still appears under Anytime today

#### Scenario: Anytime today shares the timeline's rail

- **GIVEN** at least one flexible routine due today and one routine scheduled for today
- **WHEN** home opens
- **THEN** the Anytime row's rail dot lines up on the same horizontal position as the timeline row's
  rail dot
