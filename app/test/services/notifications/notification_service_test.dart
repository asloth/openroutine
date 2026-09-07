import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/notifications/notification_service.dart';
import 'package:openroutine/services/notifications/routine_reminders.dart';

void main() {
  test('builds silent calm boundary details on Android and iOS', () {
    final details = NotificationService.stepBoundaryDetails(
      channelName: 'Gentle timing',
      channelDescription: 'A gentle reminder.',
    );

    final android = details.android!;
    final ios = details.iOS!;
    expect(android.channelId, 'gentle_estimate_boundary_v1');
    expect(android.importance, Importance.defaultImportance);
    expect(android.category, AndroidNotificationCategory.reminder);
    expect(android.playSound, isFalse);
    expect(android.enableVibration, isFalse);
    expect(ios.presentSound, isFalse);
  });

  test('keeps the calm channel independent from its localized name', () {
    final details = NotificationService.stepBoundaryDetails(
      channelName: 'Tiempo con calma',
      channelDescription: 'Un recordatorio suave.',
    );

    expect(details.android!.channelId, 'gentle_estimate_boundary_v1');
    expect(details.android!.channelName, 'Tiempo con calma');
  });

  test('builds an audible mid-step nudge on a channel of its own', () {
    final details = NotificationService.stepNudgeDetails(
      channelName: 'Mid-step nudges',
      channelDescription: 'A nudge partway through a step.',
    );

    final android = details.android!;
    final ios = details.iOS!;
    // A separate channel id is the whole point: Android will not let an
    // existing channel become audible after creation, so reusing the boundary
    // channel would silently do nothing on any device that has posted on it.
    expect(android.channelId, 'step_progress_nudge_v1');
    expect(android.channelId, isNot(NotificationService.stepBoundaryChannelId));
    expect(android.importance, Importance.high);
    expect(android.priority, Priority.high);
    expect(android.category, AndroidNotificationCategory.reminder);
    // Left at their defaults rather than set: default sound and vibration is
    // exactly what this channel wants, and naming no `sound` means the
    // system's own notification tone.
    expect(android.playSound, isTrue);
    expect(android.enableVibration, isTrue);
    expect(android.sound, isNull);
    // Unset, so it falls back to the initialization default (on), unlike the
    // boundary channel which silences itself explicitly.
    expect(ios.presentSound, isNull);
  });

  test('keeps the nudge channel independent from its localized name', () {
    final details = NotificationService.stepNudgeDetails(
      channelName: 'Avisos a mitad de paso',
      channelDescription: 'Un aviso a mitad de un paso.',
    );

    expect(details.android!.channelId, 'step_progress_nudge_v1');
    expect(details.android!.channelName, 'Avisos a mitad de paso');
  });

  test('gives every step notification a distinct id clear of reminders', () {
    final ids = {
      NotificationService.stepEndNotificationId,
      NotificationService.stepHalfwayNotificationId,
      NotificationService.stepNearEndNotificationId,
    };

    expect(ids, hasLength(3));
    for (final id in ids) {
      expect(id, greaterThanOrEqualTo(1));
      expect(id, lessThan(ReminderSchedule.idBase));
    }
  });
}
