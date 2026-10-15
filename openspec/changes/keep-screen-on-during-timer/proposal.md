## Why

Notifications are inexact now (`drop-exact-alarm`). On your Pixel, a reminder due at 12:55 arrived at 12:59, and Android allows up to 75% of the remaining time. While the phone is locked, a step's end can show up late. Keeping the screen awake during a running step means you can glance at the exact timer instead of waiting on a notification.

## What changes

- Add `wakelock_plus` and a small `ScreenWake` service behind a provider.
- The timer screen keeps the display awake while a step runs, and lets it sleep when you pause, finish, or leave.
- Note the behavior in `SPEC.md` §8.

## Capabilities

### New capabilities

- `timer-screen-wake`: when the timer keeps the display awake.

## Impact

**Code.** `timer_screen.dart`, new `services/screen/screen_wake.dart` and `state/screen_wake_provider.dart`, `pubspec.yaml`. Widget tests in `timer_screen_test.dart`.

**Permissions.** None new. `wakelock_plus` keeps the screen on with a window flag, not a wake lock permission.

**Battery.** The screen stays on for as long as a step runs. Pausing lets it sleep.

**Storage, schema, and i18n.** None.

**Rollback.** Reverting removes the dependency and the screen sleeps on its usual timeout again.
