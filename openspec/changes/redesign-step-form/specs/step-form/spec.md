## ADDED Requirements

### Requirement: The step form saves from a bottom button

The step form SHALL put its save action in a full-width button at the bottom of the screen. The button SHALL stay disabled and say so until the step has a name.

#### Scenario: A new step has no name yet

- **WHEN** you open the form to add a step
- **THEN** the bottom button reads "Name it first" and is disabled

#### Scenario: You type a name

- **WHEN** the name field has text
- **THEN** the bottom button is enabled and saves the step

### Requirement: Duration is picked from a grid of minute tiles

The form SHALL show one tile per preset duration, and SHALL add a tile for a stored duration that isn't a preset, selected.

#### Scenario: No set time

- **WHEN** you turn on "No set time"
- **THEN** the tiles and the mid-step reminder are hidden, and the step saves with no duration and no reminder
