import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Play only lets alarm clock and calendar apps declare USE_EXACT_ALARM, and
  // OpenRoutine is neither. SCHEDULE_EXACT_ALARM goes too: nothing schedules an
  // exact alarm anymore, so declaring it would only invite another review.
  test('the manifest declares no exact alarm permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, isNot(contains('"android.permission.USE_EXACT_ALARM"')));
    expect(
      manifest,
      isNot(contains('"android.permission.SCHEDULE_EXACT_ALARM"')),
    );
  });
}
