## Purpose

Defines the shared flat-surface widget set for the "tinted paper" redesign: tokens and
widgets that later, separate changes will apply to individual screens. The capability
exists on its own, with no screen consuming it yet, so that the foundation reviews as
one small slice ahead of the larger job of restyling every screen.

## ADDED Requirements

### Requirement: Tinted radius and typography tokens exist

The theme SHALL expose `AppRadius.tinted` (20) and `AppRadius.hero` (24), each with a
matching `BorderRadius` constant, and `AppTypography` SHALL expose `pageTitle` and
`sectionLabel` static text styles. These additions SHALL NOT alter any existing
`TextTheme` role or any existing `AppRadius`/`AppSpacing` constant.

#### Scenario: Existing tokens are unchanged

- **GIVEN** the theme before this change
- **WHEN** `AppRadius.tinted`, `AppRadius.hero`, `AppTypography.pageTitle`, and
  `AppTypography.sectionLabel` are added
- **THEN** every previously existing token keeps its previous value

### Requirement: `TintedCard` renders a flat, tintable surface

`TintedCard` SHALL render its `child` on a solid fill of a required `color`, with no
shadow, using `borderRadius` (default `AppRadius.tinted`) and `padding` (default
`EdgeInsets.fromLTRB(16, 18, 16, 18)`). It SHALL apply a required `foregroundColor` to
descendant text and icons via `DefaultTextStyle.merge` and `IconTheme.merge`. When an
`onTap` callback is supplied, the card SHALL provide an ink/press response, SHALL
deform by no more than 5% while held, using a motion duration resolved through the
reduced-motion resolver, and SHALL expose `Semantics(button: true)`. Without `onTap`,
the card SHALL NOT expose button semantics.

#### Scenario: A tappable card responds to a press

- **GIVEN** a `TintedCard` with an `onTap` callback
- **WHEN** the user presses and holds it
- **THEN** the card visibly deforms by no more than 5% and reports `button: true` in
  its semantics

#### Scenario: A non-interactive card carries no button semantics

- **GIVEN** a `TintedCard` with no `onTap` callback
- **WHEN** its semantics are inspected
- **THEN** it does not report `button: true`

#### Scenario: Reduced motion suppresses the press deform animation

- **GIVEN** the platform has requested reduced motion
- **WHEN** a tappable `TintedCard` is pressed
- **THEN** its deform animation resolves at zero duration rather than animating

### Requirement: `SoftCircleButton` renders a flat circular control

`SoftCircleButton` SHALL render a circular flat fill sized 48 or 64 (default 48), with
a required `icon` and `tooltip`, and an `onPressed` callback. Its `style` SHALL be
either `neutral` (fill `colorScheme.surfaceContainer`, icon color `onSurface`) or
`accent` (fill `colorScheme.primaryContainer`, icon color `onPrimaryContainer`). Icon
size SHALL be 22 at the 48 size and 24 at the 64 size. It SHALL deform by no more than
5% while held, through the reduced-motion resolver, and its rendered hit target SHALL
NOT fall below 48 logical pixels at either size.

#### Scenario: The 48px button meets the hit-target floor

- **GIVEN** a `SoftCircleButton` at its default size
- **WHEN** its layout is measured
- **THEN** its tappable area is at least 48 by 48 logical pixels

#### Scenario: Tapping invokes the callback

- **GIVEN** a `SoftCircleButton` with an `onPressed` callback
- **WHEN** the user taps it
- **THEN** the callback fires exactly once

### Requirement: `PageHeader` lays out a header without Material chrome

`PageHeader` SHALL render a header row 48 logical pixels tall with no bar, background,
elevation, or shadow. It SHALL accept an optional `leading` widget, an optional `title`
(rendered left-aligned in `AppTypography.pageTitle`, with an 8px left inset), and a
list of `actions` spaced 8px apart on the trailing side. At a 2.0x text scale factor,
the title SHALL be allowed to wrap to a second line and the row SHALL grow to
accommodate it rather than overflow.

#### Scenario: The header renders with no chrome

- **GIVEN** a `PageHeader` with a title and one action
- **WHEN** it is inspected
- **THEN** no `AppBar`, `Material` elevation, or box shadow is present in its render
  tree

#### Scenario: The title wraps at large text scale instead of overflowing

- **GIVEN** a `PageHeader` with a long title
- **WHEN** the text scale factor is 2.0
- **THEN** the title wraps rather than overflowing, and no overflow error is reported

### Requirement: `SectionLabel` renders an uppercase section caption

`SectionLabel` SHALL render its text in `AppTypography.sectionLabel`, uppercased,
colored `colorScheme.onSurfaceVariant`, with an 8px horizontal inset.

#### Scenario: Label text is uppercased for display

- **GIVEN** a `SectionLabel` constructed with lowercase text
- **WHEN** it renders
- **THEN** the displayed text is uppercase

### Requirement: `SegmentedProgress` renders filled and unfilled segments

`SegmentedProgress` SHALL render `count` rounded segments (height 6, radius 3) filling
the available width, with a 6px gap between segments when `count` is 8 or fewer and a
4px gap when `count` exceeds 8. The first `filled` segments SHALL render `color` at
0.7 opacity; the remaining segments SHALL render `color` at 0.15 opacity. It SHALL
accept a `semanticsLabel` describing overall progress.

#### Scenario: Filled and unfilled segments use different opacities

- **GIVEN** a `SegmentedProgress` with `count: 5` and `filled: 2`
- **WHEN** it renders
- **THEN** exactly 2 segments render `color` at 0.7 opacity and 3 render it at 0.15
  opacity

#### Scenario: Segment gap narrows past eight segments

- **GIVEN** a `SegmentedProgress` with `count: 9`
- **WHEN** it renders
- **THEN** the gap between segments is 4 logical pixels rather than 6

### Requirement: `PillSegmentedControl` tracks a `TabController`

`PillSegmentedControl` SHALL render a track (fill `surfaceContainer`, height 48,
padding 4, fully rounded) holding one pill per label, driven by a required
`TabController` and list of labels. The selected pill SHALL fill
`surfaceContainerLowest` with a 1px `outlineVariant` border; its label SHALL render in
Lexend 15 w600 `onSurface`, while unselected labels render Lexend 15 w500
`onSurfaceVariant`. The pill's position SHALL follow `controller.animation`, so that
swiping a `TabBarView` sharing the controller moves the pill continuously rather than
snapping only on settle. Tapping a segment SHALL call `controller.animateTo` with that
segment's index. Each segment SHALL expose tab semantics carrying the selected state.
At a 2.0x text scale factor, the control SHALL grow taller rather than clipping its
labels.

#### Scenario: Tapping a segment changes the controller's index

- **GIVEN** a `PillSegmentedControl` on a 3-tab `TabController` at index 0
- **WHEN** the user taps the third segment
- **THEN** the controller animates to index 2

#### Scenario: Swiping a paired `TabBarView` moves the pill mid-gesture

- **GIVEN** a `PillSegmentedControl` and a `TabBarView` sharing one `TabController`
- **WHEN** the user swipes the `TabBarView` partway toward the next page
- **THEN** the pill's position updates before the swipe gesture completes

#### Scenario: Segment semantics report selection

- **GIVEN** a `PillSegmentedControl` with segment 1 selected
- **WHEN** its semantics tree is inspected
- **THEN** segment 1 reports selected tab semantics and the others do not

#### Scenario: The control grows rather than clips at large text scale

- **GIVEN** a `PillSegmentedControl` with a long label
- **WHEN** the text scale factor is 2.0
- **THEN** the control's height grows and no label is clipped or overflowed
