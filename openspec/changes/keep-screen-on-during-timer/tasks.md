## 1. Screen wake

- [x] 1.1 Add `wakelock_plus`, a `ScreenWake` interface, its `WakelockScreenWake` implementation, and `screenWakeProvider`, with no callers yet
- [x] 1.2 Add widget tests asserting the screen is kept on once a run starts, off while paused and on again on resume, and off after leaving the timer, and verify all three fail
- [x] 1.3 Call `ScreenWake.keepOn` from the timer screen on every state change and on dispose, and verify 1.2 passes

## 2. Documentation

- [x] 2.1 Note the behavior in `SPEC.md` §8

## 3. Verification

- [x] 3.1 Run `flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 3.2 Run `flutter test` from `app/` and verify the suite passes
- [x] 3.3 Run `openspec validate keep-screen-on-during-timer --type change --strict` and verify it passes
- [ ] 3.4 Install on the Pixel, start a routine, and verify the screen stays on past its timeout, then sleeps when paused
