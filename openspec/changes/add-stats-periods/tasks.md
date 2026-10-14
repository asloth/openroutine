## 1. Period model (slice 1)

- [ ] 1.1 Add unit tests for `StatsPeriod.range` covering a Monday-start week, a Sunday-start week, a week that crosses a year boundary, February in a leap year, and all time being unbounded, and verify they fail
- [ ] 1.2 Implement `StatsPeriod` in `app/lib/services/stats/` and verify 1.1 passes
- [ ] 1.3 Add tests for `previous()`, `next()`, and `isCurrent(now)`, then implement them

## 2. Streak split (slice 1)

- [ ] 2.1 Add a test showing the streak computed while viewing a past period still counts back from today, and verify it fails against the current single provider
- [ ] 2.2 Move the streak into its own exported function and a `currentStreakProvider`, remove it from `computeStatistics`, and verify 2.1 passes along with the existing streak tests

## 3. Providers (slice 1)

- [ ] 3.1 Add tests that `statisticsProvider` for a given period requests only that period's range from storage, and for all time requests an unbounded one
- [ ] 3.2 Turn `statisticsProvider` into an `autoDispose` family keyed by period and first day of week, remove `statsWindow`, and verify 3.1 passes
- [ ] 3.3 Run codegen, then analyze and the full test suite

## 4. Screen (slice 2)

- [ ] 4.1 Add widget tests: opens on Week, switching to Month and All time, previous and next arrows, the next arrow disabled on the current period, arrows hidden on All time, the locale-formatted label, the empty-period message, and the first-run empty state when there are no runs at all
- [ ] 4.2 Add the period strings to `app_en.arb` and `app_es.arb`, then run `gen-l10n`
- [ ] 4.3 Build the period control and label in `stats_screen.dart` with accent colors, read `firstDayOfWeekIndex` from `MaterialLocalizations`, and verify 4.1 passes
- [ ] 4.4 Point the finishing card's streak at `currentStreakProvider`

## 5. Verification

- [ ] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify there are no issues
- [ ] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes
- [ ] 5.3 Run `openspec validate add-stats-periods --type change --strict` and verify it passes
- [ ] 5.4 Install on the Pixel with `--dart-define-from-file=dart_define.json` and `adb install -r`, then check the Spanish locale starts weeks on Monday
