# Statistics

## MODIFIED Requirements

### Requirement: The finishing bar names both of its halves

The completion bar SHALL render one segment per run up to 60 runs, and SHALL
carry a legend naming the filled segments as runs finished and the pale
segments as runs left early.

Past 60 runs the segment count SHALL cap at 60 and the filled count SHALL be
scaled to the same proportion.

#### Scenario: Forty runs, twenty-six finished
- **WHEN** the completion rate is 26 finished and 14 left early
- **THEN** the bar draws 40 segments with 26 filled
- **AND** the legend reads "26 finished" and "14 left early"

#### Scenario: A hundred runs
- **WHEN** the completion rate is 60 finished and 40 left early
- **THEN** the bar draws 60 segments with 36 filled

### Requirement: A per-step estimate reads as a signed difference

Each step row SHALL show the difference between actual and estimated time as
a single signed value, and SHALL NOT show the two durations separately.

The sign SHALL use U+2212 for a step that came in under.

A bar SHALL grow from a centre line: rightward in the tertiary colour when the
step ran long, leftward in the secondary colour when it came in under, scaled
against the largest difference shown.

#### Scenario: A step that ran long
- **WHEN** a step estimated at 10 minutes took 18
- **THEN** the row reads "+8m"

#### Scenario: A step that came in under
- **WHEN** a step estimated at 10 minutes took 7
- **THEN** the row reads "−3m"

### Requirement: The screen reports, it does not grade

Copy SHALL describe differences rather than scores, and SHALL NOT name a run
that ended early as failed or abandoned.

#### Scenario: Runs that ended early
- **WHEN** the legend names the pale half of the finishing bar
- **THEN** it reads "left early"
