## Purpose

Defines what onboarding shows, what the mascot does on each beat, and where onboarding hands off.

## ADDED Requirements

### Requirement: Onboarding tells the routine story in five beats

Onboarding SHALL show five beats in order: a hello, scheduled routines, flexible routines, going step by step with skipping, and making your first routine. A progress bar SHALL show five segments, with the current beat and those before it filled. Skip SHALL be available on every beat and SHALL complete onboarding and open Today.

#### Scenario: A fresh install

- **WHEN** a fresh install opens
- **THEN** it shows "Routines that stick, without the setup." and Get started

#### Scenario: Moving through the story

- **WHEN** the user selects Get started, then Next twice more
- **THEN** onboarding shows the scheduled beat, then the flexible beat, then the skip beat

#### Scenario: Skipping

- **WHEN** the user selects Skip on any beat
- **THEN** onboarding is marked complete and Today opens

### Requirement: The mascot acts out each beat

The mascot SHALL wave on the hello beat, run in and then jump on the scheduled beat, bounce on the flexible beat, cheer and then nod on the skip beat, and celebrate on the last beat.

#### Scenario: The scheduled beat

- **WHEN** the scheduled beat has played through
- **THEN** the mascot has run in and its last move is a jump

#### Scenario: The skip beat

- **WHEN** the skip beat has played through
- **THEN** the demo shows one step done and one skipped, and the mascot's last move is a nod

### Requirement: Onboarding ends in the routine builder

The last beat SHALL offer a scheduled routine and a flexible routine. Choosing one SHALL complete onboarding and open the routine builder with that schedule selected, on top of Today. Onboarding SHALL NOT ask where routines are stored.

#### Scenario: Choosing a scheduled routine

- **WHEN** the user selects the scheduled option
- **THEN** the routine builder opens with Scheduled selected, and going back shows Today
