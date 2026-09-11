## Purpose

Defines how the routine form seeds and displays a Scheduled routine's start time, and what it
requires before a Scheduled routine can save — plus where the low-mode setup guidance a routine
without an essential step needs actually belongs. The capability exists because a form that ignores
a routine's own stored state, or lets a Scheduled routine save with no way to ever trigger, reads as
broken somewhere else entirely by the time anyone notices.

## ADDED Requirements

### Requirement: The time picker opens at the routine's stored start time

When a Scheduled routine being edited already has a start time, opening the time picker SHALL seed
it with that stored time rather than the current time.

#### Scenario: Editing a routine with a stored start time

- **GIVEN** a Scheduled routine with a stored start time of 07:30
- **WHEN** the start-time tile is tapped
- **THEN** the time picker opens with 7:30 selected

#### Scenario: No start time is stored yet

- **GIVEN** a Scheduled routine with no stored start time
- **WHEN** the start-time tile is tapped
- **THEN** the time picker opens at the current time

### Requirement: The start-time tile follows the phone's clock format

The start-time tile SHALL display a stored start time formatted for the phone's 12-hour or 24-hour
setting, matching how the routines list displays the same value. The value stored on the routine's
schedule SHALL NOT change format because of this display.

#### Scenario: A 12-hour phone

- **GIVEN** a Scheduled routine with a stored start time of 07:30
- **AND** the phone is set to a 12-hour clock
- **WHEN** the routine form is shown
- **THEN** the start-time tile reads "7:30 AM"

#### Scenario: A 24-hour phone

- **GIVEN** a Scheduled routine with a stored start time of 07:30
- **AND** the phone is set to a 24-hour clock
- **WHEN** the routine form is shown
- **THEN** the start-time tile reads "07:30"

### Requirement: A Scheduled routine requires at least one day and a start time to save

Saving a routine in Scheduled mode SHALL require at least one day selected and a start time set.
Saving with either missing SHALL be blocked, and SHALL show an inline error under the control for
the missing field. Each error SHALL clear once its own field is fixed, independently of the other.
Flexible mode SHALL be unaffected by this requirement.

#### Scenario: No day selected

- **GIVEN** the routine form is in Scheduled mode with a start time set but no day selected
- **WHEN** the routine is saved
- **THEN** the save is blocked
- **AND** an inline error reading "Pick at least one day" appears under the day chips

#### Scenario: No start time set

- **GIVEN** the routine form is in Scheduled mode with a day selected but no start time set
- **WHEN** the routine is saved
- **THEN** the save is blocked
- **AND** an inline error reading "Pick a start time" appears under the start-time tile

#### Scenario: Fixing the missing field clears its error

- **GIVEN** a blocked save has shown the missing-day error
- **WHEN** a day is selected
- **THEN** the missing-day error clears

#### Scenario: Flexible mode is unaffected

- **GIVEN** the routine form is in Flexible mode with no day selected and no start time set
- **WHEN** the routine is saved
- **THEN** the save succeeds

### Requirement: Low-mode setup guidance appears on Routine detail, not the routines list

A routine card on the routines list SHALL NOT show setup guidance for making Low Mode available.
Routine detail SHALL show that guidance directly under the Steps header, and only when the routine
has at least one step and none of them is marked essential.

#### Scenario: A routine list card with no essential step

- **GIVEN** a routine with steps but none marked essential
- **WHEN** its card renders on the routines list
- **THEN** the card shows its step count and a chevron, with no setup guidance

#### Scenario: Routine detail with steps and none essential

- **GIVEN** a routine with at least one step and none of them marked essential
- **WHEN** Routine detail is shown
- **THEN** the setup guidance appears directly under the Steps header

#### Scenario: Routine detail with an essential step

- **GIVEN** a routine with at least one step marked essential
- **WHEN** Routine detail is shown
- **THEN** the setup guidance does not appear

#### Scenario: Routine detail with no steps

- **GIVEN** a routine with no steps
- **WHEN** Routine detail is shown
- **THEN** the setup guidance does not appear
