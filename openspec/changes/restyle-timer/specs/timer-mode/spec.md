## Purpose

Defines the running timer screen's tinted-paper surface: a tinted ground, flat circular controls,
and segmented step progress, replacing the neumorphic idiom on this one screen without changing
where any control sits or what it does.

## ADDED Requirements

### Requirement: The running screen's ground is the timer's tinted color

The running timer screen's `Scaffold` SHALL paint its background with
`context.routineCardColors.timerGround` rather than the theme's default scaffold background. Body
text and icons SHALL remain `onSurface`.

#### Scenario: The scaffold reads the timer ground token

- **GIVEN** the running timer screen
- **WHEN** its `Scaffold` is inspected
- **THEN** its background color equals `context.routineCardColors.timerGround`

### Requirement: Step progress renders as segments, not a linear bar

The running screen SHALL render step progress as a `SegmentedProgress` with one segment per step
(`count: steps.length`), filled through the current step (`filled: currentIndex + 1`), colored
`onSurface`, positioned 12 logical pixels below the "Step N of M" counter within the same 24px
horizontal padding. It SHALL NOT render a `LinearProgressIndicator`. Its semantics label SHALL
match the step counter's displayed text.

#### Scenario: The segmented progress reflects the current step

- **GIVEN** a routine with 4 steps, currently on step 2
- **WHEN** the running screen is inspected
- **THEN** a `SegmentedProgress` with `count: 4` and `filled: 2` is present
- **AND** no `LinearProgressIndicator` is present

#### Scenario: Advancing a step fills one more segment

- **GIVEN** the running screen showing step 2 of 4
- **WHEN** the user completes the step and the screen advances to step 3
- **THEN** the `SegmentedProgress`'s `filled` value becomes 3

#### Scenario: The progress semantics label matches the step counter

- **GIVEN** the running screen showing "Step 2 of 4"
- **WHEN** the `SegmentedProgress`'s semantics are inspected
- **THEN** its label reads the same "Step 2 of 4" text

### Requirement: Close is a neutral flat circular control

The running screen's close control, in its existing top-right position, SHALL be a
`SoftCircleButton` at its default 48px size and `neutral` style, with an X icon (`Icons.close`),
the existing tooltip, and the existing abandon-confirmation flow untouched.

#### Scenario: Close still asks for confirmation before leaving

- **GIVEN** a running timer
- **WHEN** the user taps the close control
- **THEN** an abandon-confirmation dialog appears, and confirming it abandons the run

### Requirement: Pause/Resume and Restart step are accent flat circular controls

The running screen's pause/resume and restart-step controls SHALL each be a `SoftCircleButton` at
64px in the `accent` style (fill `primaryContainer`, icon color `onPrimaryContainer`), keeping
their existing icons, tooltips, positions, and actions.

#### Scenario: Pause and resume still toggle the run

- **GIVEN** a running timer
- **WHEN** the user taps the pause control
- **THEN** the timer pauses and the control swaps to show resume

#### Scenario: Restart step still resets the current step's clock

- **GIVEN** a running timer partway through a step
- **WHEN** the user taps the restart-step control
- **THEN** the current step's elapsed time resets to zero

### Requirement: The ring and estimate-zone color are unchanged

`TimerClock`'s ring color SHALL continue to read the theme's `primary` role outside the estimate's
yellow zone, and `tertiary` within it. This means the ring follows whichever accent the user has
chosen; it SHALL NOT be recolored to a fixed green, because green is reserved for "a routine is
coming up soon" and using it here would blur that distinct meaning.

#### Scenario: The ring is not green while running

- **GIVEN** a running timed step before its estimate boundary
- **WHEN** the ring's color is inspected
- **THEN** it equals the theme's `primary` color and is not the fixed "upcoming" green

### Requirement: Do later stays visually secondary to Done

The "Do later" control SHALL render its label and icon in `onSurface`, keeping its existing
position, icon, and the rule that hides it on the last step and after one deferral of the current
step.

#### Scenario: Do later still hides on the last step

- **GIVEN** the running screen on the routine's last step
- **WHEN** the screen is inspected
- **THEN** "Do later" is not present

#### Scenario: Do later still hides after one deferral

- **GIVEN** a step that has already been deferred once
- **WHEN** the running screen is inspected for that step
- **THEN** "Do later" is not present
