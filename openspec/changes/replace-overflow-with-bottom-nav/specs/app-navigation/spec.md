## Purpose

Defines how a user reaches OpenRoutine's top-level destinations, which parts of the app qualify as destinations rather than actions, and what happens to a destination's state when it is left and returned to. The capability exists because a screen reachable only through an anonymous menu is a screen most users never open: discoverability is a property of the navigation, not of the screen behind it.

## ADDED Requirements

### Requirement: Top-level destinations are visible without opening a menu

The app SHALL present its top-level destinations in a persistently visible bar. A destination SHALL NOT be reachable only through a menu that must be opened to reveal its contents.

Routines and Statistics SHALL both be top-level destinations.

#### Scenario: The app is opened

- **WHEN** the app opens on the routine list
- **THEN** a bar naming both Routines and Statistics is visible without any further interaction

#### Scenario: Statistics is reached

- **WHEN** the user selects Statistics in the bar
- **THEN** the statistics screen is shown

#### Scenario: No overflow menu remains

- **WHEN** the routine list is shown
- **THEN** there is no overflow menu on it

### Requirement: A destination keeps its state while another is visited

Each top-level destination SHALL retain its own navigation stack and scroll position while a different destination is shown. Returning to a destination SHALL restore what was there rather than rebuilding it from its starting state.

#### Scenario: Returning to the routine list

- **GIVEN** the routine list is showing its Flexible tab
- **WHEN** the user selects Statistics and then selects Routines again
- **THEN** the Flexible tab is still the one showing

### Requirement: Actions are placed with their purpose, not among destinations

A screen the user completes and leaves SHALL NOT occupy a slot in the destination bar. Such a screen SHALL be reached from the context its purpose belongs to, and SHALL be presented over the bar rather than beside it.

Importing a file SHALL be reached from the data controls in Settings, alongside exporting.

#### Scenario: Import is reached

- **WHEN** the user opens Settings and selects the import control in the data section
- **THEN** the import screen is shown

#### Scenario: Import is not a destination

- **WHEN** the destination bar is shown
- **THEN** it does not name Import

### Requirement: Settings is reachable in one step from the routine list

Settings SHALL be reachable from the routine list with a single interaction, without occupying a slot in the destination bar.

#### Scenario: Settings is opened

- **WHEN** the user selects the settings control on the routine list
- **THEN** the settings screen is shown

### Requirement: Existing entry points into a routine keep working

Routes that open a specific routine SHALL continue to resolve unchanged. Introducing the destination bar SHALL NOT alter how a notification tap or a home screen widget tap reaches its routine.

#### Scenario: A home screen widget tap

- **WHEN** the app is launched by a widget tap naming a routine
- **THEN** that routine's timer is shown

#### Scenario: A reminder notification tap

- **WHEN** a routine reminder is tapped
- **THEN** that routine is shown
