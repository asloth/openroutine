## Purpose

Defines the concrete surface, sizing, motion, and accessibility floor of the widget that
renders `app-navigation`'s two top-level destinations. That capability already requires
the destinations to exist, stay visible, and preserve state; this one replaces
`app-navigation`'s "SHALL present its top-level destinations in a persistently visible
bar" requirement's implied Material rendering with the tinted-paper floating pill,
without restating the destinations, their order, or their state-preservation guarantee.

## ADDED Requirements

### Requirement: The destination bar renders as a flat, bordered pill

The bar SHALL render as a pill: a fill of `colorScheme.surfaceContainerLowest`, a 1px
border of `colorScheme.outlineVariant`, a fully rounded shape, and no shadow. The pill
SHALL be centered horizontally and positioned 16 logical pixels above the bottom safe
area inset. The pill SHALL have 5 logical pixels of padding around its destinations and
a 4 logical pixel gap between them. The stock Material `NavigationBar` SHALL NOT be
present.

#### Scenario: The bar carries no Material chrome

- **WHEN** the routine list is shown
- **THEN** no `NavigationBar` widget is present in the tree

### Requirement: A destination shows an outlined or filled icon above its label

Each destination SHALL render a 22 logical pixel icon above its label, in that order.
The icon SHALL be outlined when the destination isn't selected and filled when it is.
The label SHALL render in Lexend at 12 logical pixels, weight 600 when selected and
weight 500 otherwise. A selected destination SHALL fill with
`colorScheme.primaryContainer` behind `colorScheme.onPrimaryContainer` icon and label
color; an unselected destination SHALL have no fill and SHALL use
`colorScheme.onSurfaceVariant` for its icon and label.

#### Scenario: The selected destination is filled

- **GIVEN** the routine list is the current destination
- **WHEN** the bar is inspected
- **THEN** the Routines destination shows a `primaryContainer` fill and the
  Statistics destination shows none

### Requirement: The selected fill animates between destinations

Moving the selection from one destination to the other SHALL animate the fill using a
duration and curve from `app/lib/theme/motion.dart`, resolved through the
reduced-motion resolver on `BuildContext`.

#### Scenario: Reduced motion resolves the fill change immediately

- **GIVEN** the platform has requested reduced motion
- **WHEN** the selected destination changes
- **THEN** the fill's animation resolves at zero duration rather than animating

### Requirement: Each destination meets the hit-target floor

Each destination's tappable area SHALL be at least 48 by 48 logical pixels, regardless
of how small its visual content would otherwise be.

#### Scenario: A destination's hit target is measured

- **WHEN** a destination's layout is measured
- **THEN** its tappable area is at least 48 by 48 logical pixels in both dimensions

### Requirement: Each destination exposes selected-state semantics

Each destination SHALL expose a single semantics node carrying its label, `button:
true`, and whether it is the one currently selected. A screen reader SHALL be able to
distinguish the selected destination from the other by that state.

#### Scenario: The selected destination's semantics differ from the other's

- **GIVEN** the routine list is the current destination
- **WHEN** the semantics tree is inspected
- **THEN** the Routines destination reports selected and the Statistics destination
  does not

### Requirement: A label grows with the system text scale, capped at 1.6x

A destination's label SHALL grow with the system text scale up to a ceiling of 1.6x,
past which it SHALL NOT grow further. A destination SHALL NOT exceed 140 logical pixels
of width; a label that would otherwise need more SHALL wrap onto a second line rather
than widen the destination further. Neither destination's label SHALL overflow at any
system text scale up to and including 2.0x on a 360 logical-pixel-wide screen.

#### Scenario: A label does not overflow at a large system text scale

- **GIVEN** a system text scale of 2.0x on a 360 logical-pixel-wide screen
- **WHEN** the bar renders
- **THEN** neither destination's label overflows its bounds

### Requirement: The body clears the pill's height

The screen behind the bar SHALL extend beneath the pill rather than stopping above it,
and the body's `MediaQuery.padding.bottom` SHALL be at least the pill's rendered height,
so a screen that pads its content by that value clears the pill without needing to know
its size directly.

#### Scenario: The body's bottom padding accounts for the pill

- **WHEN** the routine list's `MediaQuery.padding.bottom` is read from within the body
- **THEN** it is at least as large as the pill's rendered height
