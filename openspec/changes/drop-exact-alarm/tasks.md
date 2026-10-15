## 1. Manifest

- [x] 1.1 Add a test asserting the manifest declares neither `USE_EXACT_ALARM` nor `SCHEDULE_EXACT_ALARM`, and verify it fails
- [x] 1.2 Remove both permissions and rewrite the manifest comment, and verify 1.1 passes

## 2. Scheduling

- [x] 2.1 Add a test with a recording plugin asserting the step end and both nudges are scheduled `inexactAllowWhileIdle`, and verify it fails on `exactAllowWhileIdle`
- [x] 2.2 Add the same assertion for routine reminders, and verify it fails
- [x] 2.3 Add `NotificationService.scheduleMode` and use it in both calls, and verify 2.1 and 2.2 pass

## 3. Documentation

- [x] 3.1 Rewrite `SPEC.md` §15.14 and the exact alarm mentions in §8 and the launch checklist
- [x] 3.2 Update the store listing in English and Spanish, the permissions table, the publishing checklist, and the privacy policy

## 4. Verification

- [x] 4.1 Run `flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 4.2 Run `flutter test` from `app/` and verify the suite passes
- [x] 4.3 Run `openspec validate drop-exact-alarm --type change --strict` and verify it passes
- [x] 4.4 Build the debug APK and verify the merged manifest declares no exact alarm permission
- [ ] 4.5 Install on the Pixel, start a step, lock the phone, and verify the step-end notification arrives
