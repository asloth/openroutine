# Design: Continue Timer into Overtime

## Technical Approach

Keep `TimerState.elapsed(now)` as the single wall-clock-derived source for timed and untimed steps. Timed UI will render that elapsed duration from start through Done, derive a two-state estimate treatment (`green` before the estimate, `yellow` at and after it), and keep the progress ring full after the boundary. Completion will reuse the existing `CompletionStepState.overrun` JSON value and persisted duration fields; no provider, storage, model, schema, notification, or localization contract changes.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Render `elapsed` continuously vs. switch from remaining to overtime | One source prevents boundary jumps and preserves wall-clock/pause behavior; it changes timed display from countdown to count-up. | Render elapsed for every timed frame. Keep the existing untimed branch and “No set time” presentation unchanged. |
| Keep three estimate zones vs. collapse the internal zone model | Leaving orange reachable risks regression; removing it makes the approved presentation structural. | Use only `green`, `yellow`, and `unbounded`; return yellow when `elapsed >= estimate`. Remove the visual/live-region zone label rather than replace it with overtime text. |
| Add a color token vs. reuse the theme | A new token broadens design-system scope. `ColorScheme.tertiary` is already documented as the honey estimate-zone accent. | Apply `colorScheme.tertiary` to clock text and `CircularProgressIndicator.color` at/after the boundary; before it, preserve current theme and paused colors. Boundary yellow remains authoritative while paused. |
| Compare raw duration vs. persisted whole seconds | Sub-second comparison could serialize `overrun` with actual seconds equal to estimate. | Classify by `spent.inSeconds > durationSeconds`, matching displayed whole seconds and durable JSON evidence. Exact-boundary completion remains `completed`; untimed completion bypasses overrun. |

## Data Flow

```text
DateTime.now ──> TimerState.elapsed(now) ──> elapsed clock text
                         │
                         ├──> estimateZone(now) ──> clock/ring color
                         └──> Done ──> _finishedState ──> CompletionStep
                                                        │
                                                        └──> existing toJson/storage
```

`RoutineTimer` remains responsible only for one-second repaint notifications and persistence. `TimerState` owns boundary and completion rules. `_Running` computes one `now`/`elapsed`/zone snapshot; `_Clock` owns formatting and visual treatment. Timed clock formatting will produce the specified `0:00`, `1:59`, `2:00`, `2:01` sequence without affecting the existing zero-padded untimed/summary formatter. Flutter text semantics expose the same elapsed value; no overtime wording, plus sign, or live-region announcement is added.

## File Changes

| File | Action | Description |
|---|---|---|
| `app/lib/services/timer/timer_machine.dart` | Modify | Make yellow inclusive and persistent, eliminate orange reachability, and classify late timed Done as `overrun`. |
| `app/lib/screens/timer/timer_screen.dart` | Modify | Render timed elapsed values, remove zone labels, and color the clock/full ring yellow from the boundary. |
| `app/test/services/timer/timer_machine_test.dart` | Modify | Add boundary, persistent-zone, completion, untimed, pause, and existing-JSON contract tests. |
| `app/test/screens/timer/timer_screen_test.dart` | Modify | Add controlled-state clock, color, semantics, no-label/no-plus, and untimed regression widget tests. |

## Interfaces / Contracts

No public or persisted interface changes. `CompletionStepState.overrun`, `actual_duration_seconds`, and `estimated_duration_seconds` already exist in `completion_log.dart`, generated JSON serialization, and `schemas/completion.schema.json`. `EstimateZone` is internal and will no longer expose `orange`.

Edge behavior: elapsed is floored to whole seconds for display and classification; the exact estimate second is yellow but `completed`; subsequent displayed seconds are yellow and `overrun` when Done. Pause accounting, reset/back/postpone clock restarts, skipped outcomes, invalid non-positive estimates, and notification scheduling retain current behavior.

## Testing Strategy

Strict TDD applies: write focused failing tests first, then the minimum implementation, then refactor while green.

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Zone at `estimate-1s`, estimate, and later; Done before/at/after; untimed never overrun; paused elapsed; overrun JSON round-trip | Fixed timestamps in `timer_machine_test.dart`; assert existing keys/value `overrun` and no schema additions. |
| Widget | `1:59 -> 2:00 -> 2:01`, continuous upward display, tertiary clock/ring at and after boundary, full ring, accessible elapsed value, absence of orange/labels/`+`, unchanged untimed UI | Drive `_ControlledRoutineTimer` with controlled timestamps and inspect text, semantics, and widget colors. |
| Integration/E2E | Not available in this repository | Rely on Flutter unit/widget suites; run targeted tests, then `flutter test` and `flutter analyze --fatal-infos` from `app/`. |

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary.

## Migration / Rollout

No migration or feature flag required. Roll back the four source/test edits; existing completion records remain valid. Keep the implementation as one reviewable slice expected to remain below the 400-line budget; `auto-chain` remains available if task planning forecasts otherwise.

## Open Questions

None.
