## Purpose

See `add-rive-mascot`'s delta for the base of this capability. This delta narrows when the
hand-drawn stand-in shows: only when there's truly no pet to render, not for the ordinary window
while the shared Rive file is loading.

## MODIFIED Requirements

### Requirement: The slot always draws something

The mascot SHALL render the hand-drawn stand-in only when there is no pet to show at all: the Rive
runtime is unavailable, or the file failed to load. While the shared Rive file — or the state
machine built from it — is still loading, the slot SHALL render an empty box at its own size rather
than the stand-in, so the stand-in never flashes in front of the real pet.

#### Scenario: The runtime is unavailable

- **WHEN** the Rive file fails to load
- **THEN** the slot still draws a pet at the requested size

#### Scenario: The shared file is still loading

- **WHEN** a slot mounts while the shared Rive file has not yet finished loading
- **THEN** the slot renders an empty box at its own size
- **AND** it does not render the hand-drawn stand-in

#### Scenario: A second slot reuses the first slot's load

- **GIVEN** one slot has already triggered the shared file's load
- **WHEN** a second slot mounts, on the same screen or a later one, before that load finishes
- **THEN** the second slot shares the same in-flight load rather than starting a new one
- **AND** neither slot shows the hand-drawn stand-in until that shared load settles
