## 1. Schema and versioning

- [ ] 1.1 Update schema_version, validator, and Drive/local/import tests for 2.0.0 (reading 1.x still works; 2.0.1+ is newer), and verify they fail
- [ ] 1.2 Delete trigger.schema.json, drop trigger_id and triggers, move $ids to v2 in both schema copies, add `SchemaVersion.v2_0`, and verify 1.1 passes

## 2. Model and storage

- [ ] 2.1 Add a migration test from v6 with a routine linked to a trigger, and verify it fails
- [ ] 2.2 Remove `Trigger`, `Routine.triggerId`, the triggers table and column (Drift v7 with `onUpgrade`), and the trigger paths in the storage adapters, export, and import; verify 2.1 passes

## 3. App

- [ ] 3.1 Update the routine form, routine detail, import, and reminder tests to assert no moment UI or copy, and verify they fail
- [ ] 3.2 Remove the Moment picker, the chip, the import counts, and the moment reminder clause; clean both ARB files and the Drive README
- [ ] 3.3 Update docs/SPEC.md, DESIGN.md, and CONTRIBUTING.md

## 4. Verification

- [ ] 4.1 `flutter analyze --fatal-infos` reports no issues
- [ ] 4.2 `flutter test` passes
- [ ] 4.3 Install on the Pixel with `adb install -r`, confirm routines survive the migration, and reconnect Drive
