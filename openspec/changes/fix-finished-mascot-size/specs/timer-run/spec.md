## Purpose

See `redesign-timer-run`'s delta for the base of this capability: what the running and finished
timer screens show and which actions they offer. This delta adds the guarantee that the mascot is
the same size on both screens, so it reads as the same companion whether it's working alongside you
or celebrating with you.

## MODIFIED Requirements

### Requirement: The finished screen celebrates and returns to today

When a run finishes, the timer SHALL show the mascot cheering, at the same size the mascot has on
the running screen, a finished title, what got done, any estimate adjustment on offer, and a Back to
today action.

#### Scenario: Back to today

- **WHEN** the user selects Back to today
- **THEN** the timer closes

#### Scenario: The mascot matches the running screen's size

- **GIVEN** a run that just finished
- **WHEN** the finished screen renders
- **THEN** the mascot's rendered size equals the mascot's rendered size on the running screen
