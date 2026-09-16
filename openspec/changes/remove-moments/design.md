## Context

See `proposal.md`. `SchemaVersion.parseSupported` gates reading, and the Drive write gate refuses to write a folder whose declared version is newer than the build's. The Drive cutover approval records the target schema version, so changing `SchemaVersion.currentValue` requires a fresh approval.

## Decisions

### A major bump, not a deprecation

The alternative was to stop using moments but keep writing `trigger_id: null` and `triggers: []`, so no version bump would be needed. The user chose a clean removal. Removing required fields is breaking under `docs/SPEC.md` §4, so the version becomes 2.0.0.

### 2.0.0 reads 1.x

Every 1.x file is a 2.0.0 file plus moments. The models ignore unknown keys, so reading 1.x needs no conversion: parse, drop the extra keys, and the next write declares 2.0.0. `parseSupported` accepts major 1 as before and adds 2.0.0. Anything above 2.0.0 is newer and read-only, as today.

### The database drops the column and the table

Drift's `TableMigration` rebuilds `routines` without `trigger_id`, copying every other column, and then `triggers` is dropped. Rebuilding is needed because SQLite can't drop a column that has a foreign key. The migration test seeds a v6 database with a routine linked to a trigger and checks that the routine, its steps, and its logs survive.

### Reminder copy

`reminderBodyWithTrigger` goes away. The body is the existing "starts in N min" or "starts now" line under the routine's name as the title.
