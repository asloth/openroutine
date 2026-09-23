## Why

A read-only security and performance audit of `app/` found two failure paths that leave the app stuck with nothing to tell the user. Both are cheap to fix and both are reachable with data a person can produce by hand.

**A malformed date in an import file hangs the import screen.** The bundled schemas declare draft 2020-12, and `json_schema` stops validating `format` from draft 2019-09 onward unless you ask it to. So `"exported_at": "yesterday"` passes `validateExportBundle`, and then `ExportBundle.fromJson` throws a raw `FormatException` out of `ImportService.validateJsonString`. `ImportScreen._choose` catches `ImportException` and `UnsupportedSchemaVersionException` only, so the exception escapes, `_busy` is never cleared, and the screen sits on a spinner with no message. The Drive read path already survives the same data, because `DriveSync._run` catches `FormatException`.

**A second folder named "OpenRoutine" in Drive hangs every sync.** `DriveApiClient.discoverFolder` throws `DriveAmbiguousDiscovery` when the name matches more than once, which duplicating the folder inside Drive is enough to cause. The exception implements `Exception` directly rather than extending `DriveApiException`, so none of the handlers in `DriveSync._run` catch it and neither does `SyncController.syncNow`. Sync is called through `unawaited(...)`, so it becomes an unhandled async error: Settings stays on "Syncing…" forever, no failure is recorded, and nothing says what's wrong or how to fix it.

The audit also flagged two pieces of hardening in the same neighbourhood. The notification payload becomes a path segment without escaping, where the widget tap path already escapes; and an exported file name interpolates the routine name without sanitizing it.

## What Changes

- Validate `format` when checking an import against the export schema, so a bad `date-time` is reported as a schema violation instead of reaching the model.
- Translate a model parse failure inside `ImportService` into an `ImportException`, so the import screen's existing error handling covers values the schema can't express.
- Catch `DriveAmbiguousDiscovery` in `DriveSync._run` and report it as its own sync outcome, with a message that says what to do about it. Treat it as non-retryable, the way a newer remote schema is treated: no timer resolves a duplicate folder.
- Escape the routine id from a notification payload before it becomes a path segment, matching `widgetLaunchRoute`.
- Sanitize the routine name in an exported file name.

## Capabilities

### New Capabilities

- `failure-reporting` — the requirement that a failure a person can cause with their own data ends in a message they can act on, rather than a stuck screen.

## Impact

**Code.** `app/lib/services/import_export/schema_validator.dart`, `import_service.dart`, `export_service.dart`, `app/lib/services/storage/drive/drive_sync.dart`, `app/lib/state/sync_provider.dart`, `app/lib/screens/settings/settings_screen.dart`, `app/lib/main.dart`. Unit tests for validation, import, export naming, and sync; a widget test for the settings message.

**Storage and schema.** None. No file under `schemas/` changes, and nothing new is persisted. Turning on `format` validation makes the validator enforce what the schemas already declare.

**Existing users.** A file that imported before still imports: every bundle this app writes uses ISO-8601 timestamps and v7 UUIDs, which both already satisfy their declared formats. What changes is that an invalid file now fails with a message instead of a spinner.

**i18n.** Three new strings in both ARB files: the duplicate-folder status, the waiting-for-approval status, and the "Sync now" action.

**Rollback.** Reverting restores the previous behaviour on both paths. Nothing is written differently in the meantime, so there's nothing to unwind.
