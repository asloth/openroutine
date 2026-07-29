import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_prefs.dart';

part 'app_prefs_provider.g.dart';

/// Overridden in main() with a real SharedPreferences instance obtained via
/// SharedPreferences.getInstance() before runApp — the router's redirect
/// logic needs onboarding status synchronously on first build, so this is
/// resolved once at startup rather than exposed as an async provider.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before runApp',
  );
});

@riverpod
AppPrefs appPrefs(Ref ref) => AppPrefs(ref.watch(sharedPreferencesProvider));

@riverpod
class OnboardingComplete extends _$OnboardingComplete {
  @override
  bool build() => ref.watch(appPrefsProvider).onboardingComplete;

  Future<void> complete() async {
    await ref.read(appPrefsProvider).setOnboardingComplete(true);
    state = true;
  }
}

@riverpod
class StorageModeSetting extends _$StorageModeSetting {
  @override
  StorageMode build() => ref.watch(appPrefsProvider).storageMode;

  Future<void> setMode(StorageMode mode) async {
    await ref.read(appPrefsProvider).setStorageMode(mode);
    state = mode;
  }
}

@riverpod
class LocaleOverrideSetting extends _$LocaleOverrideSetting {
  @override
  String? build() => ref.watch(appPrefsProvider).localeOverride;

  Future<void> setLocale(String? languageCode) async {
    await ref.read(appPrefsProvider).setLocaleOverride(languageCode);
    state = languageCode;
  }
}
