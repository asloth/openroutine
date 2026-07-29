# OpenRoutine data folder

This folder was created by the [OpenRoutine](https://github.com/asloth/openroutine) app. It holds your routines as plain JSON files that **you own** — OpenRoutine has access only to files it creates here (`drive.file` OAuth scope), nothing else in your Drive.

You (or any AI agent you've given Drive access to, like Claude or Codex) can read and edit these files directly.

## Files

- **`meta.json`** — schema version, last-writer client ID, last sync timestamp.
- **`routines.json`** — all your routines, steps, and triggers: `{ "routines": [...], "steps": [...], "triggers": [...] }`.
- **`completions/YYYY-MM.ndjson`** — one completion log per line, split by month. Append-only.

## Schema

Every file's shape is defined by the versioned JSON Schemas published at [`schemas/`](https://github.com/asloth/openroutine/tree/main/schemas) in the OpenRoutine repo. Unknown fields are ignored by older clients; do not remove fields you don't recognize.

## Safe-edit rules

1. **Always bump `updated_at`** (ISO-8601 UTC) on any routine or step you edit. Conflict resolution is last-writer-wins by `updated_at` — an edit without a fresh timestamp can be silently overwritten.
2. **Never hard-delete.** Set `deleted_at` instead. Hard deletes can resurrect on the next sync from an offline client.
3. **Completions are append-only.** Add new lines to the current month's `.ndjson` file; never rewrite existing lines. Readers dedupe by `id`.
4. **Keep `id` fields as UUIDv7** and don't reuse or reassign them across entities.

See [`docs/for-agents.md`](https://github.com/asloth/openroutine/blob/main/docs/for-agents.md) in the repo for the full agent integration guide.
