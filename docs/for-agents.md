# Editing OpenRoutine data safely

OpenRoutine stores user-owned routine data as JSON in Google Drive. Read the
published schemas before writing, preserve fields you do not recognize, and ask
the user to confirm changes before applying them.

## Find the data

Drive-connected users have this folder:

```text
OpenRoutine/
├── README.md
├── meta.json
├── routines.json
└── completions/
    └── YYYY-MM.ndjson
```

Local-only users can share an OpenRoutine export. It has the same top-level
shape as `routines.json` and can be imported back into the app.

| File | Purpose | Write model |
|---|---|---|
| `routines.json` | Routines, steps, and triggers | Full JSON document |
| `meta.json` | Schema version and sync diagnostics | App-managed; do not edit |
| `completions/YYYY-MM.ndjson` | Timer runs for one UTC month | Append-only, one JSON object per line |

## Validate before writing

The files in [`schemas/`](../schemas/) are the public contract:

- [`export.schema.json`](../schemas/export.schema.json): `routines.json` and imports
- [`routine.schema.json`](../schemas/routine.schema.json): routines and schedules
- [`step.schema.json`](../schemas/step.schema.json): routine steps
- [`trigger.schema.json`](../schemas/trigger.schema.json): triggers
- [`completion.schema.json`](../schemas/completion.schema.json): completion lines

Use UUIDv7 for every new `id`. Use ISO-8601 UTC for timestamps, for example
`2026-08-11T14:30:00Z`. Keep `schema_version` and unknown fields unchanged.

## Valid values

| Field | Values and constraints |
|---|---|
| `schedule.mode` | `scheduled`, `flexible` |
| `schedule.days[]` | `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun` |
| `schedule.start_time` | Local 24-hour `HH:MM`, or `null`; use `null` for flexible routines |
| `trigger.kind` | `manual` in schema v1 |
| `step.name` | 1-50 characters |
| `step.duration_seconds` | Positive integer, or `null` when `no_explicit_time` is `true` |
| `completion.outcome` | `completed`, `abandoned` |
| `completion.steps[].state` | `completed`, `skipped`, `overrun` |

Each step belongs to one routine through `routine_id`. Its zero-based `order`
must agree with its position in the routine's ordered `step_ids` list.

## Merge rules

OpenRoutine merges routines, steps, and triggers independently by `id` using
last-writer-wins (LWW):

1. A new ID is added.
2. For an existing ID, the record with the later `updated_at` wins.
3. Equal or older timestamps do not overwrite the current record.

Therefore, bump `updated_at` on EVERY record you change. When a step list
changes, update both the affected steps and their parent routine, including the
routine's `step_ids` and `updated_at`.

## Deletion and tombstones

Never remove a routine or step object from `routines.json`. Hard deletion can
let an offline device upload its stale copy and resurrect the object.

To delete a routine or step:

1. Set `deleted_at` to the current UTC timestamp.
2. Set `updated_at` to the same timestamp.
3. Keep the full object in its array so the tombstone reaches other clients.

Triggers do not have `deleted_at` in schema v1. Do not invent one or delete a
trigger automatically; ask the user how references should be reassigned.

## Completion rules

Completion shards are NDJSON, not JSON arrays. Each non-empty line must be one
complete object that validates against `completion.schema.json`.

- Append new records; never edit, remove, reorder, or wrap existing lines.
- Use a new UUIDv7 `id`; readers deduplicate repeated IDs.
- Choose the shard from `started_at` in UTC: `2026-08-11T...Z` belongs in
  `completions/2026-08.ndjson`.
- Do not fabricate completion history unless the user explicitly requests it.

Drive has no append operation, so OpenRoutine may rewrite a shard as the union
of local and remote records by `id`. Append-only describes record semantics,
not the transport request.

## Safe edit examples

### Rename one routine

1. Find the routine by `id`, not by name.
2. Change only `name` and `updated_at`.
3. Validate the complete document against `export.schema.json`.
4. Write the complete `routines.json` document back.

```json
{
  "name": "Short evening reset",
  "updated_at": "2026-08-11T14:30:00Z"
}
```

The snippet shows changed fields only. Do not replace the full object with it.

### Add a step

1. Create a schema-valid step with a new UUIDv7, the parent's `routine_id`, and
   matching `created_at` and `updated_at` timestamps.
2. Insert it into `steps` and assign contiguous `order` values from zero.
3. Insert its ID at the same position in the parent's `step_ids`.
4. Bump `updated_at` on the parent routine and any reordered existing steps.
5. Validate and write the full document.

### Remove a step

1. Tombstone the step by setting `deleted_at` and `updated_at` to now in UTC.
2. Remove its ID from the parent's `step_ids` and bump the routine's
   `updated_at`.
3. Reassign contiguous `order` values and bump `updated_at` on reordered steps.
4. Keep the tombstoned step in `steps`, then validate the full document.

## Final checklist

- [ ] The user approved the write.
- [ ] IDs and unknown fields were preserved.
- [ ] Every changed record has a newer UTC `updated_at`.
- [ ] Routine `step_ids` and step `order` values agree.
- [ ] Deleted routines or steps remain as tombstones.
- [ ] Completion history is append-only NDJSON.
- [ ] The complete output validates against the published schemas.
