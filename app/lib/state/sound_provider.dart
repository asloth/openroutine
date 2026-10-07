import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/sounds/app_sounds.dart';
import 'app_prefs_provider.dart';

part 'sound_provider.g.dart';

/// Whether the app plays its own sounds. On by default. Notification sounds
/// follow the phone's notification settings instead, not this switch.
@Riverpod(keepAlive: true)
class SoundsEnabledSetting extends _$SoundsEnabledSetting {
  @override
  bool build() => ref.watch(appPrefsProvider).soundsEnabled;

  Future<void> setEnabled(bool enabled) async {
    await ref.read(appPrefsProvider).setSoundsEnabled(enabled);
    state = enabled;
  }
}

/// The sound player, already silenced when sounds are off, so callers play
/// without checking the setting themselves.
@Riverpod(keepAlive: true)
AppSounds appSounds(Ref ref) => ref.watch(soundsEnabledSettingProvider)
    ? AudioplayersAppSounds()
    : const SilentAppSounds();
