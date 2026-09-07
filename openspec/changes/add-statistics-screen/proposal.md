## Why

Every timer run already writes a completion log: when it started and ended, whether it finished or was abandoned, and for each step whether it was completed, skipped or overrun, how long it actually took, and what it was estimated at. None of that is ever shown back to the user.

That data answers questions this app exists to help with. How long does the morning routine *really* take, against what you thought? Which step do you skip every single time — the one that should probably be shorter, moved, or dropped? Are you finishing runs, or abandoning them? Do you actually start at the time you scheduled?

Estimate-versus-actual is the one that matters most here. Time blindness makes planning by feel unreliable, and the app is already collecting the correction — it just never shows it.

## What Changes

- Add a statistics screen, reachable from the routines-list overflow menu alongside Import and Settings.
- Add `completionsInRange` to the `StorageAdapter` interface so completions can be read across all routines, not one at a time. `DriveAdapter` delegates to its local adapter, matching how it handles every other read.
- Add a pure aggregation layer that turns a list of completion logs into the four views, with no Flutter or storage dependency, so the arithmetic is testable on its own.
- Present four views:
  - **Estimate vs actual** — total and per-step, showing where estimates run short.
  - **Completion rate and streak** — finished versus abandoned runs, and consecutive days with at least one finished run.
  - **Most-skipped steps** — which steps get skipped or deferred most often.
  - **Time-of-day** — when runs actually start.
- Add an empty state that explains what the screen will show once there is data, rather than rendering four empty charts.

## Capabilities

### New Capabilities

- `statistics` — what the app reports back about past runs, how each figure is derived, and what is shown when there is not enough data to derive it.

## Impact

**Code.** New: an aggregation service, a provider, the screen, and a route. Modified: `storage_adapter.dart` (one method), `drive_adapter.dart` (delegation), `local_adapter.dart` (the method becomes an override), `routines_list_screen.dart` (menu entry), `main.dart` (route), plus new strings in both `.arb` files.

**Storage and schema.** No schema change and no new persisted data. Everything shown is derived from completion logs that are already written. Adding a method to the storage interface is an internal API change, not a change to the public JSON contract under `schemas/`.

**Delivery.** This exceeds the 400-line review budget as one slice, so it is chained: the storage query and aggregation layer land first with their tests, then the screen and its route, then the individual views. Each phase in `tasks.md` is a review point.

**Data availability.** The device this is being built for currently has **no completion logs at all** — its data was cleared during an earlier install. The screen will show its empty state until routines are created and run. That makes the empty state part of the deliverable rather than an afterthought, and it means on-device verification of the populated views needs seeded data or several real runs.

**i18n.** All new strings go into `app_en.arb` and `app_es.arb` together.

**Rollback.** Removing the screen, route, provider and aggregation service reverts the change. The storage interface method may stay harmlessly or be reverted with them; nothing persisted changes either way.
