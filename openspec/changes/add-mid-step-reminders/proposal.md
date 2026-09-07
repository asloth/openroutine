## Why

A step's only notification fires when its estimate runs out. By then the useful moment has passed: someone who drifted away from a ten-minute shower learns about it at minute ten, when the routine is already behind. Nothing tells them while there is still time to come back.

That step-end nudge is also deliberately silent — `playSound: false`, `enableVibration: false` on the `gentle_estimate_boundary_v1` channel — because it marks a boundary rather than summoning anyone. A mid-step nudge has the opposite job. It exists to interrupt someone who has lost the thread, and a silent interruption does not interrupt.

Not every step wants this. Reading and stretching want to be left alone; showering and tidying are the ones people vanish into. So it is per-step, and the step has to remember it.

## What Changes

- Add a persisted per-step `remind_during` flag: whether this step nudges the user partway through its estimate.
- Fire two nudges per opted-in step, at 50% and 80% of its estimate, with sound and vibration, on their own notification channel.
- Fire neither nudge for a step whose estimate is under two minutes, nor for a step with no explicit time — there is no "partway" worth interrupting inside 120 seconds.
- Turn the toggle on by default in the step form for newly created steps, while the *stored* and *imported* default stays off.

## Capabilities

### New Capabilities

- `mid-step-reminders` — when the app interrupts a user during a step rather than at its boundary, which steps opt in, and what such an interruption is allowed to do.

## Impact

**Public API — this is a schema change.** `schemas/step.schema.json` and its bundled twin `app/assets/schemas/step.schema.json` gain a `remind_during` boolean. `schemas/` is the documented public contract for agent integrations (docs/SPEC.md §13), so this is a public API change and is called out as one, not treated as an internal storage detail.

The change is **additive**. The property carries `"default": false` and is deliberately **absent from `required`**, so every file written against 1.0 or 1.1 still validates unmodified. The export schema version moves 1.1.0 → **1.2.0**, and `SchemaVersion.parseSupported` accepts 1.2.0 alongside the versions it already read. An integration that has never heard of `remind_during` keeps working unchanged; one that writes it has it honoured.

**Storage.** Drift schema 5 → 6: one additive `BoolColumn` on `routine_steps` defaulting to false, with its own `onUpgrade` branch. No table is rebuilt and no existing row is rewritten.

**Existing users.** Silent. Every existing step migrates to `remind_during = false` and behaves exactly as it does today. The feature appears only on steps the user opts in, or on steps created after the form slice lands.

**Drive sync.** The cutover approval is pinned to `SchemaVersion.currentValue`, so an install that syncs to Drive must re-approve at 1.2.0 before it pushes again. That is the existing designed response to a version bump, not new work, but it is a visible consequence of shipping this.

**i18n.** None in this slice. Later slices add the notification channel name and description and the step-form toggle label to `app_en.arb` and `app_es.arb` together.

**Rollback.** Reverting the code is safe and needs no down-migration.

- A reverted build reads a v6 database correctly: SQLite keeps the extra column, drift ignores a column its table definitions no longer declare, and every other value is untouched. The one asymmetry is that the database's `user_version` is then ahead of the build's `schemaVersion`; drift does not downgrade, so if that ever matters the recovery is to re-apply this change rather than to unwind the database.
- Files exported at 1.2.0 are refused by a reverted build as "newer". That path already exists and is already tested: the import screen says so in words and refuses *before* touching local data. Nothing is lost, because `remind_during` is the only field at stake and its absence means false.
- The schema files revert cleanly: removing an optional, non-required property cannot invalidate a document that was valid with it.
