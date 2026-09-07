Chained delivery. Each numbered group is a review point; the suite must be green at the end of every one, not only at the end.

## 0. Preconditions

- [x] 0.1 Record the pre-change baseline by running the full suite and noting the passing count
- [x] 0.2 Confirm `completionsInRange` exists on `LocalAdapter` and is absent from `StorageAdapter`, so the interface change is additive rather than a rename

## 1. Cross-routine reads — review point

- [x] 1.1 Add `completionsInRange(DateTime from, DateTime to)` to the `StorageAdapter` interface with a doc comment explaining it is the cross-routine counterpart to `getCompletions`
- [x] 1.2 Mark `LocalAdapter.completionsInRange` as an override and add `DriveAdapter.completionsInRange` delegating to its local adapter, and verify by test that the Drive adapter returns what local returns
- [x] 1.3 Run the full suite and verify it is green before starting the next phase

## 2. Aggregation — review point

Pure functions over logs and steps. No Flutter, no storage, no providers.

- [x] 2.1 Add a failing test for estimate accuracy asserting a step whose actual exceeds its estimate is reported with the difference, then implement it and verify the test passes
- [x] 2.2 Add a failing test asserting steps with no recorded estimate are excluded and do not affect totals, then implement and verify — this is the exclusion rule most easily got wrong by treating a null estimate as zero
- [x] 2.3 Add a failing test for completion rate over finished and abandoned runs, then implement and verify
- [x] 2.4 Add a failing test asserting a day whose only run was abandoned does not extend the streak, and that a gap day ends it, then implement and verify
- [x] 2.5 Add a failing test for skipped-step counts ordered by frequency and resolved to current names, then implement and verify
- [x] 2.6 Add a failing test asserting a skipped step whose definition no longer exists is omitted rather than shown by identifier, then implement and verify
- [x] 2.7 Add a failing test asserting start times bucket by *local* hour for a log stored in UTC, then implement and verify — a UTC-bucketed result is the likely bug and is invisible in any timezone at offset zero
- [x] 2.8 Run the full suite and verify it is green before starting the next phase

## 3. Screen and route — review point

- [x] 3.1 Add a provider exposing the aggregated statistics, reading through `storageAdapterProvider` rather than reaching for the local adapter
- [x] 3.2 Add the statistics screen with its empty state only, plus a `/stats` route using the shared `appPage` transition and `state.pageKey`
- [x] 3.3 Add a statistics entry to the routines-list overflow menu alongside Import and Settings, with strings in both `.arb` files
- [x] 3.4 Add a widget test asserting the screen shows the empty-state explanation and no zeroed figures when there are no logs, and verify it passes
- [x] 3.5 Run the full suite and verify it is green before starting the next phase

## 4. The four views

- [x] 4.1 Add the estimate-versus-actual view with a widget test asserting it states it has nothing to compare when no log recorded an estimate, while the other views still render
- [x] 4.2 Add the completion-rate and streak view with a widget test over seeded logs
- [x] 4.3 Add the most-skipped-steps view with a widget test over seeded logs
- [x] 4.4 Add the time-of-day view with a widget test over seeded logs
- [x] 4.5 Verify every new user-facing string exists in both `app_en.arb` and `app_es.arb` by running `flutter gen-l10n` and confirming no untranslated messages

## 5. Verification

- [x] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes above the 0.1 baseline
- [x] 5.3 Run `openspec validate add-statistics-screen --type change --strict` and verify it passes
- [x] 5.4 Build and install on the Pixel 9a, open the screen, and confirm the empty state renders — the populated views cannot be verified on device without seeded data, which is stated rather than claimed
