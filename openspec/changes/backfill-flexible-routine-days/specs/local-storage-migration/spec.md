## Purpose

Defines what a Drift schema upgrade must do to the data already on a device, as distinct from the
column-level shape a schema change adds — the difference between "the table now has this column"
and "existing rows now hold the right value in it." The capability exists because a schema bump
that only changes shape can still leave existing installs holding data that used to be valid and
silently stops being once another change starts relying on it.

## ADDED Requirements

### Requirement: Flexible routines with no scheduled days are backfilled to every day

When the local database upgrades past schema version 7, every routine whose schedule mode is
`flexible` and whose stored day list is empty SHALL have its day list set to all seven days. The
routine's other fields SHALL be unchanged, and no other routine SHALL be modified by this upgrade.

#### Scenario: A flexible routine has no scheduled days

- **GIVEN** a routine with schedule mode `flexible` and an empty day list
- **WHEN** the database upgrades to schema version 8
- **THEN** the routine's day list contains all seven days

#### Scenario: A flexible routine already has scheduled days

- **GIVEN** a routine with schedule mode `flexible` and a non-empty day list
- **WHEN** the database upgrades to schema version 8
- **THEN** the routine's day list is unchanged

#### Scenario: A scheduled routine has no scheduled days

- **GIVEN** a routine with schedule mode `scheduled` and an empty day list
- **WHEN** the database upgrades to schema version 8
- **THEN** the routine's day list remains empty

#### Scenario: Other data is undisturbed

- **GIVEN** a database with routines, steps, and completion logs
- **WHEN** the database upgrades to schema version 8
- **THEN** every column other than a backfilled routine's day list, and every other table, holds
  the same values it held before the upgrade
