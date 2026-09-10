## Purpose

Defines the routines list screen's presentation as tinted-paper surfaces, replacing the
stock `AppBar`/`TabBar`/neumorphic look with `PageHeader`, `PillSegmentedControl`,
`SectionLabel`, and `TintedCard`, while every control keeps today's action and destination.

## ADDED Requirements

### Requirement: The screen header carries no stock `AppBar`

The routines list SHALL render its title and settings entry point through `PageHeader`
instead of `AppBar`. The title SHALL read the existing app title string. The settings entry
point SHALL be a neutral `SoftCircleButton` with the existing settings tooltip, and SHALL
navigate to `/settings` when pressed, matching today's behavior. The screen SHALL set its own
status-bar icon contrast via `AnnotatedRegion<SystemUiOverlayStyle>` — dark icons in light
theme, light icons in dark theme, and a transparent status bar — since removing the `AppBar`
removes the styling it used to provide.

#### Scenario: The header shows the app title with no AppBar

- **GIVEN** the routines list screen
- **WHEN** it renders
- **THEN** the app title is visible and no `AppBar` widget is present in the tree

#### Scenario: The settings button opens Settings

- **GIVEN** the routines list screen
- **WHEN** the user taps the settings control in the header
- **THEN** the app navigates to `/settings`

### Requirement: Scheduled/Flexible switch through a pill segmented control

The routines list SHALL present the "Scheduled" and "Flexible" tabs through
`PillSegmentedControl` bound to the same `TabController` driving the `TabBarView`, instead of
a `TabBar`. Tapping a segment SHALL switch the visible tab, and swiping the tab content SHALL
move the segmented control to match, matching today's tab-switching behavior.

#### Scenario: Tapping a segment switches tabs

- **GIVEN** the routines list screen showing the Scheduled tab
- **WHEN** the user taps the "Flexible" segment
- **THEN** the Flexible tab's content becomes visible and no `TabBar` widget is present in the
  tree

#### Scenario: Swiping the tab content moves the segmented control

- **GIVEN** the routines list screen showing the Scheduled tab
- **WHEN** the user swipes the tab content to the Flexible page
- **THEN** the segmented control reflects Flexible as selected

### Requirement: Moment group headings use `SectionLabel`

Each moment group heading SHALL render through `SectionLabel` instead of a plain styled
`Text`, following the existing rule for when a heading is shown (suppressed when there is
exactly one, untriggered group).

#### Scenario: A named moment group shows a section label

- **GIVEN** routines grouped under two or more distinct moments
- **WHEN** the list renders
- **THEN** each group's heading renders as a `SectionLabel`

### Requirement: Routine cards are tinted, not neumorphic

Each routine card SHALL render as a `TintedCard` filled with
`context.routineCardColors.fill`/`onFill`, instead of `NeumorphicCard`. The card SHALL keep
its existing content and order: the fixed-width start-time column, the routine name, the step
count, the Low Mode guidance text when shown, and either a chevron or the Low Mode action.
Secondary text (step count, Low Mode guidance) SHALL render at 80% opacity of `onFill`. The
start time SHALL render in `onFill`, following the device's 12/24-hour clock setting exactly
as it does today. Tapping the card SHALL navigate to the routine's detail screen, matching
today's behavior.

#### Scenario: A routine card is filled with the accent

- **GIVEN** a saved routine
- **WHEN** its card renders
- **THEN** the card's fill equals `context.routineCardColors.fill` and its text/icon color
  equals `context.routineCardColors.onFill`

#### Scenario: Tapping a card opens the routine

- **GIVEN** a routine card
- **WHEN** the user taps it
- **THEN** the app navigates to that routine's detail screen

### Requirement: "Start Low Mode" renders as a filled pill

When a routine has core steps, its card SHALL show "Start Low Mode" as a 48px-tall pill
filled with `onFill` at 10% opacity, its label in `onFill`, instead of a `TextButton`. It
SHALL start Low Mode for the routine's core steps when pressed, matching today's behavior.

#### Scenario: Starting Low Mode from a card

- **GIVEN** a routine card with core steps
- **WHEN** the user presses "Start Low Mode"
- **THEN** the app navigates to that routine's Low Mode timer with its core steps

### Requirement: The FAB is a flat circle with no shadow

The screen's floating action button SHALL render as a 56px circle with no elevation or
shadow, filled with the theme's primary color, styled through `floatingActionButtonTheme`
rather than a local override. It SHALL keep its existing tooltip and SHALL navigate to
`/routines/new` when pressed, matching today's behavior.

#### Scenario: The FAB creates a routine

- **GIVEN** the routines list screen
- **WHEN** the user taps the FAB
- **THEN** the app navigates to `/routines/new`

### Requirement: The list clears the FAB and any floating bottom navigation

The routine list's bottom padding SHALL be at least the device's bottom safe-area inset plus
the FAB's clearance, so the last card is never obscured by the FAB or by a floating bottom
navigation bar rendered below the screen's body.

#### Scenario: The last card is not obscured

- **GIVEN** a routine list long enough to reach the bottom of the screen
- **WHEN** it is scrolled to the end
- **THEN** the last card's full content is visible above the FAB

### Requirement: The screen tolerates large text scale

At 1.5x and 2.0x text scale factor, every element on the routines list SHALL remain visible
with no overflow error.

#### Scenario: The screen renders without overflow at 2.0x text scale

- **GIVEN** the routines list screen with at least one routine
- **WHEN** the text scale factor is 2.0
- **THEN** no overflow error is reported
