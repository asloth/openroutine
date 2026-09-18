## Purpose

Defines what a screen's back control and routine detail's delete control render as. The capability
exists because a screen that renders these controls with the stock Material widgets, rather than
the tinted-paper set the rest of the app has moved to, reads as a different app mid-navigation —
and a menu that always opens to one item costs a tap it doesn't save.

## ADDED Requirements

### Requirement: Every screen's back control is a SoftBackButton

Any screen that shows a back control in its top bar SHALL render it as `SoftBackButton`: a 48px
`SoftCircleButton` with `Icons.chevron_left`, not the stock Material back arrow.

#### Scenario: A screen with an AppBar is shown

- **WHEN** routine form, step form, settings, or import renders its `AppBar`, in any of its
  states (loaded, loading, error, or unavailable)
- **THEN** the `AppBar`'s leading is a `SoftBackButton`
- **AND** neither the stock `Icons.arrow_back` nor `Icons.arrow_back_ios` appears

#### Scenario: The back control is tapped with no override

- **GIVEN** a `SoftBackButton` with no `onPressed` given
- **WHEN** it's tapped
- **THEN** it pops the current route, the same way the stock back button would

### Requirement: The back control sits in a consistent position

A `SoftBackButton` placed as an `AppBar`'s leading SHALL sit 16px from the left edge and vertically
centered in the toolbar, matching the inset routine detail's hand-rolled row already uses.

#### Scenario: The back control is placed in an AppBar

- **WHEN** a `SoftBackButton` is set as an `AppBar`'s `leading`
- **THEN** its left edge is 16px from the bar's left edge
- **AND** it's vertically centered in the toolbar

### Requirement: Routine detail's delete control needs one tap, not two

Routine detail SHALL show its delete control as a `SoftCircleButton` with `Icons.delete_outline`,
directly in the header row, rather than behind an overflow menu.

#### Scenario: Routine detail's header row is shown

- **WHEN** routine detail renders its header row
- **THEN** it shows a `SoftCircleButton` with `Icons.delete_outline` and the tooltip for Delete
- **AND** no overflow menu (`Icons.more_horiz` or a `PopupMenuButton`) appears

#### Scenario: The delete control is tapped

- **WHEN** the delete control is tapped
- **THEN** the same confirm dialog it showed from behind the menu appears
- **AND** confirming deletes the routine, invalidates the routines list, and returns to the
  previous screen, exactly as it did before
