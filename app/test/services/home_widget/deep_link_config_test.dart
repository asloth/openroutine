import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Flutter's own deep linking hands a widget tap's `openroutine://` URI to
  // go_router when the app is already running, and no route matches it, so the
  // tap lands on Page Not Found. `home_widget` delivers the tap instead, through
  // `HomeWidget.widgetClicked`, and main.dart routes it.
  test(
    'Flutter deep linking is off, so widget taps reach home_widget only',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        matches(
          RegExp(
            r'<meta-data\s+android:name="flutter_deeplinking_enabled"\s+'
            r'android:value="false"\s*/>',
          ),
        ),
      );
    },
  );
}
