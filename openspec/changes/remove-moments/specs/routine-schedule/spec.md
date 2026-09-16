## Purpose

Defines how a routine is reached now that moments are gone: through its schedule alone.

## ADDED Requirements

### Requirement: Routines carry no moment

The app SHALL NOT store, show, export, or ask for a moment or trigger on a routine. Files it writes SHALL declare schema version 2.0.0 and SHALL NOT contain `trigger_id` or `triggers`.

#### Scenario: Creating a routine

- **WHEN** the user creates a routine
- **THEN** the form asks for no moment

#### Scenario: Exporting

- **WHEN** the user exports their routines
- **THEN** the file declares 2.0.0 and has no `triggers` list

### Requirement: Older files still import

The app SHALL read files declaring any 1.x schema version, ignoring their moments.

#### Scenario: Importing a 1.2.0 export with moments

- **GIVEN** a 1.2.0 export whose routines reference triggers
- **WHEN** the user imports it
- **THEN** the routines and steps import and no moment appears

### Requirement: Existing installs keep their routines

Upgrading an install that has moments SHALL keep every routine, step, and completion log.

#### Scenario: Upgrading with a linked moment

- **GIVEN** a routine linked to a moment
- **WHEN** the app upgrades
- **THEN** the routine and its steps and history are intact, with no moment

### Requirement: Reminders come from the schedule

A reminder SHALL be scheduled from a routine's days, start time, and the Remind me setting, and its text SHALL name the routine and when it starts.

#### Scenario: A reminder for a routine that had a moment

- **GIVEN** a scheduled routine
- **WHEN** its reminder is built
- **THEN** the body says when it starts and names no moment
