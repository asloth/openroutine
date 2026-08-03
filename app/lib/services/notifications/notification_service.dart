import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Fires a local notification when a step's timer expires while the app is
/// backgrounded (docs/SPEC.md §8).
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
  static const _stepEndNotificationId = 1;

  static const _channelId = 'timer_mode';

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        _channelId,
        'Timer Mode',
        channelDescription: 'Tells you when a routine step is up.',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked for explicitly at the point of starting a timer instead, so
          // the prompt has context rather than appearing on first launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asked for when the user first starts a timer, not at app launch, so the
  /// system prompt arrives with obvious context. A refusal is not fatal: the
  /// timer still runs, it just can't tell you about it in the background.
  Future<bool> requestPermission() async {
    await init();
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
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Schedule the "step is up" notification for [endsAt], replacing whatever
  /// was pending. Times already in the past are dropped rather than fired
  /// immediately — that only happens for a step that is already overrunning,
  /// which the user can see for themselves.
  Future<void> scheduleStepEnd({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {
    await init();
    await cancelPending();

    // tz.local is left at UTC: we schedule an offset from now, so the absolute
    // instant is right regardless of the zone. Only wall-clock-anchored
    // schedules ("every day at 07:00") would need the device's real zone, and
    // Timer Mode has none — which is why flutter_timezone isn't a dependency.
    final scheduledAt = tz.TZDateTime.from(endsAt.toUtc(), tz.UTC);
    if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.UTC))) return;

    await _plugin.zonedSchedule(
      id: _stepEndNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelPending() async {
    await init();
    await _plugin.cancel(id: _stepEndNotificationId);
  }
}
