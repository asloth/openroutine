## Purpose

Defines the app's top-level destinations and what the Routines destination lists.

## ADDED Requirements

### Requirement: Three top-level destinations

The app SHALL offer Today, Routines, and Streaks, in that order, from a navigation bar that stays on screen and within the screen's width at any supported text scale.

#### Scenario: The bar on a narrow phone

- **GIVEN** a 360dp-wide phone at a 2.0x text scale
- **WHEN** the bar renders
- **THEN** all three destinations are visible and nothing overflows

### Requirement: Routines lists every routine

The Routines destination SHALL list every routine regardless of the day it's due, scheduled routines by start time and then routines with no start time, and SHALL offer a way to add a routine.

#### Scenario: A routine due on another day

- **GIVEN** a routine scheduled only for a day other than today
- **WHEN** the user opens Routines
- **THEN** the routine is listed
