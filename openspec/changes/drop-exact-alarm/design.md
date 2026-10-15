## Context

See `proposal.md`. `NotificationService` schedules everything through `flutter_local_notifications`' `zonedSchedule`, in two places: `_schedule` for a running step and `scheduleRoutineReminders` for routine reminders.

## Goals and non-goals

**Goals:**

- Ship a bundle Play accepts with no exact alarm declaration.
- Keep every notification firing while the phone is locked.

**Non-goals:**

- Exact timing while the phone is locked. See the alternatives below.
- Keeping the screen awake during a timer.

## Decisions

### Inexact-while-idle everywhere, from one constant

`NotificationService.scheduleMode` is `inexactAllowWhileIdle`, and both calls use it. It's the inexact mode that still fires through Doze, which is the only situation these notifications matter in.

*Alternative considered:* keep `SCHEDULE_EXACT_ALARM`, check `canScheduleExactNotifications()` before each schedule, and add a sheet that sends the user to Android's "Alarms & reminders" page. Play allows that permission for any app. Rejected for now: it adds a sheet, strings in both ARB files, a settings round trip, and remembered dismissal, all to shave a few minutes off a notification the user may never see late. `SPEC.md` §15.14 records it as the path if that changes.

*Alternative considered:* declare the app an alarm clock. Rejected: it isn't one, the store listing says so, and a false declaration risks more than a rejection.

### Drop `SCHEDULE_EXACT_ALARM` too

Nothing schedules an exact alarm anymore, so declaring the permission only invites another review question.

## Risks and trade-offs

**Late notifications.** → Android may batch an inexact alarm by a few minutes, and in deep Doze it allows about one such alarm every nine minutes per app. A halfway nudge and a step end close together on a locked phone can arrive together. The on-screen timer is unaffected.

**A plugin could merge the permission back in.** → The manifest test reads the source manifest only. Verify the merged manifest of the release build before uploading.

## Migration plan

None. Already scheduled exact alarms on existing installs fire as before, and the next schedule replaces them with inexact ones.
