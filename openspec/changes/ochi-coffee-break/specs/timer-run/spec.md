## ADDED Requirements

### Requirement: The mascot takes a coffee break on long steps

While a step planned for more than 5 minutes runs, the running screen's mascot SHALL hold a cup of
coffee and take a sip about every 45 seconds. A step of 5 minutes or less, or one with no planned
time, SHALL get no coffee. Pausing SHALL put the cup down and stop the sips until the run resumes.

#### Scenario: A long step gets coffee

- **GIVEN** a step planned for 6 minutes
- **WHEN** it starts running
- **THEN** the mascot holds a coffee

#### Scenario: A 5-minute step gets none

- **GIVEN** a step planned for exactly 5 minutes
- **WHEN** it starts running
- **THEN** the mascot holds no coffee

#### Scenario: The mascot sips now and then

- **GIVEN** a long step running
- **WHEN** 45 seconds pass
- **THEN** the mascot takes a sip, and again 45 seconds later

#### Scenario: A short step never sips

- **GIVEN** a step planned for 1 minute
- **WHEN** 45 seconds pass
- **THEN** the mascot takes no sip

#### Scenario: Paused, the cup goes down

- **GIVEN** a long step running
- **WHEN** the user pauses the run
- **THEN** the mascot puts the coffee down and takes no sips while paused

#### Scenario: Moving on to a short step ends the break

- **GIVEN** a long step running
- **WHEN** the user marks it done and the next step is short
- **THEN** the mascot puts the coffee down and stops sipping
