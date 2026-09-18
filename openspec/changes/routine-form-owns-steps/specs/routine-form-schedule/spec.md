# Routine form

## MODIFIED Requirements

### Requirement: A routine cannot be saved without a step

The form SHALL hold its steps in memory and SHALL NOT write anything to
storage until Save. Save SHALL be unavailable while the routine has no steps.

On Save the routine and its steps SHALL be written together.

#### Scenario: A new routine with no steps
- **WHEN** the form has a name, a day, and no steps
- **THEN** Save is disabled
- **AND** nothing has been written to storage

#### Scenario: Backing out of a half-built routine
- **WHEN** a name and two steps have been entered and the form is dismissed
- **THEN** no routine and no steps exist in storage

#### Scenario: Saving
- **WHEN** the form has a name, a day, and two steps, and Save is pressed
- **THEN** the routine and both steps are written
- **AND** the button read "Save · 2 steps" before it was pressed

### Requirement: Save is the screen's main control

Save SHALL be a full-width button at the bottom of the screen, and SHALL
report how many steps the routine has and how long it is estimated to take.

#### Scenario: A routine of two steps
- **WHEN** the routine has a 3-minute and a 2-minute step
- **THEN** the button reads "Save · 2 steps, 5 min"
