## ADDED Requirements

### Requirement: The accent colors the entire theme

The chosen accent SHALL be the app's whole theme. Its `ColorScheme` — surfaces, primary, secondary,
tertiary, and every other role — its neumorphic shadow pair, and its mascot colors SHALL all come
from the same chosen palette. There SHALL NOT be a separate background palette merged underneath
it.

#### Scenario: An accent is chosen

- **WHEN** the user chooses an accent color
- **THEN** the app's surfaces, every color role, and the mascot all take that palette's own colors

#### Scenario: The theme is built with a chosen accent

- **WHEN** the app theme is built with a given accent, in either light or dark
- **THEN** the theme's `MascotPalette` equals that accent's own mascot colors
- **AND** the theme's `ColorScheme.surface` equals that accent's own surface color

## MODIFIED Requirements

### Requirement: The accent defaults to purple

When no accent has been stored, the app SHALL theme itself — surfaces, every color role, and the
mascot, not only routine cards and primary actions — with `Palette.inkIris`. An unrecognized stored
accent identifier SHALL also resolve to `Palette.inkIris`.

#### Scenario: No accent has been chosen

- **WHEN** the app starts with no stored accent
- **THEN** the whole app, including its surfaces and its mascot, is themed with ink iris

#### Scenario: A stored accent is not recognized

- **GIVEN** a stored accent identifier the build does not know
- **WHEN** the app starts
- **THEN** the whole app, including its surfaces and its mascot, is themed with ink iris

## REMOVED Requirements

### Requirement: An accent color is independent of the background palette

**Reason**: There is no longer a background palette for the accent to be independent from. The
accent is the only color setting Settings › Appearance offers, and "The accent colors the entire
theme" (above) replaces this requirement's job.

**Migration**: None. Anyone who had chosen a background palette different from their accent now
sees their accent's palette everywhere; anyone who never touched either setting already saw ink
iris as their accent and keeps seeing it, now applied to the whole app.

### Requirement: The accented scheme clears the same contrast bar as any palette

**Reason**: This requirement guaranteed an accent's `primary` cleared AA against a *different*
palette's surface, once the two were merged. With no merge step, an accent's `primary` only ever
appears against its own surface, which every built-in and generated palette already guarantees on
its own — see `app/test/theme/palette_test.dart`'s AA sweep across every built-in and the full hue
wheel.

**Migration**: None.

### Requirement: Elevated surfaces don't tint with the accent

**Reason**: `surfaceTint` used to stay pinned to the background palette specifically so it wouldn't
shift color when the accent differed from it. With one palette driving the whole theme, there is
nothing else for `surfaceTint` to diverge from — it comes from the same palette as every other role,
same as it always did.

**Migration**: None.
