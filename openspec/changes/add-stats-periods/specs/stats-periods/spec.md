## ADDED Requirements

### Requirement: Period selection

The statistics screen MUST offer three periods: Week, Month, and All time. It MUST open on the current week. The finishing, estimate, skipped-steps, and start-times figures MUST count only runs that started inside the selected period, using local calendar days.

#### Scenario: Opening the screen

- GIVEN finished runs this week and last week
- WHEN you open the statistics screen
- THEN Week MUST be selected
- AND the figures MUST count only this week's runs

#### Scenario: All time

- GIVEN runs from more than a year ago and from this week
- WHEN you select All time
- THEN the figures MUST include both

### Requirement: Navigating past periods

For Week and Month, the screen MUST provide controls that step to the previous and next period and MUST show a label for the period it's displaying. Stepping past the current period MUST NOT be possible. All time MUST NOT show the controls.

#### Scenario: Stepping back a week

- GIVEN Week is selected on the current week
- WHEN you select the previous-period control
- THEN the figures MUST count only last week's runs
- AND the label MUST name last week's dates

#### Scenario: Can't go past now

- GIVEN the current week or month is displayed
- THEN the next-period control MUST be disabled

### Requirement: Locale week start

A week MUST start on the first day of the week for the phone's locale.

#### Scenario: Monday-first locale

- GIVEN a locale whose week starts on Monday
- WHEN a run started on Sunday
- THEN it MUST count toward the week that began the previous Monday

#### Scenario: Sunday-first locale

- GIVEN a locale whose week starts on Sunday
- WHEN a run started on Sunday
- THEN it MUST count toward the week that begins that Sunday

### Requirement: Streak is independent of the period

The current streak MUST count back from today whichever period is selected.

#### Scenario: Viewing a past week

- GIVEN a five-day streak ending today
- WHEN you view a week from last month
- THEN the streak MUST still read five days

### Requirement: Empty period

When the selected period has no runs but other runs exist, the screen MUST keep the period control visible and MUST show a short message instead of zeroed figures. When no runs exist at all, the screen MUST show the existing first-run empty state.

#### Scenario: A quiet week

- GIVEN runs exist only in earlier weeks
- WHEN the current week is displayed
- THEN a message that nothing ran this week MUST appear
- AND the period control MUST remain usable
