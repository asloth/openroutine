## 1. Match the finished screen's mascot to the running screen's

- [x] 1.1 Add a test to `app/test/screens/timer/timer_screen_test.dart` that finishes a run and
      asserts the finished screen's `MascotSlot.size` is at least 160 and equals the running
      screen's size, and verify it fails against the current 124/168 split
- [x] 1.2 Add a private `_mascotSize` constant to `timer_screen.dart` and have both the running and
      finished `MascotSlot`s read it, and verify 1.1 passes

## 2. Keep the existing finished-screen test honest

- [x] 2.1 Scroll `finishing the run shows the summary and writes a log` to `Back to today` before
      asserting on it, since the bigger mascot pushes it past the `ListView`'s default lazy-build
      extent at the widget-test surface size, and verify it still passes

## 3. Verification

- [x] 3.1 Run `app/test/screens/timer/timer_screen_test.dart` and verify the whole file passes
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.3 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
