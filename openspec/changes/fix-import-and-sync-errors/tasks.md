## 1. Import validation

- [ ] 1.1 Add a unit test importing a bundle whose `exported_at` is `"yesterday"`, asserting it throws `ImportException` with `schemaViolation`, and verify it fails with a raw `FormatException`
- [ ] 1.2 Pass `validateFormats: true` to `_exportSchema.validate` in `SchemaValidator.validateExportBundle`, and verify 1.1 passes
- [ ] 1.3 Add a unit test asserting a bundle produced by `ExportService` still validates, and verify it passes
- [ ] 1.4 Add a unit test covering a value that passes the schema but defeats the models, asserting `ImportException`, and verify it fails
- [ ] 1.5 Wrap `ExportBundle.fromJson` in `ImportService.validateJsonString`, mapping `FormatException` and `ArgumentError` to `ImportException(schemaViolation)`, and verify 1.4 passes

## 2. Ambiguous Drive folder

- [ ] 2.1 Add a test using the fake Drive client with two folders named `OpenRoutine`, asserting `sync()` returns `SyncOutcome.ambiguousFolder`, and verify it fails with an uncaught `DriveAmbiguousDiscovery`
- [ ] 2.2 Add `SyncOutcome.ambiguousFolder`, catch `DriveAmbiguousDiscovery` in `DriveSync._run`, record it through `recordUnwritableRemote`, and verify 2.1 passes
- [ ] 2.3 Add a test asserting the run records a failure the queue reports and schedules no retry, and verify it passes
- [ ] 2.4 Add `SyncStatus.ambiguousFolder`, map the outcome in `SyncController.syncNow` without scheduling a retry, and verify the analyzer reports no unhandled switch case
- [ ] 2.5 Add `syncStatusAmbiguousFolder` to `app_en.arb` and `app_es.arb`, naming the duplicate folder as the cause and removing it as the fix
- [ ] 2.6 Add a widget test asserting Settings shows that message for the new status, and verify it passes

## 3. Escaping and sanitizing

- [ ] 3.1 Add a test asserting a notification payload containing a path separator routes to an escaped segment, and verify it fails
- [ ] 3.2 Escape the payload with `Uri.encodeComponent` where the route is built in `main.dart`, and verify 3.1 passes
- [ ] 3.3 Add a test asserting an exported file name drops characters a file name can't carry while keeping the readable part, and verify it fails
- [ ] 3.4 Sanitize the routine name in `ExportService.exportRoutine`, and verify 3.3 passes

## 4. Verification

- [ ] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [ ] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or above the current 594 baseline
- [ ] 4.3 Run `openspec validate fix-import-and-sync-errors --type change --strict` and verify it passes
- [ ] 4.4 Verify the diff stays within the 400-line review budget
