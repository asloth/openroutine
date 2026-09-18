# Redesign the Statistics screen

## Why

Statistics missed the home redesign, and it reported numbers instead of
findings. Four charts asked you to work out what they meant: a filled bar with
nothing naming its pale half, per-step estimates printed as "18m / 10m" for
you to subtract, and a bar per hour of the day with no summary over it.

Knowing you start at 07:00 is not the same as knowing mornings are when you
actually start.

## What changes

Each section becomes a card that leads with the finding in a sentence, with
the evidence one tap behind it.

- **Finishing** says which way your runs go, shows the rate as ten dots you
  can count, and keeps the streak under a hairline.
- **Estimated vs actual** says whether things take longer than you plan and
  names the step furthest off. "Show every step" opens the per-step bars.
- **Most skipped** names the step you skip most and suggests shortening it.
  "Show the rest" opens the others.
- **When you start** answers with the part of the day, with three bars behind
  it. "Show it by hour" opens the hourly detail.

The evidence, when opened, is the chart work each section already had: bars
diverging from a centre line for estimates, scaled track bars for skipped
steps, one bar per hour for start times.

## What doesn't change

The tone. The screen still reports differences rather than grades, and the
empty state still explains what will appear instead of showing four zeroed
charts.

## New aggregation

One addition: `RoutineStatistics.dayParts` folds the hourly buckets into
morning, afternoon and evening. Derived from `startTimes` rather than stored,
so there is no second field to keep in step and no change to the constructor.

## Colour

The diverging pair is fixed to the palette's moss and honey rather than
`colorScheme.secondary` and `tertiary`. Those sit at fixed hue offsets from
the accent, so on a blue accent they come out plum and navy — colours that say
nothing about a step running long or short.
