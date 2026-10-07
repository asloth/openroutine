## 1. Ochi's hello on reminders

- [x] 1.1 Add a unit test that reminder details use `routine_reminder_v2` with the `ochi_hello`
      raw sound and that `routine_reminder_v1` is retired, and verify it fails
- [x] 1.2 Bundle `res/raw/ochi_hello.ogg` with a `keep.xml`, move the channel to v2, and delete
      retired channels in `init()`; verify 1.1 passes

## 2. Verification

- [x] 2.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` and verify no issues
- [x] 2.2 Run `/home/sabera/fvm/bin/fvm flutter test` and verify the full suite passes
- [ ] 2.3 Trigger a reminder on the Pixel 9a and hear the hello
