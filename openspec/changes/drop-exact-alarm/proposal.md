## Why

Play Console flagged that the app declares `USE_EXACT_ALARM`. Play only allows that permission for apps whose core function is an alarm clock or a calendar, and the declaration form offers only those two answers. OpenRoutine is a routine app, so it can't answer honestly, and Play requires the permission gone from every track.

Removing the line from the manifest isn't enough by itself. Both scheduling calls ask Android for `exactAllowWhileIdle`, and Android 14 and later reject an exact schedule from an app without the permission. The notification would never appear.

## What changes

- Remove `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM` from the Android manifest.
- Schedule step-end notifications, mid-step nudges, and routine reminders as `inexactAllowWhileIdle`, from one named constant.
- Update `SPEC.md` §8 and §15.14, the publishing checklist, the store listing in both languages, and the privacy policy so none of them promise exact alarms.

## Capabilities

### New capabilities

- `notification-timing`: how the app hands its notifications to Android, and what it promises about when they arrive.

## Impact

**Code.** `AndroidManifest.xml` and `notification_service.dart`. Tests in `test/services/notifications/`.

**Behavior.** While the phone is locked, a notification can arrive a few minutes late. The on-screen timer stays exact, because it reads wall-clock timestamps.

**Storage and schema.** None. Nothing under `schemas/` changes.

**i18n.** None in the app. The Spanish store listing text changes alongside the English.

**Play Console.** A new bundle has to replace 1.0.0 on Internal testing, and the store listing text has to be pasted again.

**Rollback.** Reverting restores the permission and the Play declaration problem with it.
