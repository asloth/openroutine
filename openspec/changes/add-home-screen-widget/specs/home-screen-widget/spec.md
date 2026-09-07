# Home Screen Widget Specification

## Purpose

Define an Android launcher surface that lists the user's routines and starts one in Timer Mode in a single tap, without duplicating the storage contract outside Dart and without changing any persisted or public schema.

## ADDED Requirements

### Requirement: Routine list on the home screen

The system MUST offer an Android app widget that lists the user's active routines. Each row MUST show the routine's name and its step count, and MUST show the routine's start time when the routine has one. Rows MUST be ordered scheduled routines first by ascending start time, then flexible routines by name, matching the in-app list. The widget MUST be resizable and MUST scroll when it holds more rows than fit.

#### Scenario: Widget lists the routines

- GIVEN a user with one scheduled routine at `07:30` with seven steps and one flexible routine with three steps
- WHEN the widget is placed on the home screen
- THEN it MUST show the scheduled routine first with its start time, name and step count
- AND it MUST show the flexible routine below it without a start time

#### Scenario: More routines than fit

- GIVEN a widget sized shorter than the number of routines
- WHEN the user scrolls the widget
- THEN the remaining rows MUST be reachable

#### Scenario: Deleted routines are absent

- GIVEN a routine that has been deleted
- WHEN the widget renders
- THEN that routine MUST NOT appear

### Requirement: Start times follow the device clock setting

The widget MUST render start times according to the device's 12/24-hour setting rather than a formatting choice frozen when the data was published.

#### Scenario: Device switches to 12-hour time

- GIVEN a routine whose stored start time is `19:30`
- WHEN the device is set to 12-hour time
- THEN the widget MUST render that start time in 12-hour form

### Requirement: One tap starts the routine

Tapping a routine row MUST open the app at that routine's Timer Mode, which starts the run. This MUST hold whether the app is closed or already running. When onboarding is incomplete, the app's existing onboarding redirect MUST still take precedence.

#### Scenario: Tap with the app closed

- GIVEN the app is not running
- WHEN the user taps a routine row
- THEN the app MUST open at that routine's Timer Mode with the run started

#### Scenario: Tap with the app already open

- GIVEN the app is running and showing another screen
- WHEN the user taps a routine row
- THEN the app MUST navigate to that routine's Timer Mode with the run started

#### Scenario: Tap before onboarding is complete

- GIVEN onboarding has not been completed
- WHEN the user taps a routine row
- THEN the app MUST show onboarding rather than Timer Mode

### Requirement: The widget reflects routine changes

The system MUST refresh the widget whenever the routine list changes, including creation, rename, deletion, reordering, and a sync that pulls another device's change. The user MUST NOT have to refresh the widget manually, and the widget MUST NOT poll on a timer.

#### Scenario: A routine is renamed

- GIVEN a widget showing a routine named `Morning`
- WHEN the user renames it to `Mañana` in the app
- THEN the widget MUST show the new name without further user action

### Requirement: Empty and unavailable states

When no routine data is available — no routines exist, or the app has never run since the widget was placed — the widget MUST render an intelligible empty state rather than an error or a blank surface, and tapping it MUST open the app. Malformed stored data MUST be treated as no data.

#### Scenario: Widget placed before first launch

- GIVEN the app has never been opened since install
- WHEN the widget is placed on the home screen
- THEN it MUST show its empty state
- AND tapping it MUST open the app

### Requirement: Localized and themed presentation

Widget copy MUST come from the app's existing localization resources, so English and Spanish stay in step with the rest of the app. The widget MUST render legibly in both light and dark system themes using the app's palette.

#### Scenario: Spanish device

- GIVEN a device set to Spanish
- WHEN the widget renders its empty state
- THEN the copy MUST be the Spanish string from the app's localization resources

#### Scenario: Dark mode

- GIVEN the device is in dark mode
- WHEN the widget renders
- THEN it MUST use the dark palette with legible contrast

### Requirement: The widget does not read the database

The widget MUST NOT read or write the app's database directly. The app MUST publish a versioned snapshot of the routine list that the widget renders. That snapshot is internal and MUST NOT be added to `schemas/`, which is the public agent contract.

#### Scenario: Storage schema is untouched

- GIVEN the widget is implemented
- WHEN the storage schema and `schemas/` are inspected
- THEN they MUST be unchanged
- AND no migration MUST be required
