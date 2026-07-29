# OpenRoutine — a guide for AI agents

This is a placeholder. The full guide — written *for* agents like Claude or Codex reading a user's Drive — ships in **M5** per [`SPEC.md`](SPEC.md) §9 and §12.

It will cover:

- Where to find the data: `/OpenRoutine/` in the user's Google Drive.
- File naming and layout (`routines.json`, `meta.json`, `completions/YYYY-MM.ndjson`).
- Links to the JSON Schemas in [`schemas/`](../schemas/) that define valid shapes.
- Sync semantics: last-writer-wins per routine via `updated_at`; always bump `updated_at` when writing.
- Safe-edit patterns and example prompts.

Until then, [`SPEC.md`](SPEC.md) §9 is the authoritative reference.
