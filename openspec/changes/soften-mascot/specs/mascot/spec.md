## ADDED Requirements

### Requirement: The pet smiles with its eye on happy moments

When the pet celebrates, cheers a done step, jumps, or bounces, its eye SHALL smile by a lid rising from below, and the eye SHALL keep its shape rather than squashing flat.

#### Scenario: A routine finishes

- **WHEN** a screen passes `MascotMood.cheering`
- **THEN** the pet's eye smiles from below while it celebrates, and returns to its full shape when it's done

#### Scenario: A step is done

- **WHEN** the pet reacts to a completed step
- **THEN** its eye smiles from below for the length of the reaction
