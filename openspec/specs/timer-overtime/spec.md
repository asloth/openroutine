# timer-overtime Specification

## Purpose
Define continuous elapsed timing, estimate-boundary presentation, and completion classification for timed steps without changing untimed behavior or persisted schemas.

## Requirements

### Requirement: Continuous elapsed timer

For a timed step, the system MUST display one continuous elapsed count-up from `0:00` until the user marks the step Done. Reaching the estimate MUST NOT change the display's time basis, introduce an overtime label or plus sign, or stop elapsed-time progression.

#### Scenario: Timed step crosses the estimate

- GIVEN a running timed step with a two-minute estimate
- WHEN elapsed time advances through `1:59`, `2:00`, and `2:01`
- THEN the displayed values MUST be `1:59`, `2:00`, and `2:01` in that order
- AND the timer MUST continue counting upward until Done

#### Scenario: Untimed step remains unchanged

- GIVEN a running untimed step
- WHEN time passes and the step is completed
- THEN the system MUST preserve the existing untimed presentation
- AND it MUST NOT apply estimate-boundary overtime behavior

### Requirement: Persistent estimate-boundary presentation

For a timed step, the system MUST turn the clock and progress treatment yellow when elapsed time equals the estimate and MUST keep them yellow while elapsed time exceeds the estimate. The system MUST NOT use an orange overtime treatment. The accessible timer value MUST continue to expose elapsed time without adding explicit overtime wording.

#### Scenario: Exact estimate boundary

- GIVEN a running timed step whose estimate is `2:00`
- WHEN elapsed time changes from `1:59` to `2:00`
- THEN the clock and progress treatment MUST turn yellow at `2:00`
- AND the accessible timer value MUST represent `2:00`

#### Scenario: Presentation after the boundary

- GIVEN a timed step whose elapsed time exceeds its estimate
- WHEN the timer advances to another elapsed value
- THEN the clock and progress treatment MUST remain yellow and MUST NOT turn orange
- AND no overtime label or plus sign MUST be presented visually or accessibly

### Requirement: Completion classification

The system MUST classify a timed step completed after its estimate as `overrun`. It MUST classify a timed step completed at or before its estimate as `completed`, and MUST NOT classify an untimed step as `overrun`. Completion JSON MUST remain valid under the existing schema without new fields, values, or schema-version changes.

#### Scenario: Completion after the estimate

- GIVEN a timed step with a `2:00` estimate and elapsed time of `2:01`
- WHEN the user marks the step Done
- THEN its completion state MUST be `overrun`
- AND its completion JSON MUST remain valid under the existing schema

#### Scenario: Completion at or before the estimate

- GIVEN a timed step whose elapsed time is less than or equal to its estimate
- WHEN the user marks the step Done
- THEN its completion state MUST be `completed`

#### Scenario: Untimed completion

- GIVEN an untimed step
- WHEN the user marks the step Done
- THEN its completion state MUST NOT be `overrun`
