## Why

The statistics screen still carries the neumorphic idiom and a stock `AppBar`, while the
approved "tinted paper" direction has already landed its shared widgets
(`add-tinted-surfaces`). This change moves the statistics screen to that idiom, the same
way `add-appearance-defaults`-style screen work has moved other screens one at a time.

Finishing is the number this screen exists to answer — did you actually get through the
routine, and how often — so it becomes the screen's hero, not one card among four equals.

## What Changes

- Remove the `AppBar` in favor of a `PageHeader` carrying the screen title, with a
  status-bar style set for contrast against the tinted ground.
- Turn the completion-rate section into a hero `TintedCard` in the accent's container
  pair, with a large finished-count figure, a "of N runs finished" line, the streak, and
  a `SegmentedProgress` bar.
- Lay the remaining three sections — estimate accuracy, most skipped, and start times —
  flat on the page as a `SectionLabel` plus divided rows, instead of neumorphic cards.
- Add two new strings, `statsCompletionFinished` and `statsCompletionOfTotal`, that split
  the existing `statsCompletionRate` sentence into a big number and a trailing phrase.
  `statsCompletionRate` stays, now used only for the hero's combined semantics label.
- Reserve bottom list padding for the floating nav pill another change is adding, using
  `MediaQuery.paddingOf(context).bottom`.

Nothing about *what* the screen reports changes: same four sections, same order, same
aggregation service, same empty state copy and layout.

## Capabilities

### Modified Capabilities

- `statistics` — no requirement changes. This change is presentation only; the existing
  `specs/statistics/spec.md` deltas already describe what is computed and shown, and
  none of that arithmetic moves. This delta file documents the visual requirements the
  screen now has to meet, so they're reviewable and testable the same way the
  computation ones are.

## Impact

**Code.** `app/lib/screens/stats/stats_screen.dart` only. No change to
`app/lib/services/stats/`, `app/lib/state/stats_provider.dart`, `app/lib/theme/`, or any
shared widget.

**Tests.** `app/test/screens/stats/stats_screen_test.dart` is rewritten against the new
layout: no `AppBar`, the hero card's fill and figures, the hero's combined semantics
label, segment math at a few totals, the three flat sections' dividers, the empty state,
and no overflow at 1.5x/2.0x text scale.

**Storage and schema.** None. No persisted data, no schema, no storage-adapter change.

**i18n.** Two new keys, `statsCompletionFinished` and `statsCompletionOfTotal`, added to
`app_en.arb` and `app_es.arb` together. `statsCompletionRate` is kept rather than removed,
since it still backs the hero's screen-reader sentence.

**Rollback.** Reverting `stats_screen.dart` and its test file, and dropping the two new
ARB keys, fully undoes this change. Nothing else depends on the new layout.
