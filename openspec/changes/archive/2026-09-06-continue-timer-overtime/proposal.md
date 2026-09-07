# Proposal: Continue Timer into Overtime

## Why

Display one continuous elapsed count-up from task start until Done. At the estimate, the timer becomes persistently yellow without changing its time basis; later completion uses the existing `overrun` state.

## What Changes

### In Scope
- Display elapsed time continuously (for example, `0:00` through `1:59`, `2:00`, `2:01`, and onward).
- Turn the clock and progress treatment yellow at the estimate boundary and keep both yellow thereafter, without an orange transition.
- Record `CompletionStepState.overrun` when a timed step is completed beyond its estimate.

### Out of Scope
- Overtime labels, plus signs, or other new textual semantics.
- Persistence fields, schema values, migrations, analytics, or backends.
- Changes to untimed steps, pause accounting, notifications, or auto-advance.

## Capabilities

### New Capabilities
- `timer-overtime`: Continuous elapsed timing, persistent yellow boundary presentation, and overrun classification.

### Modified Capabilities
- None; no accepted capabilities exist.

## Approach

Render the existing wall-clock-derived elapsed duration throughout the timed step; never switch display sources. Derive boundary styling from elapsed time and the estimate. Classify completion as `overrun` only when elapsed exceeds the estimate; actual and estimated durations remain the durable evidence.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `app/lib/services/timer/timer_machine.dart` | Modified | Boundary state and completion classification |
| `app/lib/screens/timer/timer_screen.dart` | Modified | Elapsed display and yellow presentation |
| `app/test/services/timer/timer_machine_test.dart` | Modified | Boundary and classification tests |
| `app/test/screens/timer/timer_screen_test.dart` | Modified | Display and color tests |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Color alone may not convey overtime accessibly | Med | Preserve accessible timer values without claiming explicit semantics |
| Boundary rounding could cause a skipped or duplicated displayed second | Med | Use one elapsed source and controlled timestamps for exact-boundary tests |
| Consumers assume all finished steps are `completed` | Low | Verify compatibility with the existing `overrun` enum |

## Rollback Plan

Revert the elapsed presentation, boundary styling, and classification changes. Stored records remain valid because there is no schema migration.

## Dependencies

- Existing wall-clock calculations, theme roles, and `overrun` schema support.

## Success Criteria

- [ ] A 2-minute step displays `0:00` through `1:59`, `2:00`, `2:01`, and onward until Done, with no `00:00` to `2:01` jump or display-mode switch.
- [ ] The clock/ring turns yellow at `2:00`, remains yellow thereafter, and never turns orange.
- [ ] No plus sign or new overtime text label is rendered.
- [ ] Completing beyond the estimate records `overrun`; completing at or before it records `completed`; untimed steps never record `overrun`.
- [ ] Completion JSON remains schema-valid without storage or schema changes.
