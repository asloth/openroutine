import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display awake while you're running a routine, so you can glance
/// at the timer without unlocking. While the screen is on and the app is in
/// front, a step's progress is exact; a locked phone has to rely on inexact
/// notifications instead (docs/SPEC.md §15.14).
abstract interface class ScreenWake {
  Future<void> keepOn(bool on);
}

class WakelockScreenWake implements ScreenWake {
  const WakelockScreenWake();

  /// Never throws. A screen that sleeps is a small loss; a timer that breaks
  /// because a plugin isn't there (tests, desktop) is not.
  @override
  Future<void> keepOn(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (error) {
      debugPrint('Screen wake unavailable: $error');
    }
  }
}
