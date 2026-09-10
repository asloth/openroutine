## MODIFIED Requirements

### Requirement: The statistics screen renders as a tinted-paper surface

The statistics screen SHALL render without a stock `AppBar`, using `PageHeader` for its
title and a status-bar style that keeps status-bar icons legible against the tinted
ground in both themes. Finishing SHALL render as a single hero surface using the
accent's routine-card container pair, showing the finished-run count, the total-run
phrase, the current streak, and a segmented progress indicator. Estimate accuracy, most
skipped, and start times SHALL each render as a section label over rows laid flat on the
page, separated by a 1-logical-pixel divider between rows and no divider after the last
row.

This requirement governs presentation only. Every requirement below this line in this
capability — what is computed, from which logs, and what is withheld when there isn't
enough data — is unchanged by it.

#### Scenario: The hero renders in the accent's container colors

- **GIVEN** the statistics screen has completion data to show
- **WHEN** the hero finishing card renders
- **THEN** its fill and on-fill colors are `context.routineCardColors.fill` and `.onFill`

#### Scenario: The hero exposes one combined semantics announcement

- **GIVEN** the hero finishing card is showing a finished count, a total, and a streak
- **WHEN** its semantics are inspected
- **THEN** exactly one semantics node on the card carries a label combining the
  completion sentence and the streak sentence
- **AND** the card's visible text is excluded from the semantics tree, so a screen
  reader does not also announce it as separate fragments

#### Scenario: Flat sections divide rows without bracketing them in a card

- **GIVEN** the most-skipped-steps section has more than one row to show
- **WHEN** it renders
- **THEN** a divider appears between each pair of adjacent rows
- **AND** no divider appears after the last row

#### Scenario: The empty state is unaffected by the restyle

- **GIVEN** there are no completion logs
- **WHEN** the statistics screen renders
- **THEN** it shows the same empty-state heading, body copy, and layout as before this
  change

#### Scenario: The screen tolerates large text scale

- **GIVEN** the statistics screen has completion data to show
- **WHEN** the platform text scale factor is 1.5 or 2.0
- **THEN** every section renders without an overflow error
