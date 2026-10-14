## Why

The statistics screen reports the last 365 days as a single block. You can't tell how last week went, or compare this month with the one before, because every run lands in the same total. People want to look back at a specific week or month.

## What Changes

- Add a period control to the statistics screen with three options: Week, Month, and All time. It opens on the current week.
- Add ‹ and › arrows that step back and forward through past weeks or months. You can't step past the current period. All time has no arrows.
- Label the selected period, for example "Oct 6 – 12" or "September 2026". Dates are formatted for the phone's locale.
- Start weeks on the phone locale's first day of the week, as `MaterialLocalizations.firstDayOfWeekIndex` reports it. There's no setting.
- Filter the finishing, estimate, skipped-steps, and start-times cards by the selected period.
- Keep the current streak independent of the period. It always counts back from today, and the streak query no longer depends on which logs the period returns.
- When a period has no runs, keep the period control on screen and show a short "nothing ran" message instead of zeroed charts. The existing first-run empty state stays for someone who has never run a routine.
- Make All time unbounded. It replaces the fixed 365-day `statsWindow`.

## Capabilities

### New capabilities

- `stats-periods`: selecting and navigating the time period the statistics screen reports on, and how the streak and empty states behave across periods.

## Impact

**Code.** `app/lib/state/stats_provider.dart` (a family keyed by period, with a separate streak provider), `app/lib/services/stats/` (a pure `StatsPeriod` value that resolves to a local date range, and the streak split out of `computeStatistics`), `app/lib/screens/stats/stats_screen.dart` (the period control, the label, and the per-period empty state). Unit tests for period ranges and the streak, and widget tests for the screen.

**Storage and schema.** None. `completionsInRange` already takes any range, and the Drive adapter delegates to the local one. No file under `schemas/` changes, and there's no Drift migration.

**Performance.** All time reads every completion log. Logs are small and local, and the screen already reads a year of them, so this is acceptable for now. If history grows large, aggregation can move into the query later.

**i18n.** New strings for the three period names, the arrows' semantic labels, and the empty-period message, in both `app_en.arb` and `app_es.arb`. Date labels use `intl` with the active locale and don't need ARB strings.

**Rollback.** Reverting restores the single 365-day report. Nothing is persisted, so there's nothing to unwind.

**Delivery.** Two slices: the period model, streak split, and providers first, then the screen.
