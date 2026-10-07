import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The short sounds the app plays while you use it. Notification sounds live
/// in `android/app/src/main/res/raw/` instead, because the OS plays those.
enum AppSound {
  /// You finished a step and the next one is up.
  stepDone('sounds/step_done_pop.ogg'),

  /// You finished the whole routine: Ochi's wheee, then a boing.
  routineFinished('sounds/routine_finished.ogg');

  const AppSound(this.asset);

  /// Relative to `assets/`, which is where audioplayers looks.
  final String asset;
}

abstract interface class AppSounds {
  Future<void> play(AppSound sound);
}

/// What the app uses when you turn sounds off in Settings.
class SilentAppSounds implements AppSounds {
  const SilentAppSounds();

  @override
  Future<void> play(AppSound sound) async {}
}

class AudioplayersAppSounds implements AppSounds {
  // Mixes with whatever else is playing instead of pausing your music, and
  // stays quiet when the phone is on silent: these are garnish, never alarms.
  static final _context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: true,
  ).build();

  /// Never throws. A sound that can't play costs nothing but the sound, so a
  /// missing plugin or a busy audio device must not break the timer.
  @override
  Future<void> play(AppSound sound) async {
    final player = AudioPlayer();
    try {
      await player.setAudioContext(_context);
      await player.setReleaseMode(ReleaseMode.release);
      player.onPlayerComplete.first.then((_) => player.dispose()).ignore();
      await player.play(AssetSource(sound.asset), mode: PlayerMode.lowLatency);
    } catch (error) {
      debugPrint('Sound ${sound.name} unavailable: $error');
      await player.dispose().catchError((_) {});
    }
  }
}
