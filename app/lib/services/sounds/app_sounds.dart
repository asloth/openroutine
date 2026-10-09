import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The short sounds the app plays while you use it. Notification sounds live
/// in `android/app/src/main/res/raw/` instead, because the OS plays those.
enum AppSound {
  /// You finished or skipped a step and the next one is up.
  stepDone('sounds/step_done_pop.ogg', Duration(milliseconds: 700)),

  /// You finished the whole routine: Ochi's wheee, then a boing.
  routineFinished('sounds/routine_finished.ogg', Duration(milliseconds: 1600));

  const AppSound(this.asset, this.length);

  /// Relative to `assets/`, which is where audioplayers looks.
  final String asset;

  /// How long the file runs. Low-latency players never say when they're
  /// done, so this is when the player gets handed back.
  final Duration length;
}

abstract interface class AppSounds {
  /// Gets every sound ready, so [play] starts on the same frame as the
  /// animation it goes with.
  Future<void> preload();

  Future<void> play(AppSound sound);
}

/// What the app uses when you turn sounds off in Settings.
class SilentAppSounds implements AppSounds {
  const SilentAppSounds();

  @override
  Future<void> preload() async {}

  @override
  Future<void> play(AppSound sound) async {}
}

class AudioplayersAppSounds implements AppSounds {
  // Mixes with whatever else is playing instead of pausing your music, and
  // stays quiet when the phone is on silent: these are garnish, never alarms.
  // Built by hand because `AudioContextConfig` asserts on iOS when you ask
  // for silence-respecting sounds that also mix with your music.
  @visibleForTesting
  static final context = AudioContext(
    android: AudioContextAndroid(
      usageType: AndroidUsageType.notificationRingtone,
      audioFocus: AndroidAudioFocus.none,
    ),
    // Ambient already mixes with other audio. The package rejects the
    // mixWithOthers option on it, so it stays out.
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  final _pools = <AppSound, Future<AudioPool>>{};

  Future<AudioPool> _pool(AppSound sound) => _pools[sound] ??= AudioPool.create(
    source: AssetSource(sound.asset),
    // A pop can land while the last one is still ringing out.
    maxPlayers: 2,
    audioContext: context,
    playerMode: PlayerMode.lowLatency,
  );

  @override
  Future<void> preload() async {
    for (final sound in AppSound.values) {
      try {
        await _pool(sound);
      } catch (error) {
        debugPrint('Sound ${sound.name} unavailable: $error');
        _pools.remove(sound);
      }
    }
  }

  /// Never throws. A sound that can't play costs nothing but the sound, so a
  /// missing plugin or a busy audio device must not break the timer.
  @override
  Future<void> play(AppSound sound) async {
    try {
      final stop = await (await _pool(sound)).start();
      Future.delayed(sound.length, stop).ignore();
    } catch (error) {
      debugPrint('Sound ${sound.name} unavailable: $error');
      _pools.remove(sound);
    }
  }
}
