import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'routine_reminders.dart';

/// Fires one calm local notification when a step reaches its estimate.
///
/// The scheduling is handed to the OS rather than kept alive in-process. That
/// is deliberate and replaces SPEC §8's original foreground-service plan: an
/// alarm registered with the system fires whether or not our process survives,
/// which a foreground service cannot promise, and it avoids declaring a
/// `specialUse` foregroundServiceType that would need justifying at store
/// review. The timer's *state* needs no help staying alive either — it is
/// recomputed from wall-clock timestamps (see services/timer/timer_machine.dart).
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;

  /// Every scheduled step-end reuses this id: only one step is ever pending at
  /// a time, and reusing the id means scheduling a new one implicitly replaces
  /// any stale notification we forgot to cancel.
  static const stepEndNotificationId = 1;

  /// Called when a notification carrying a routine id is tapped. Set once, in
  /// main(), because routing needs the router — which the service must not
  /// know about.
  void Function(String routineId)? onOpenRoutine;

  // Channels are immutable on Android after creation. A new ID prevents old
  // alarm/high-priority settings from leaking into this calmer reminder.
  static const stepBoundaryChannelId = 'gentle_estimate_boundary_v1';

  static NotificationDetails stepBoundaryDetails({
    required String channelName,
    required String channelDescription,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      stepBoundaryChannelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
      playSound: false,
      enableVibration: false,
    ),
    iOS: const DarwinNotificationDetails(presentSound: false),
  );

  /// Returns false if the platform could not be set up, rather than throwing.
  ///
  /// Callers are things like "start the timer" and "arm reminders", and none
  /// of them should die because notifications are unavailable. That is not
  /// hypothetical: on a platform with no init settings this throws, and
  /// because `RoutineTimer.start` awaited it first, a running timer was left
  /// stuck on its loading spinner forever — the notification is the garnish,
  /// the timer is the meal.
  Future<bool> init() async {
    if (_ready) return true;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Asked for explicitly at the point of starting a timer instead,
            // so the prompt has context rather than appearing on first launch.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );
      _ready = true;
      return true;
    } catch (error, stack) {
      debugPrint('Notifications unavailable: $error\n$stack');
      return false;
    }
  }

  void _handleResponse(NotificationResponse response) {
    final routineId = response.payload;
    if (routineId == null || routineId.isEmpty) return;
    onOpenRoutine?.call(routineId);
  }

  /// Asked for when the user first starts a timer, not at app launch, so the
  /// system prompt arrives with obvious context. A refusal is not fatal: the
  /// timer still runs, it just can't tell you about it in the background.
  Future<bool> requestPermission() async {
    if (!await init()) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: false) ?? false;
    }
    return false;
  }

  /// Schedule the estimate-boundary notification for [endsAt], replacing whatever
  /// was pending. Times already in the past are dropped rather than fired
  /// immediately — that only happens for a step that is already overrunning,
  /// which the user can see for themselves.
  Future<void> scheduleStepEnd({
    required DateTime endsAt,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!await init()) return;
    await cancelPending();

    // tz.local is left at UTC: we schedule an offset from now, so the absolute
    // instant is right regardless of the zone. Only wall-clock-anchored
    // schedules ("every day at 07:00") would need the device's real zone, and
    // Timer Mode has none — which is why flutter_timezone isn't a dependency.
    final scheduledAt = tz.TZDateTime.from(endsAt.toUtc(), tz.UTC);
    if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.UTC))) return;

    await _plugin.zonedSchedule(
      id: stepEndNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: stepBoundaryDetails(
        channelName: channelName,
        channelDescription: channelDescription,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelPending() async {
    if (!await init()) return;
    await _plugin.cancel(id: stepEndNotificationId);
  }

  // Reminders get their own channel: they are wall-clock alarms about a
  // routine starting, where the step-end channel is a calm nudge during one.
  // Same reasoning as the comment above — a channel's settings are immutable
  // once created, so the two must not share.
  static const routineReminderChannelId = 'routine_reminder_v1';

  static NotificationDetails routineReminderDetails({
    required String channelName,
    required String channelDescription,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      routineReminderChannelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  /// Replaces every pending routine reminder with [requests].
  ///
  /// Wholesale rather than incremental: the reserved id range is cleared
  /// first, so there is no bookkeeping to get out of step with reality when a
  /// routine is renamed, rescheduled or deleted.
  Future<void> scheduleRoutineReminders(
    List<ReminderRequest> requests, {
    required String channelName,
    required String channelDescription,
  }) async {
    if (!await init()) return;
    await cancelRoutineReminders();

    final details = routineReminderDetails(
      channelName: channelName,
      channelDescription: channelDescription,
    );

    for (final request in requests) {
      final scheduledAt = tz.TZDateTime.from(request.at.toUtc(), tz.UTC);
      if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.UTC))) continue;
      await _plugin.zonedSchedule(
        id: request.notificationId,
        title: request.title,
        body: request.body,
        scheduledDate: scheduledAt,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: request.routineId,
      );
    }
  }

  Future<void> cancelRoutineReminders() async {
    if (!await init()) return;
    for (var i = 0; i < ReminderSchedule.maxReminders; i++) {
      await _plugin.cancel(id: ReminderSchedule.idBase + i);
    }
  }
}
