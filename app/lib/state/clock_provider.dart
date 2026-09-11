import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// The current time, refreshed every 30 seconds.
///
/// One shared notifier rather than a `Timer` per card: every routine card on
/// the routines list needs the same `now` to decide whether it's upcoming,
/// so one tick re-evaluates all of them together instead of each card
/// running its own timer slightly out of step with the rest.
///
/// `keepAlive`, the same as `app_prefs_provider.dart`'s settings notifiers —
/// this is a value that should keep ticking for as long as anything is
/// watching it, not get torn down and rebuilt with each screen.
///
/// Tests override this by overriding `Clock` with a build that returns a
/// fixed `DateTime`, so a card's upcoming state is deterministic.
@Riverpod(keepAlive: true)
class Clock extends _$Clock {
  Timer? _timer;

  @override
  DateTime build() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      state = DateTime.now();
    });
    ref.onDispose(() => _timer?.cancel());
    return DateTime.now();
  }
}
