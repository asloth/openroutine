## Purpose

Defines what a fresh install of OpenRoutine is themed with, and the requirement that every themed component follows the selected palette's colour roles rather than falling back to framework defaults. The capability exists because a component the theme forgets does not look obviously wrong in the palette it was designed against — it only becomes visible in a different one, by which time it reads as a bug in the palette rather than a gap in the theme.

## ADDED Requirements

### Requirement: A fresh install uses the default palette

When no palette has been stored, the app SHALL theme itself with a single named default palette. That default SHALL be defined in one place, so that changing it does not require finding every fallback.

An unrecognised stored palette identifier SHALL also resolve to that default rather than leaving the app unthemed.

#### Scenario: No palette has been chosen

- **WHEN** the app starts with no stored palette
- **THEN** it is themed with the default palette

#### Scenario: A stored palette is not recognised

- **GIVEN** a stored palette identifier the build does not know
- **WHEN** the app starts
- **THEN** it is themed with the default palette rather than left unthemed

#### Scenario: A chosen palette survives the default changing

- **GIVEN** the user has previously chosen a palette
- **WHEN** the app starts
- **THEN** it is themed with the palette the user chose, not the default

### Requirement: Themed components follow the selected palette

Every interactive component the app renders SHALL take its colours from the selected palette's roles. A component SHALL NOT fall back to framework default colouring, because framework defaults draw from roles the app does not use for that purpose and diverge unpredictably as the palette changes.

Components that express the same idea SHALL use the same role as each other. A selected segment and a selected chip are the same idea and SHALL match.

#### Scenario: A selected segment is rendered

- **WHEN** a segmented control renders a selected segment
- **THEN** its background comes from the same palette role a selected chip uses

#### Scenario: The palette changes

- **GIVEN** a palette whose secondary role differs sharply in hue from its primary
- **WHEN** a segmented control renders a selected segment
- **THEN** it remains consistent with the rest of the interface rather than taking the divergent role
