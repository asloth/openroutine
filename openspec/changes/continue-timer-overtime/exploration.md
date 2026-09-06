## Exploration: continue-timer-overtime

### Current State
Timer Mode is already architected as a wall-clock-derived timer, not a decrementing tick counter. `TimerState.elapsed(now)` calculates elapsed time from `stepStartedAt`, `pausedAccumulated`, and `pausedAt`, while the Riverpod notifier's 1-second ticker only repaints the UI. For timed steps, `TimerState.remaining(now)` already goes negative after the estimate expires, and the machine intentionally does not auto-advance at zero. The code comments and tests explicitly call this overrun behavior out.

The gap is visual/product-facing: `_Clock` clamps negative remaining time to zero before formatting, so the user sees `00:00` forever once the estimate has expired instead of seeing overtime. The progress ring also clamps progress to `1.0`, so it stays visually complete. Separate estimate guidance already exists: `EstimateZone.green` through the estimate, `yellow` until 150% of the estimate, then `orange`; `_EstimateZoneLabel` renders localized semantic labels, but the ring color currently comes from the global progress-indicator theme and does not vary by zone.

Overtime duration does not need a new persistence field for ordinary completion evidence: `CompletionStep.actualDurationSeconds` and `estimatedDurationSeconds` already let readers derive extra time as `actual - estimated`, and completion schemas already admit a `steps[].state` value of `overrun`. However, the current machine never writes `CompletionStepState.overrun`; `_finishedState` always returns `completed`, even when actual time exceeds the estimate. That is a related existing inconsistency, not strictly required to show live overtime.

### Affected Areas
- `app/lib/services/timer/timer_machine.dart` — Owns elapsed/remaining/estimate-zone rules; `remaining()` already returns negative overtime, `estimateZone()` defines green/yellow/orange thresholds, and `_finishedState()` currently never records `overrun`.
- `app/lib/state/timer_provider.dart` — Owns the repaint ticker and notification scheduling; likely does not need behavioral changes for live overtime because elapsed time is already wall-clock-derived and the ticker continues while running.
- `app/lib/screens/timer/timer_screen.dart` — `_Clock` clamps negative remaining to zero and the circular progress indicator uses the global progress color; this is the primary UI integration point for showing extra minutes and any overtime visual state.
- `app/lib/l10n/app_en.arb` / `app/lib/l10n/app_es.arb` — Existing zone labels are localized; any new overtime label/copy must be added in both locales.
- `app/lib/theme/theme.dart` and `app/lib/theme/colors.dart` — Progress indicators currently use `colorScheme.secondary` (moss/green) globally; color/state changes should use theme roles rather than hand-picked screen colors.
- `app/lib/models/completion_log.dart` — Defines `CompletionStepState.overrun` and comments that overrun is a completed step that exceeded its estimate.
- `schemas/completion.schema.json` and `app/assets/schemas/completion.schema.json` — Public JSON contract already allows `completed`, `skipped`, and `overrun`; no schema expansion appears necessary for derived overtime.
- `app/lib/services/storage/local_adapter.dart` and `app/lib/services/storage/drift/tables.dart` — Completion steps are persisted as JSON inside append-only completion rows; no storage migration appears necessary if overtime remains derived.
- `app/test/services/timer/timer_machine_test.dart` — Already tests negative `remaining()` and estimate-zone thresholds; needs focused tests if completion overrun classification is corrected.
- `app/test/screens/timer/timer_screen_test.dart` — Already tests zone labels and countdown behavior; should cover post-estimate overtime display and visual/semantic state.
- `docs/SPEC.md` — States that timed steps keep counting into overrun and that `overrun` should be reachable, matching the desired product intent but not the current visible UI.

### Approaches
1. **Display overtime from existing negative remaining** — Keep the timer machine and persistence shape intact; update `_Clock` to render elapsed overtime after `remaining < Duration.zero`, with a clearly defined display format and semantics.
   - Pros: Smallest change; uses the existing wall-clock timer; no migration or schema impact; directly fixes the visible `00:00` problem.
   - Cons: Requires product decisions for format/copy and accessibility; does not by itself fix persisted `overrun` classification.
   - Effort: Low

2. **Add an explicit overtime view model/state** — Add helpers such as `isOvertime(now)` / `overtime(now)` and possibly an explicit UI-facing overtime zone, then have `_Clock` and labels consume those helpers.
   - Pros: Makes overtime semantics explicit and testable; avoids scattering negative-duration logic through widgets; creates a clean place for future product rules.
   - Cons: Slightly larger state-machine API surface; still needs UI and product decisions.
   - Effort: Medium

3. **Persist overtime as first-class data** — Add a stored overtime field or change completion state handling as part of this work.
   - Pros: Makes analytics/reporting easier if future features need direct overtime queries; can fix the existing unreachable `overrun` state.
   - Cons: A new field would expand the public schema and Drive/import/export contract unnecessarily because overtime is already derivable; larger review and migration risk.
   - Effort: High

### Recommendation
Use Approach 2, but keep persistence derived. Add explicit timer-machine helpers for live overtime (`isOvertime`/`overtime` or equivalent), use them in `_Clock`, and keep `actualDurationSeconds - estimatedDurationSeconds` as the durable source for completed runs. In the same proposal, call out the existing `overrun` persistence inconsistency as either in-scope or intentionally deferred: the schema and model already expect it, but `_finishedState()` currently prevents it from being written.

For the visual state, do not commit yet to "green becomes yellow" as the final semantic rule. The current product already uses green/yellow/orange as calm estimate guidance: green through 100%, yellow until 150%, orange after 150%. A proposal should either preserve that model and color the ring by the existing zone, or simplify to a two-state in-time/overtime model. Mixing both without deciding the thresholds would make the UI inconsistent.

### Risks
- Product semantics are under-specified: the proposal must decide whether overtime display means `+00:01`, `Over by 00:01`, count-up replacing the countdown, or another accessible format.
- Color semantics are under-specified: the current code already has green/yellow/orange zones, so changing to yellow at overtime may conflict with the existing 150% orange threshold unless the model is deliberately revised.
- Persisted completion semantics are inconsistent with docs/schema today: `overrun` exists but is never emitted. If fixed in the same change, tests and completion-log expectations must be updated; if deferred, the proposal should say so.
- Widget tests that pump real time can be fragile around exact second boundaries; new tests should use controlled `TimerState` where possible, as the existing zone-label test does.
- OpenSpec CLI was not available in this environment (`openspec: command not found`), so the artifact was written to the authorized path without CLI status/instructions validation.

### Ready for Proposal
Yes — the proposal should frame this as a focused Timer Mode UI/state clarification: show live overtime after a timed step estimate expires, preserve wall-clock correctness and existing storage contracts, and ask the user to decide the overtime display format plus whether the existing green/yellow/orange estimate-zone model should remain or be simplified. It should also explicitly decide whether fixing persisted `CompletionStepState.overrun` is included in this change or split into a follow-up.
