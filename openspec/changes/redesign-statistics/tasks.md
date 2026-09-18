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
