## Purpose

Defines the routine detail screen's structure and behavior after it moves from the neumorphic idiom
to tinted-paper surfaces: header controls, the summary card and history dots, and the step list.
Every requirement here either restates an existing behavior that must survive the restyle unchanged,
or describes the new surface treatment replacing it.

## ADDED Requirements

### Requirement: The screen renders with no `AppBar`

The routine detail screen SHALL NOT render a `Scaffold.appBar` or any `AppBar` widget. It SHALL wrap
its content in `SafeArea(bottom: false)` and set the platform status-bar icon contrast through an
`AnnotatedRegion<SystemUiOverlayStyle>` — dark icons on a light theme, light icons on a dark theme,
with a transparent status-bar background.

#### Scenario: No `AppBar` is present

- **GIVEN** the routine detail screen is showing
- **WHEN** its widget tree is inspected
- **THEN** no `AppBar` widget is found

### Requirement: A 48px header row carries Back, Share, Edit, and More

The screen SHALL render a 48px-tall row holding a neutral `SoftCircleButton` labeled with the
platform's back-button tooltip on the left, and three neutral `SoftCircleButton`s — Share, Edit, and
More — spaced 8px apart on the right, in that order. Back SHALL pop the current route. Share SHALL
invoke the same export action the screen invokes today. Edit SHALL navigate to the routine's edit
route. More SHALL open a menu offering Delete; selecting Delete SHALL show the same confirmation
dialog the screen shows today, and SHALL delete the routine and pop the screen only on confirmation.

#### Scenario: Back pops the current route

- **GIVEN** the routine detail screen was reached by pushing over another route
- **WHEN** the user selects the Back control
- **THEN** the previous route is shown

#### Scenario: Edit navigates to the edit route

- **GIVEN** the routine detail screen is showing
- **WHEN** the user selects Edit
- **THEN** the app navigates to that routine's edit route

#### Scenario: More still confirms before deleting

- **GIVEN** the routine detail screen is showing
- **WHEN** the user selects More, then Delete, then confirms the dialog
- **THEN** the routine is deleted and the screen pops
- **AND WHEN** the user selects More, then Delete, then cancels the dialog
- **THEN** the routine is not deleted and the screen stays open

### Requirement: The moment chip and summary card read the accent color

The moment name SHALL render as a small pill-shaped chip filled with
`context.routineCardColors.fill`, with text colored `context.routineCardColors.onFill`. When the
routine has no assigned moment, the chip SHALL show the existing "no moment" fallback text. The
estimated-time-and-history summary SHALL render as a single `TintedCard` filled with
`context.routineCardColors.fill`, with its text and dots colored
`context.routineCardColors.onFill`.

#### Scenario: The chip and card use the accent fill

- **GIVEN** an accent color other than the app's default
- **WHEN** the routine detail screen renders
- **THEN** the moment chip and the summary card both fill with that accent's container color

#### Scenario: A routine with no moment still shows the fallback text

- **GIVEN** a routine with no assigned moment
- **WHEN** the routine detail screen renders
- **THEN** the chip shows the existing "no moment" text instead of a blank chip

### Requirement: History dots render three completion states

The seven history dots SHALL each render one of three states: a day with a completed run renders a
filled circle in `context.routineCardColors.onFill`; a day with an attempt that wasn't completed
renders a 1.5px ring in that same color; a day with no logged run renders a 1.5px ring at 30%
opacity of that color. Each dot SHALL keep its existing tooltip and semantics describing which state
it represents.

#### Scenario: A completed day renders filled

- **GIVEN** a day within the last 7 days has a completed run logged
- **WHEN** the history dots render
- **THEN** that day's dot is a filled circle and its tooltip reports the completed state

#### Scenario: An attempted, unfinished day renders a solid ring

- **GIVEN** a day within the last 7 days has a run that was started but not completed
- **WHEN** the history dots render
- **THEN** that day's dot is an unfilled ring and its tooltip reports the abandoned state

#### Scenario: A day with no run renders a faint ring

- **GIVEN** a day within the last 7 days has no logged run
- **WHEN** the history dots render
- **THEN** that day's dot renders at reduced opacity and its tooltip reports nothing was logged

### Requirement: Start Timer keeps its enabled rule

The Start Timer button SHALL remain disabled, and SHALL show the existing helper text, exactly when
the routine has no steps. It SHALL navigate to the routine's timer route when enabled and selected.

#### Scenario: Start Timer is disabled with no steps

- **GIVEN** a routine with no steps
- **WHEN** the routine detail screen renders
- **THEN** Start Timer is disabled and the existing helper text is shown

#### Scenario: Start Timer is enabled with at least one step

- **GIVEN** a routine with at least one step
- **WHEN** the routine detail screen renders
- **THEN** Start Timer is enabled, and selecting it navigates to the timer route

### Requirement: Steps render in one bordered container with internal dividers

All step rows SHALL render inside a single container with a visible border and clipped corners,
rather than one card per row. A 1px divider SHALL separate each pair of adjacent rows, and no
divider SHALL render after the last row. Reordering, the transparent drag-proxy, the saving-order
lock, the single-step case, the empty-list case, and every existing tooltip and semantics label
SHALL behave exactly as they do today.

#### Scenario: No divider follows the last row

- **GIVEN** a routine with three or more steps
- **WHEN** the step list renders
- **THEN** exactly `steps.length - 1` dividers render, and none renders below the final row

#### Scenario: Reordering still updates step order

- **GIVEN** a routine with three or more steps
- **WHEN** the user drags a step to a new position
- **THEN** the step order updates and persists, exactly as it does before this change

#### Scenario: A single step shows no drag handle

- **GIVEN** a routine with exactly one step
- **WHEN** the step list renders
- **THEN** no drag handle is present

### Requirement: The screen tolerates large text scales

At a 1.5x and a 2.0x text-scale factor, no part of the routine detail screen SHALL overflow or
report a rendering error.

#### Scenario: The screen renders without overflow at 2.0x text scale

- **GIVEN** the platform text-scale factor is set to 2.0
- **WHEN** the routine detail screen renders with a routine that has steps and history
- **THEN** no overflow error is reported
