## Purpose

Defines how the "Add step" and "Edit step" screen presents step templates, the guidance text under
its toggles, the name field's character counter, and the duration picker. The capability exists
because this screen is the one place a person composes a routine step by hand, and a control that
can't be read, or costs too many taps, gets abandoned in favor of typing everything from scratch.

## ADDED Requirements

### Requirement: Templates open in a sheet, grouped by category, when creating a step

When creating a step, the screen SHALL show a full-width button that opens a template picker.
Selecting a template SHALL fill the step's name, emoji, and duration and close the picker. The
button SHALL NOT appear when editing an existing step.

The picker SHALL group templates by category, with each category's label shown once above its
templates. Each template SHALL be readable in full — its name SHALL NOT be truncated or clipped at
any text scale the app supports. A template with a duration SHALL show its duration; a template
with none SHALL show only its emoji and name.

#### Scenario: Creating a step shows the template entry point

- **WHEN** a person opens "Add step"
- **THEN** a full-width "Start from a template" button appears under the name field

#### Scenario: Editing a step hides the template entry point

- **WHEN** a person opens "Edit step" for an existing step
- **THEN** no template button appears

#### Scenario: Opening the picker groups templates by category

- **WHEN** a person selects the template button
- **THEN** a sheet opens showing each category's label once, with that category's templates
  beneath it

#### Scenario: A template name reads in full at a large text scale

- **GIVEN** the template picker is open
- **WHEN** the device text scale is 1.5x the default
- **THEN** every template's name still renders in full, with no ellipsis or clipped glyphs

#### Scenario: Picking a template fills the step and closes the picker

- **GIVEN** the template picker is open
- **WHEN** a person selects a template
- **THEN** the name field, emoji, and duration take that template's values, and the picker closes

#### Scenario: A template with no duration shows no duration

- **GIVEN** a template that has no duration
- **WHEN** the picker shows that template
- **THEN** only its emoji and name appear, with no duration text

### Requirement: Toggle guidance reads as part of its toggle

The explanatory text under the "essential for Low Mode" checkbox and the "remind me during this
step" switch SHALL be that control's subtitle, not a separate sibling element. A screen reader
SHALL reach the guidance as part of the control's own description, without a duplicate
announcement.

#### Scenario: The essential toggle's guidance is its subtitle

- **WHEN** the "essential for Low Mode" checkbox renders
- **THEN** its guidance text is that checkbox tile's subtitle

#### Scenario: The reminder toggle's guidance is its subtitle

- **WHEN** the "remind me during this step" switch renders with an explicit time set
- **THEN** its guidance text is that switch tile's subtitle

#### Scenario: Guidance disappears with its control

- **GIVEN** a step has no explicit time
- **WHEN** the reminder switch is unavailable
- **THEN** its guidance text is also absent, rather than left showing on its own

### Requirement: The name field hides its character counter

The step name field SHALL enforce its 50-character limit without displaying a counter below it.

#### Scenario: The name field shows no counter

- **WHEN** the "Add step" or "Edit step" name field renders
- **THEN** no character count appears beneath it

#### Scenario: The limit still applies

- **WHEN** a person types past 50 characters into the name field
- **THEN** the field stops accepting further characters

### Requirement: Duration offers fixed one-tap presets

The duration picker SHALL offer chips for 1, 2, 3, 5, 10, 15, 20, 30, 45, and 60 minutes. When the
step's current duration is not one of those values, the picker SHALL show it as an additional
selected chip in sorted position, so the stored or templated value is never changed by opening the
picker.

#### Scenario: The presets render

- **WHEN** the duration picker renders
- **THEN** chips for 1, 2, 3, 5, 10, 15, 20, 30, 45, and 60 minutes all appear

#### Scenario: A non-preset duration keeps its own chip

- **GIVEN** a step whose duration is 7 minutes
- **WHEN** the duration picker renders
- **THEN** a 7-minute chip appears, selected, in sorted position among the presets

#### Scenario: Selecting a preset changes the duration

- **WHEN** a person selects a preset chip
- **THEN** the step's duration becomes that chip's value
