import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/notifications/notification_service.dart';

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
}
