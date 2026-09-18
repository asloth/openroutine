# Redesign the Statistics screen

## Why

Statistics missed the home redesign. Today sits on warm paper with quiet
headings over white cards; Statistics still used the older `PageHeader` /
`AppSpacing` idiom and a tinted hero card, so the two destinations read as
two different apps.

The figures were also thinner than the data behind them. The finishing bar
showed a filled proportion with nothing naming the pale half. Per-step
estimates printed two raw durations — "18m / 10m" — and left you to subtract
them. Most-skipped and start-time rows carried counts with no shape to
compare against.

## What changes

- Every section takes a quiet uppercase heading on the paper, matching home's
  Anytime today.
- **Finishing** keeps its big number and gains a legend naming both halves of
  the bar: runs finished, and runs left early. The bar draws one segment per
  run up to 60, so it's countable rather than only proportional. The streak
  moves below a hairline inside the same card.
- **Estimated vs actual** keeps its headline sentence and gives each step a
  bar diverging from a centre line — warm and rightward when a step ran long,
  green and leftward when it came in under — with a signed difference in place
  of two raw durations.
- **Most skipped** puts each step on its own card with a bar scaled against
  the most-skipped step.
- **When you start** scales each hour's bar against the busiest hour and gives
  the busiest one the full colour, the rest a wash of it.

No new aggregation: every figure here already existed on `RoutineStatistics`.

## What doesn't change

The tone. The screen still reports differences rather than grades, and still
says "left early" rather than "abandoned" or "failed". The empty state still
explains what will appear instead of showing four zeroed charts.

## Colour

The diverging pair is `colorScheme.secondary` (moss) and `tertiary` (honey),
not a hardcoded green and orange. `theme/colors.dart` already describes honey
as "the 'a little longer' end of the estimate zones", and both derive from the
palette's seed hue, so they follow the accent you pick rather than fighting it.
