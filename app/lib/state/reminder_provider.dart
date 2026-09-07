import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/routine.dart';
import '../services/notifications/routine_reminders.dart';
import 'app_prefs_provider.dart';
import 'timer_provider.dart';

part 'reminder_provider.g.dart';

/// The localised text a reminder needs. Built in the widget layer, where
/// `AppLocalizations` is reachable, and handed down — the same shape the timer
/// already uses for its own notification copy.
class ReminderCopy {
  const ReminderCopy({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String Function(Routine routine) title;
  final String Function(Routine routine, Duration lead) body;
  final String channelName;
  final String channelDescription;
}

/// Minutes between the reminder and the routine's start time.
@Riverpod(keepAlive: true)
class ReminderLeadSetting extends _$ReminderLeadSetting {
  /// The choices offered in Settings. Zero means "at the start time".
  static const options = [0, 5, 10, 15, 30];

  @override
  Duration build() =>
      Duration(minutes: ref.watch(appPrefsProvider).reminderLeadMinutes);

  Future<void> setLead(Duration lead) async {
    await ref.read(appPrefsProvider).setReminderLeadMinutes(lead.inMinutes);
    state = lead;
  }
}

/// Re-arms the OS-level reminders for every scheduled routine.
///
/// Called whenever the routine list changes, which covers create, edit, delete
/// and a Drive sync bringing someone else's edit down — all of them land as an
/// invalidation of `routinesProvider`, so none of them needs to remember to
/// call this itself.
@Riverpod(keepAlive: true)
class RoutineReminders extends _$RoutineReminders {
  @override
  DateTime? build() => null;

  Future<void> arm(List<Routine> routines, ReminderCopy copy) async {
    final notifications = ref.read(notificationServiceProvider);
    final lead = ref.read(reminderLeadSettingProvider);

    final requests = ReminderSchedule.build(
      routines: routines,
      now: DateTime.now(),
      lead: lead,
      title: copy.title,
      body: copy.body,
    );

    if (requests.isEmpty) {
      await notifications.cancelRoutineReminders();
      state = DateTime.now();
      return;
    }

    // Asked for at the point something would actually fire, not at launch —
    // same reasoning as the timer's prompt. A refusal is not fatal: the
    // routines still work, they just cannot announce themselves.
    await notifications.requestPermission();
    await notifications.scheduleRoutineReminders(
      requests,
      channelName: copy.channelName,
      channelDescription: copy.channelDescription,
    );
    state = DateTime.now();
  }
}
