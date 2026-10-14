## 1. Period model (slice 1)

- [x] 1.1 Add unit tests for `StatsPeriod.range` covering a Monday-start week, a Sunday-start week, a week that crosses a year boundary, February in a leap year, and all time being unbounded, and verify they fail
- [x] 1.2 Implement `StatsPeriod` in `app/lib/services/stats/` and verify 1.1 passes
- [x] 1.3 Add tests for `previous()`, `next()`, and `isCurrent(now)`, then implement them

## 2. Streak split (slice 1)

- [x] 2.1 Add a test showing the streak computed while viewing a past period still counts back from today, and verify it fails against the current single provider
- [x] 2.2 Move the streak into its own exported function and a `streakDaysProvider`, remove it from `computeStatistics`, and verify 2.1 passes along with the existing streak tests

## 3. Providers (slice 1)

- [x] 3.1 Add tests that `statisticsProvider` for a given period requests only that period's range from storage, and for all time requests an unbounded one
- [x] 3.2 Turn `statisticsProvider` into an `autoDispose` family keyed by period (a week carries its own first day), remove `statsWindow`, and verify 3.1 passes
- [x] 3.3 Run codegen, then analyze and the full test suite

## 4. Screen (slice 2)

- [x] 4.1 Add widget tests: opens on Week, switching to Month and All time, previous and next arrows, the next arrow disabled on the current period, arrows hidden on All time, the locale-formatted label, the empty-period message, and the first-run empty state when there are no runs at all
- [x] 4.2 Add the period strings to `app_en.arb` and `app_es.arb`, then run `gen-l10n`
- [x] 4.3 Build the period control and label in `stats_screen.dart` with accent colors, read `firstDayOfWeekIndex` from `MaterialLocalizations`, and verify 4.1 passes
- [x] 4.4 Point the finishing card's streak at `streakDaysProvider` (done in slice 1: `computeStatistics` takes the streak from it, so the card needed no change)

## 5. Verification

- [x] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify there are no issues
- [x] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes
- [x] 5.3 Run `openspec validate add-stats-periods --type change --strict` and verify it passes
- [ ] 5.4 Install on the Pixel with `--dart-define-from-file=dart_define.json` and `adb install -r`, then check the Spanish locale starts weeks on Monday
