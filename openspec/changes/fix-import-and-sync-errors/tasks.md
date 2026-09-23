## 1. Import validation

- [x] 1.1 Add a unit test importing a bundle whose `exported_at` is `"yesterday"`, asserting it throws `ImportException` with `schemaViolation`, and verify it fails with a raw `FormatException`
- [x] 1.2 Pass `validateFormats: true` to `_exportSchema.validate` in `SchemaValidator.validateExportBundle`, and verify 1.1 passes
- [x] 1.2a Override the `uuid` format with a check that accepts v7, because json_schema's own regex stops at version 5 and rejects every id this app writes, and add tests pinning both the acceptance and the rejection
- [x] 1.3 Add a unit test asserting a bundle produced by `ExportService` still validates, and verify it passes
- [x] 1.4 Add a unit test covering a value that passes the schema but defeats the models, asserting `ImportException`, and verify it fails
- [x] 1.5 Wrap `ExportBundle.fromJson` in `ImportService.validateJsonString`, mapping `FormatException` and `ArgumentError` to `ImportException(schemaViolation)`, and verify 1.4 passes

## 2. Ambiguous Drive folder

- [x] 2.1 Add a test using the fake Drive client with two folders named `OpenRoutine`, asserting `sync()` returns `SyncOutcome.ambiguousFolder`, and verify it fails with an uncaught `DriveAmbiguousDiscovery`
- [x] 2.2 Add `SyncOutcome.ambiguousFolder`, catch `DriveAmbiguousDiscovery` in `DriveSync._run`, record it through `recordUnwritableRemote`, and verify 2.1 passes
- [x] 2.3 Add a test asserting the run records a failure the queue reports and schedules no retry, and verify it passes
- [x] 2.4 Add `SyncStatus.ambiguousFolder`, map the outcome in `SyncController.syncNow` without scheduling a retry, and verify the analyzer reports no unhandled switch case
- [x] 2.5 Add `syncStatusAmbiguousFolder` to `app_en.arb` and `app_es.arb`, naming the duplicate folder as the cause and removing it as the fix
- [x] 2.6 Add a widget test asserting Settings shows that message for the new status, and verify it passes

## 3. Escaping and sanitizing

- [x] 3.1 Add a test asserting a notification payload containing a path separator routes to an escaped segment, and verify it fails
- [x] 3.2 Escape the payload with `Uri.encodeComponent` where the route is built in `main.dart`, and verify 3.1 passes
- [x] 3.3 Add a test asserting an exported file name drops characters a file name can't carry while keeping the readable part, and verify it fails
- [x] 3.4 Sanitize the routine name in `ExportService.exportRoutine`, and verify 3.3 passes

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or above the current 604 baseline (618 after this change)
- [x] 4.3 Run `openspec validate fix-import-and-sync-errors --type change --strict` and verify it passes
- [x] 4.4 Verify the diff stays within the 400-line review budget

## 5. Audit follow-up

- [x] 5.1 Add a test importing a bundle whose `schema_version` has a 20-digit major, asserting `preview()` throws `UnsupportedSchemaVersionException` with `isNewer`, and verify it fails with a raw `FormatException`
- [x] 5.2 Parse version components with `int.tryParse` in `SchemaVersion.parseSupported`, treat an unparseable major as newer, and verify 5.1 passes
- [x] 5.3 Add tests pinning the `ArgumentError` branch at the parse boundary and rejecting a well-shaped non-v7 id
- [x] 5.4 Add a test asserting `prepareCutover()` with a duplicate folder returns `SyncOutcome.ambiguousFolder` and saves no approval, and verify it fails with an uncaught `DriveAmbiguousDiscovery`
- [x] 5.5 Report Drive failures from `prepareCutover()` as outcomes, map them in `SyncController.connect`, and verify 5.4 passes
- [x] 5.6 Add a widget test asserting the Drive row offers "Sync now" in `ambiguousFolder` and calls `syncAgain`, and verify it fails; add `driveSyncNow` to both ARB files and `SyncController.syncAgain`, which re-runs the cutover when connect never saved one
- [x] 5.7 Keep letters in any script in export file names, and drop `@visibleForTesting` from `fileNameFor`
- [x] 5.8 Run analyze and the full suite, and verify both pass (625 tests)

## 6. Audit follow-up, second pass

- [x] 6.1 Add a test where the user removes the approved folder and keeps the copy, asserting sync reports `SyncOutcome.cutoverNeeded` with no backoff and recovers after preparing again, and verify it fails
- [x] 6.2 Add `SyncOutcome.cutoverNeeded` and `SyncStatus.cutoverNeeded`, raise it from the preflight's approval check, record it without backoff, and verify 6.1 passes
- [x] 6.3 Make `SyncController.syncAgain` always prepare before syncing, and offer "Sync now" for `cutoverNeeded` in Settings, with a widget test and `syncStatusCutoverNeeded` in both ARB files
- [x] 6.4 Add a test asserting `prepareCutover()` reports a non-JSON response as `SyncOutcome.failed`, and make its catch total
- [x] 6.5 Map an offline cutover to `SyncStatus.offline` instead of `error`
- [x] 6.6 Add scenarios for the connect path, the sync-again action, and the approval wait to `specs/failure-reporting/spec.md`
- [x] 6.7 Run analyze and the full suite, and verify both pass (628 tests)
