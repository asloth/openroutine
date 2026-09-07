## Context

See `proposal.md` — Why, and `specs/statistics/spec.md` for the contract.

Two existing facts shape this. `StorageAdapter` exposes `getCompletions(routineId)` but no cross-routine read; `completionsInRange` exists only on `LocalAdapter`, where `DriveSync` calls it directly. And `DriveAdapter` is constructed with a `local:` adapter and delegates reads to it, so extending the interface costs one delegating method rather than a second implementation.

## Goals / Non-Goals

**Goals:**

- Keep the arithmetic pure and separately testable, so a wrong number is a unit-test failure rather than something spotted on a chart.
- Make the empty and insufficient-data paths first-class, since that is the state the screen ships in for this user.

**Non-Goals:**

- Charting libraries. The four views are expressible with layout and simple painted bars; a dependency for that is not earned.
- Per-routine filtering, date-range pickers, or export of statistics. All are plausible later; none are asked for.
- Backfilling or migrating historical data. There is none.

## Decisions

### Aggregation is a pure function of logs plus steps

The service takes `List<CompletionLog>` and the steps needed to resolve names, and returns plain result objects. No Riverpod, no Flutter, no storage.

*Rationale:* every requirement in the spec is arithmetic over records — which steps are excluded, when a streak breaks, how hours are bucketed. Testing that through a widget means constructing a database and pumping a tree to assert a number. As a pure function each rule gets a direct test, and the screen is left with nothing to get wrong but layout.

### `completionsInRange` moves onto the interface

*Alternative considered:* reaching for `LocalAdapter` directly from the statistics provider, as `DriveSync` does. Rejected because `DriveSync` is *part of* the Drive implementation and legitimately knows about local storage; a UI-facing provider is not, and doing so would make statistics silently wrong for anyone whose adapter is not the local one. Adding the method keeps the screen honest about which adapter it is talking to.

### Steps are resolved by identifier, and unresolved ones are dropped

*Rationale:* completion logs store `stepId` and are append-only, so they outlive the steps they reference. Showing a raw identifier tells the user nothing; showing a placeholder invites the question of what it was. Dropping is the only option that does not mislead, and the spec says so explicitly rather than leaving it to the implementation.

### Local time for bucketing, UTC for storage

Timestamps are stored UTC and converted to local for the hour buckets.

*Rationale:* "when do I start my routine" is a question about the user's day. A run at 07:30 local is a morning run regardless of the offset it was recorded at. This is the one place the stored representation must not be shown directly.

### Streaks count finishing, not attending

A day whose only run was abandoned breaks the streak.

*Rationale:* the alternative — counting any run — produces a number that rises while things are going badly, which is worse than not showing it. Stated in the spec so it is a decision rather than an implementation detail. This is also why the screen shows completion rate next to the streak: a streak alone is the metric most likely to feel like an accusation after it breaks.

## Risks / Trade-offs

**Statistics can read as judgement rather than information.** → The reason the empty state is specified rather than left to default, and the reason estimate accuracy is framed as a difference rather than an error rate. The app's own copy rule is that nothing should scold; these screens are where that is easiest to violate.

**Loading every completion log to compute aggregates.** → Acceptable at this scale: logs are one row per run, on-device, for a single user. If it ever stops being acceptable the fix is a date-bounded query, which `completionsInRange` already takes.

**Four views is a lot of surface for one change.** → Handled by chained delivery rather than by cutting scope: the storage and aggregation phase is reviewable on its own, then the screen, then the views. Phase boundaries in `tasks.md` are the review points.

## Migration Plan

None. No persisted data changes.

## Open Questions

None affecting the specs or the task breakdown. Visual treatment of each view is a layout decision that can be adjusted after seeing it with real data — which this device will not have until routines have been run.
