# Tasks

- [x] Give every section a quiet heading on the paper.
- [x] Rebuild Finishing as a white card: big number, one segment per run,
      a legend naming both halves, and the streak under a hairline.
- [x] Add `statsCompletionFinishedLegend` and `statsCompletionLeftEarly` to
      both ARB files.
- [x] Give `SegmentedProgress` a 2px gap tier past 24 segments.
- [x] Raise the segment cap from 20 to 60.
- [x] Replace the per-step "actual / estimated" pair with a diverging bar and
      a signed difference.
- [x] Put each most-skipped step on its own card with a scaled bar.
- [x] Scale start-time bars against the busiest hour and tint the busiest one
      full strength.
- [x] Update the four screen tests that asserted the old design, keeping each
      one's intent.
- [x] Cover the under-estimate direction, which nothing tested before.
- [x] `flutter analyze --fatal-infos` clean, full suite green.

## Second pass — findings over figures

- [x] Give each section a headline chosen from the data, with the evidence
      behind a disclosure link.
- [x] Add `RoutineStatistics.dayParts` and `dayPartOf`, evening owning the
      small hours.
- [x] Replace the segmented bar with ten dots, clamped so rounding can never
      claim a clean sweep or a blank.
- [x] Add `_around` so a value can be styled inside a translated sentence.
- [x] Retire the strings this design drops from both ARB files.
- [x] Rework the screen tests: headlines at each threshold, both rounding
      clamps, the evening headline, and the detail behind each link.
