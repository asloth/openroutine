import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/notifications/notification_launch.dart';

void main() {
  test('a routine id becomes a single path segment', () {
    expect(
      routineNotificationRoute('019fc553-a96e-7cb7-84e8-93de8598e290'),
      '/routines/019fc553-a96e-7cb7-84e8-93de8598e290',
    );
  });

  test('a payload carrying separators cannot reshape the route', () {
    // Payloads are schema-constrained ids today. Escaping here is what keeps
    // that from being the only reason this is safe — the widget tap path
    // already works this way.
    expect(
      routineNotificationRoute('../settings'),
      '/routines/..%2Fsettings',
    );
  });
}
