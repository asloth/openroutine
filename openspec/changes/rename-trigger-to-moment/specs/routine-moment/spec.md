## Purpose

Covers the control that assigns a routine to a named moment of the day, such as "After waking up". It exists because this control's effects are all deferred — they appear on the routines list and in notifications, never on the screen where the choice is made — so without a deliberate requirement it reads to the user as a control that does nothing.

## ADDED Requirements

### Requirement: The control is named for what it is

The control SHALL be presented with a name describing a moment in the user's day, not a mechanism that fires. It SHALL NOT be named in a way that implies the app performs an action when the moment arrives, because it performs none.

This applies to every locale. A translation SHALL convey a moment or occasion, not a firing mechanism.

#### Scenario: The user opens the routine form

- **WHEN** the routine form is displayed
- **THEN** the control is labelled with a term describing a moment of the day
- **AND** the label does not imply automatic activation

#### Scenario: The interface is displayed in Spanish

- **WHEN** the routine form is displayed in Spanish
- **THEN** the control's label conveys a moment or occasion rather than a firing mechanism

### Requirement: The control states its effects where it is chosen

Because every effect of assigning a moment appears on a different screen than the one where it is assigned, the form SHALL state what assigning one does, adjacent to the control.

The statement SHALL name the effects that actually occur and SHALL NOT describe behaviour the app does not perform.

#### Scenario: The user views the control

- **WHEN** the routine form is displayed
- **THEN** text adjacent to the control states that a moment groups routines and appears in reminders

#### Scenario: A routine is assigned a moment

- **GIVEN** a routine assigned to a moment
- **WHEN** a reminder for that routine is delivered
- **THEN** the reminder names the moment, matching what the form said it would do
