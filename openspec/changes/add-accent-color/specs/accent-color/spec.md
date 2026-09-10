## Purpose

Defines the accent color: the color routine cards and primary actions carry, chosen independently
of the background palette, plus the fixed colors that no setting can change.

## ADDED Requirements

### Requirement: An accent color is independent of the background palette

The app SHALL let the user choose an accent color separately from the background palette. Choosing
an accent SHALL NOT change the background palette, and choosing a background palette SHALL NOT
change the accent.

The accent SHALL be chosen from the same set of built-in palettes offered for the background, using
each one's `primary` identity. A custom hue is not offered for the accent.

#### Scenario: Choosing an accent leaves the palette alone

- **GIVEN** the app is themed with a chosen background palette
- **WHEN** the user chooses a different accent color
- **THEN** the background palette's surfaces are unchanged

#### Scenario: Choosing a palette leaves the accent alone

- **GIVEN** the app is themed with a chosen accent color
- **WHEN** the user chooses a different background palette
- **THEN** the accent color is unchanged

### Requirement: The accent defaults to purple

When no accent has been stored, the app SHALL theme routine cards and primary actions with
`Palette.inkIris`. An unrecognized stored accent identifier SHALL also resolve to `Palette.inkIris`.

This default is independent of whatever the background palette defaults to.

#### Scenario: No accent has been chosen

- **WHEN** the app starts with no stored accent
- **THEN** routine cards and primary actions are themed with ink iris

#### Scenario: A stored accent is not recognized

- **GIVEN** a stored accent identifier the build does not know
- **WHEN** the app starts
- **THEN** routine cards and primary actions are themed with ink iris

### Requirement: The accented scheme clears the same contrast bar as any palette

The colors the accent contributes to the theme SHALL clear WCAG AA against the surfaces they
actually appear on: the accented `primary` SHALL clear 4.5:1 against the background palette's
`surface`, and the accented `onPrimaryContainer` SHALL clear 4.5:1 against the accented
`primaryContainer`. This SHALL hold for every combination of background palette and accent, in both
light and dark.

#### Scenario: An accent is paired with an unrelated background palette

- **GIVEN** a background palette and an accent color that are not the same palette
- **WHEN** the app builds its theme
- **THEN** the accented primary clears 4.5:1 against that background palette's surface in both
  light and dark

### Requirement: Elevated surfaces don't tint with the accent

Material's elevation tint (`surfaceTint`) SHALL keep coming from the background palette, not the
accent, so menus, dialogs, and other elevated surfaces don't shift color when the accent changes.

#### Scenario: A menu opens over an accented theme

- **GIVEN** an accent color that differs from the background palette's own primary
- **WHEN** an elevated surface such as a menu or dialog is themed
- **THEN** its tint comes from the background palette, not the accent

### Requirement: Routine cards carry the accent's colors

The theme SHALL expose the accent's container colors as `RoutineCardColors`, for routine cards and
similar surfaces to read directly rather than assuming which `ColorScheme` role currently holds the
accent.

#### Scenario: The theme is built with a chosen accent

- **WHEN** the app theme is built with a given accent
- **THEN** `RoutineCardColors.fill` and `RoutineCardColors.onFill` come from that accent's container
  pair

### Requirement: "Coming up" green is fixed, not part of any palette

The color that marks a routine as coming up soon SHALL be fixed across every background palette and
every accent, in both light and dark. It SHALL NOT be generated from, or altered by, either setting.

#### Scenario: The palette or accent changes

- **GIVEN** any combination of background palette and accent
- **WHEN** the app themes a routine as "coming up soon"
- **THEN** it uses the fixed upcoming color, not a color derived from the palette or accent
