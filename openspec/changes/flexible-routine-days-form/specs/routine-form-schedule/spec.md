## Purpose

Defines what the Create/Edit routine form requires and persists for each schedule mode. The
capability exists because "flexible" describes when a routine runs, not whether it belongs to any
day at all — a routine still needs its days regardless of mode, and only a fixed clock time is
mode-specific.

## ADDED Requirements

### Requirement: A routine has days regardless of schedule mode

The Create/Edit routine form SHALL let the user choose days in both Scheduled and Flexible mode, and
SHALL require at least one day be chosen before saving, in either mode.

#### Scenario: Flexible mode shows the day chips

- **WHEN** the user selects Flexible mode on the routine form
- **THEN** the day chips remain visible and selectable

#### Scenario: Saving Flexible with no days is rejected

- **GIVEN** the user is on Flexible mode with no days selected
- **WHEN** the user saves
- **THEN** the form shows the days-required error and does not save

#### Scenario: Saving Flexible with days selected persists them

- **GIVEN** the user is on Flexible mode with at least one day selected
- **WHEN** the user saves
- **THEN** the routine is saved with mode Flexible and exactly the days selected

#### Scenario: Switching an existing routine to Flexible keeps its days

- **GIVEN** an existing Scheduled routine with days already set
- **WHEN** the user switches it to Flexible and saves
- **THEN** the saved routine keeps those same days

### Requirement: Only Scheduled mode asks for a start time

The Create/Edit routine form SHALL show and require a start time only in Scheduled mode. Flexible
mode SHALL NOT show a start-time control, and SHALL always save a null start time.

#### Scenario: Flexible mode hides the start-time row

- **WHEN** the user selects Flexible mode on the routine form
- **THEN** the start-time row is not shown

#### Scenario: Saving Flexible never sets a start time

- **GIVEN** the user is on Flexible mode
- **WHEN** the user saves
- **THEN** the saved routine's start time is null, regardless of any start time entered earlier in
  the same editing session
