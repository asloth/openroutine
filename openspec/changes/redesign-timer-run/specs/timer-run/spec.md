## Purpose

Defines what the running and finished timer screens show and which actions they offer.

## ADDED Requirements

### Requirement: The running screen shows the step and its time

The running screen SHALL show the routine's name, the current step's position in the run, the mascot, the step's name, and a clock that counts up. For a step with a set time, a bar SHALL fill toward the estimate, and the clock and bar SHALL change colour at and after the estimate without showing overtime text.

#### Scenario: A timed step starts

- **WHEN** the first of three steps starts
- **THEN** the screen shows "1 of 3", the step's name, and 0:00

#### Scenario: A step passes its estimate

- **GIVEN** a two-minute step
- **WHEN** 2:01 has elapsed
- **THEN** the clock reads 2:01 in the estimate colour and the bar is full

### Requirement: The running screen offers one clear next action

The running screen SHALL offer Done — next step, or Finish on the last step, as its primary action, and Skip beneath it. Do it last SHALL appear only while the current step can still be put off. Pause and Resume SHALL remain available.

#### Scenario: Skip

- **WHEN** the user selects Skip
- **THEN** the step is recorded as skipped and the next step starts

#### Scenario: Do it last

- **WHEN** the user selects Do it last
- **THEN** the step moves to the end of the run

### Requirement: The running screen shows the rest of the run

The running screen SHALL list every step in the order it will run, marking completed and skipped steps, and SHALL show the minutes left.

#### Scenario: A step was skipped

- **GIVEN** the first step was skipped
- **WHEN** the second step is running
- **THEN** the first step appears struck through in the list

### Requirement: A halfway banner accompanies opted-in steps

For a step that opted into mid-step reminders, the running screen SHALL show a halfway banner from the midpoint of the estimate until the estimate ends.

#### Scenario: Halfway through

- **GIVEN** a ten-minute step that opted into reminders
- **WHEN** five minutes have elapsed
- **THEN** a banner says the step is halfway through with five minutes to go

### Requirement: The finished screen celebrates and returns to today

When a run finishes, the timer SHALL show the mascot cheering, a finished title, what got done, any estimate adjustment on offer, and a Back to today action.

#### Scenario: Back to today

- **WHEN** the user selects Back to today
- **THEN** the timer closes
