## Purpose

Defines what the app reports back to the user about their past runs, and how each figure is derived from the completion logs already being recorded. It exists because these numbers are read as judgements about the person, not just summaries of data — so the capability specifies not only what is computed but what is withheld when there is too little data to say anything honest.

## ADDED Requirements

### Requirement: Statistics are derived, never separately stored

Every reported figure SHALL be derived from completion logs at the time it is displayed. The app SHALL NOT persist a computed statistic, because a stored aggregate can disagree with the records it summarises once logs are imported, synced, or arrive out of order.

#### Scenario: Completion logs are imported after statistics were viewed

- **GIVEN** statistics have been displayed
- **WHEN** further completion logs are imported
- **THEN** the statistics reflect the imported logs when next displayed

### Requirement: Estimate accuracy is reported against recorded estimates

For steps that recorded both an actual and an estimated duration, the app SHALL report how actual time compares with estimated time, in total and per step.

Steps without a recorded estimate SHALL be excluded from this comparison rather than counted as zero, because an absent estimate is not an estimate of nothing.

#### Scenario: A step took longer than estimated

- **GIVEN** a completed step whose actual duration exceeds its estimate
- **WHEN** estimate accuracy is reported
- **THEN** that step is shown as taking longer than estimated, by the difference between the two

#### Scenario: A step recorded no estimate

- **GIVEN** a completed step with no recorded estimate
- **WHEN** estimate accuracy is reported
- **THEN** that step is excluded from the comparison
- **AND** it does not affect the totals

### Requirement: Completion rate counts finished runs against abandoned ones

The app SHALL report the proportion of runs that finished versus those abandoned, and the current streak of consecutive days containing at least one finished run.

A day with no run at all SHALL end a streak. A day containing only abandoned runs SHALL also end it, because the streak counts finishing, not attending.

#### Scenario: Consecutive days each contain a finished run

- **GIVEN** finished runs on each of several consecutive days
- **WHEN** the streak is reported
- **THEN** it counts those consecutive days

#### Scenario: A day contains only an abandoned run

- **GIVEN** a day whose only run was abandoned
- **WHEN** the streak is reported
- **THEN** that day does not extend the streak

### Requirement: Skipped steps are reported by frequency

The app SHALL report which steps were most often skipped, counted across runs and identified by the step's current name.

A step that no longer exists SHALL be omitted rather than shown by identifier, because an identifier tells the user nothing.

#### Scenario: A step is skipped across several runs

- **WHEN** skipped steps are reported
- **THEN** steps appear ordered by how often they were skipped
- **AND** each is identified by its name

#### Scenario: A skipped step has since been deleted

- **GIVEN** completion logs referencing a step that no longer exists
- **WHEN** skipped steps are reported
- **THEN** that step is omitted

### Requirement: Start times are reported by time of day

The app SHALL report when runs actually started, grouped by hour of the day, in the user's local time rather than the stored timezone.

#### Scenario: Runs started at various times

- **WHEN** start times are reported
- **THEN** runs are grouped by the local hour in which each started

### Requirement: Insufficient data is stated, not implied by empty charts

When there are no completion logs, the app SHALL explain what the screen will show once runs have been recorded, instead of rendering empty or zeroed figures.

An empty chart reads as a score of zero, which is a judgement the data does not support.

#### Scenario: No runs have been recorded

- **WHEN** the statistics screen is opened with no completion logs
- **THEN** it explains what will appear once runs are recorded
- **AND** it does not display zeroed figures or empty charts

#### Scenario: Runs exist but none recorded an estimate

- **GIVEN** completion logs exist but none recorded a step estimate
- **WHEN** the statistics screen is opened
- **THEN** the estimate comparison states it has nothing to compare
- **AND** the other reports are still shown
