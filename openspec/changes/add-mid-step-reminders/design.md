## Context

See `proposal.md` — Why.

`NotificationService` already schedules one notification per running step, at the estimate boundary, by handing a wall-clock time to the OS rather than keeping a timer alive in-process (`services/notifications/notification_service.dart`). It reuses a single `stepEndNotificationId` because only one step is ever pending at a time, so scheduling a new one implicitly replaces a stale one. The timer's own state is recomputed from timestamps, never held.

`RoutineStep` is a plain freezed data container that matches `schemas/step.schema.json` field for field. `isCore` established the shape an additive per-step boolean takes here: `@Default(false)` on the model, a defaulted `BoolColumn` on the drift table, an `onUpgrade` branch, an optional non-required property in both schema files, and a schema-version bump. This change follows that precedent deliberately rather than inventing a second shape.

## Goals / Non-Goals

**Goals:**

- Interrupt during a step the user chose to be interrupted during, early enough to act on.
- Keep the interruption survivable across process death, like the existing step-end nudge.
- Keep every file written before 1.2 readable, and keep files written at 1.2 readable by anything that ignores unknown properties.

**Non-Goals:**

- Configurable percentages. 50% and 80% are fixed. A settings screen for two numbers costs more than it returns, and every value the user could pick is a value we would then have to keep meaningful across estimate changes.
- Reminding during a step with no explicit time. There is no denominator, so there is no "partway".
- Changing anything about the step-end notification. It stays silent and stays on its own channel.

## Decisions

### The flag lives on the step, not on the routine or in settings

`remind_during` is per-step because the property being expressed is per-step: *this activity* is one people drift out of. A routine-level or app-level switch would force the reading step and the showering step to agree.

*Alternative considered:* a global "nudge me during long steps" setting keyed off duration alone. Rejected — duration does not predict drift. A twenty-minute deliberate read and a twenty-minute tidy have the same estimate and opposite needs.

### The stored default is false; "on for new steps" is a form behaviour

The model default stays `@Default(false)`. Existing steps and imported files therefore stay silent, which is what an additive field must guarantee. Turning the toggle on for *newly created* steps is a default in the step form's initial state, not a change to the model or the schema.

*Rationale:* these are two different questions that a single default would conflate — "what does an absent value mean?" (false, forever, for compatibility) and "what do we suggest to someone creating a step?" (on, because the feature is worth discovering). Encoding the second in the model would silently switch the feature on for every step that already exists.

### A two-minute floor, checked at schedule time

A step estimated under 120 seconds schedules neither nudge. At 90 seconds the 50% and 80% marks are 45 and 72 seconds apart from each other and from the end — three alerts inside a minute and a half, which is not a reminder, it is a nuisance.

The floor is evaluated when the step starts, against the estimate in force at that moment, so a step re-estimated by the calibration prompt gets the new answer on its next run without any stored state needing to change.

### Its own notification channel, because Android channels are immutable

The mid-step nudge is sound-and-vibration; the step-end nudge is deliberately neither. Android will not let an existing channel's importance or sound be changed after creation, which is why the existing channel id already carries a `_v1` suffix. A separate channel id therefore is not a preference — it is the only way to have both behaviours, and it also lets the user silence mid-step nudges in system settings without losing the boundary marker.

### Two scheduled OS alarms per step, cancelled on every step transition

Each nudge is a distinct notification id, scheduled at step start alongside the existing step-end alarm and cancelled whenever the step ends, is skipped, is deferred, or the run is abandoned.

*Alternative considered:* one in-process timer firing both. Rejected for the reason the step-end nudge was moved to the OS in the first place: an in-process timer dies with the process, and this app's whole notification design assumes the process will not survive.

## Data flow — scheduling and cancellation

Step starts (timer machine)
→ read `step.remindDuring`, `step.durationSeconds`
→ if `remindDuring` and `durationSeconds != null` and `durationSeconds >= 120`:
  → schedule alarm A at `startedAt + 0.5 × duration` (mid-step channel, sound + vibration)
  → schedule alarm B at `startedAt + 0.8 × duration` (same channel)
→ schedule the existing step-end alarm at `startedAt + duration` (boundary channel, silent) — unchanged

Step ends / skipped / deferred / run abandoned / app cancels reminders
→ cancel A and B by id, then the step-end alarm — as today

Pause
→ cancel A and B; resume reschedules both from the recomputed remaining time, because the alarms are absolute wall-clock times and a paused step's marks have moved.

## Data flow — migration and import

Existing install (drift v5) opens
→ `onUpgrade(from: 5, to: 6)` → `addColumn(routineSteps, routineSteps.remindDuring)`
→ every existing row reads back `false` from the column default; no row is rewritten.

Import of a 1.0 or 1.1 bundle
→ `SchemaVersion.parseSupported` accepts it as before
→ step JSON has no `remind_during` → generated `fromJson` reads `json['remind_during'] as bool? ?? false`
→ step is stored with the reminder off, exactly as it behaved in the writing version.

Import of a 1.2 bundle into a 1.2 install
→ accepted; `remind_during` round-trips.

Import of a 1.2 bundle into a pre-1.2 build
→ `parseSupported` throws `UnsupportedSchemaVersionException(isNewer: true)` → the import screen shows the "created by a newer version" message and writes nothing.

## Risks / Trade-offs

**Two extra alarms per step multiplies the scheduling surface.** → Each is an independent id that is cancelled on every path that ends a step, and the existing single-id design gets no help from us here: with three ids in flight, a missed cancellation is now visible as a notification firing during the *next* step rather than being harmlessly overwritten. The cancellation paths are enumerated above and each needs its own test.

**Sound and vibration are a bigger interruption than anything the app currently does.** → Deliberate, and the reason the flag is opt-in per step rather than on everywhere. The mitigation that matters is the separate channel: a user who finds it too much can mute it at the OS level without losing the quiet boundary nudge.

**`parseSupported`'s accept/reject arithmetic gets a third accepted version.** → It was already hardcoded around "1.1 must be exactly 1.1.0", and adding 1.2 the same way is the third copy of one idea. Rewritten so the accepted set is stated once and the `isNewer` classification is derived rather than re-hardcoded; the import screen rethrows anything it cannot classify as newer, so getting that boolean wrong turns a handled error into an unhandled one. It is tested per version.

**The two-minute floor is a number chosen by judgement.** → Stated in the spec as a requirement rather than buried as a constant, so it can be argued with rather than discovered.

## Migration Plan

Forward: drift v5 → v6 adds one defaulted column on open. Nothing else runs.

Backward: see `proposal.md` — Rollback. No down-migration is written, because the reverted build ignores the extra column and the only data at stake defaults to the value the reverted build assumes.
