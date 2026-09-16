## Why

A routine can belong to a moment ("After waking up"), stored as a trigger. Moments don't do anything. They were meant to fire routines from events in a later schema version, but only the `manual` kind ever existed, so today a moment is a label that groups nothing and triggers nothing. The home redesign already dropped moment groups. What actually brings a routine up is its schedule: the days and start time drive the reminder.

Keeping moments costs a picker in the routine form, a chip on routine detail, a clause in every reminder, a table, and a required field in every file on Drive, all for a label.

## What Changes

- **BREAKING (public schema).** Schema version **2.0.0**:
  - `schemas/trigger.schema.json` is deleted.
  - `trigger_id` is removed from `routine.schema.json`.
  - `triggers` is removed from `export.schema.json`.
  - Every schema's `$id` moves from `/schemas/v1/` to `/schemas/v2/`.

  This is a major bump because an older client requires `trigger_id` and `triggers`, and would reject a file without them.
- The app writes 2.0.0 and still reads every 1.x file, ignoring `trigger_id` and `triggers`, so earlier exports and Drive folders import cleanly.
- A local database migration (v7) drops the `triggers` table and each routine's `trigger_id`. Routines, steps, and history are kept.
- The Moment picker leaves the routine form, the moment chip leaves routine detail, and import previews stop counting moments.
- Reminders keep working exactly as today from each routine's days and start time and the Remind me setting. Their text no longer names a moment.

## Capabilities

### New Capabilities

- `routine-schedule` — a routine is reached through its schedule alone; no moment or trigger is stored, shown, or exported.

## Impact

**Schema and compatibility.** Files written by this build declare 2.0.0. A 1.x client can still read a 2.0.0 Drive folder, but it must not write to one; that's the existing write gate. On a device already syncing, Drive asks for the cutover approval again, so the user reconnects Drive once in Settings. Local data is untouched.

**Storage.** Drift `schemaVersion` 6 → 7 with an `onUpgrade` branch. `SchemaVersion` gains `v2_0` as current. Test fixtures that pin `1.2.0`, or a "newer than us" version, move up.

**Code.** Models (`Trigger` and `Routine.triggerId` removed, `ExportBundle`, `ImportPreview`), the storage adapters, Drive sync, the schema validator, the routine form, routine detail, the import screen, home's reminder copy, and the Drive folder README.

**i18n.** Moment and trigger strings are removed from both ARB files, and the reminder copy is simplified.

**Docs.** `docs/SPEC.md`, `DESIGN.md`, and `CONTRIBUTING.md` stop describing moments.

**Rollback.** Code rolls back cleanly, but data doesn't. A 2.0.0 Drive folder can't be written by a 1.x build, and dropped moment names aren't recoverable. Moments carried no behaviour, so nothing functional is lost.
