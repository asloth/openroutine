## Why

Routine reminders play the phone's default notification sound, so they sound like every other
app. Sara listened to the drafts from 2026-09-24 and picked Ochi's hello for reminders. It sounds
like Ochi saying "hello, time for your routine."

## What Changes

- Bundle `ochi_hello.ogg` (0.64 seconds) as an Android raw resource, with a `keep.xml` so release
  resource shrinking doesn't drop it.
- Move routine reminders to a new channel, `routine_reminder_v2`, that plays the hello. Android
  fixes a channel's sound once it exists, so the existing `routine_reminder_v1` can't change.
- Delete `routine_reminder_v1` when notifications start, so Settings doesn't list a dead
  duplicate "Routine reminders" channel.

## Capabilities

### Modified Capabilities

- `routine-reminders` — Android reminders play Ochi's hello.

## Impact

**Code.** `app/lib/services/notifications/notification_service.dart`: the reminder channel id, its
sound, and a retired-channel cleanup in `init()`. New files under
`app/android/app/src/main/res/raw/`.

**Tests.** One unit test in `app/test/services/notifications/notification_service_test.dart`.

**Users.** Anyone who customized the v1 channel in system Settings (for example, muted it) gets a
fresh v2 channel with the defaults. That's the unavoidable cost of changing a channel's sound.

**iOS.** Unchanged, and it still plays the default sound. A custom iOS sound needs the file added
to the Xcode project's bundle resources, which is a follow-up best done from Xcode.

**Storage, schema, and i18n.** None.

**Rollback.** Revert. A v2 channel already created on a device stays, unused, until a later build
retires it.
