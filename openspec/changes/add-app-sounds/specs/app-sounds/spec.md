## ADDED Requirements

### Requirement: A run sounds its milestones

The app SHALL play a short sound when you finish a step and the next one starts, and a celebration sound when you finish the routine. Skipping a step or stopping early SHALL play nothing.

#### Scenario: You finish a step that isn't the last

- **WHEN** you mark a step done and another step follows
- **THEN** the step-done sound plays

#### Scenario: You finish the last step

- **WHEN** you mark the last step done
- **THEN** the routine-finished sound plays, and the step-done sound doesn't

### Requirement: You can turn sounds off

Settings SHALL offer a Sounds switch, on by default. When it's off, the app SHALL play none of its own sounds.

#### Scenario: Sounds are off

- **GIVEN** you turned Sounds off
- **WHEN** you finish a step or a routine
- **THEN** no sound plays
