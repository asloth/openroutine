Single review slice — the diff stays inside the 400-line budget.

## 0. Preconditions

- [x] 0.1 Confirm `git log --oneline -1` is at or after `399bc94` (tinted-surfaces
      foundation merged) and run codegen before touching anything
- [x] 0.2 Record the pre-change baseline by running the full suite and noting the
      passing count

## 1. Strings

- [x] 1.1 Add `statsCompletionFinished` and `statsCompletionOfTotal` to `app_en.arb`
      with descriptions and placeholders, and to `app_es.arb`, then run
      `flutter gen-l10n`

## 2. Tests first

- [x] 2.1 Rewrite `app/test/screens/stats/stats_screen_test.dart` against the new
      layout: no `AppBar`; the hero uses `routineCardColors.fill`/`onFill` and shows
      the finished count and "of N runs finished"; the hero exposes one semantics
      node carrying the full completion sentence plus the streak; segment math at
      total 0 (guarded), 5, and 40; the three flat sections render dividers between
      rows only, none after the last; the empty state keeps its copy and layout; no
      overflow at 1.5x and 2.0x text scale; Spanish strings render in an `es` locale
      test
- [x] 2.2 Run the suite and watch the rewritten tests fail against the current
      screen

## 3. Implementation

- [x] 3.1 Replace the `AppBar` with `PageHeader` plus `SafeArea(bottom: false)` and
      an `AnnotatedRegion<SystemUiOverlayStyle>` for status-bar contrast
- [x] 3.2 Build the hero finishing card: `TintedCard` (`AppRadius.hero`, padding
      22/24/24/24, `routineCardColors.fill`/`onFill`), its label, baseline row,
      streak line, `SegmentedProgress`, and the combined semantics label with the
      visible text excluded from the semantics tree
- [x] 3.3 Rebuild estimate accuracy, most skipped, and start times as
      `SectionLabel` plus flat 44px rows with 1px `outlineVariant` dividers, 8px
      inset, keeping each section's existing data logic
- [x] 3.4 Restyle the start-time bars to 8px tall, radius 4, track
      `surfaceContainer`, fill `primary`, with a 44px-wide tabular hour label
- [x] 3.5 Add bottom list padding of `MediaQuery.paddingOf(context).bottom + 32`
- [x] 3.6 Run the rewritten tests and verify they pass

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/`
      and verify no issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the
      full suite passes above the 0.2 baseline
- [x] 4.3 Format only the files touched by this change
- [x] 4.4 Run `openspec validate restyle-statistics --type change --strict` and
      verify it passes
