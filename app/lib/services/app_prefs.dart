import 'package:shared_preferences/shared_preferences.dart';

/// Only `local` is selectable in M2 — `drive` is reserved for the
/// visible-but-disabled "Coming soon" option (M4 turns it on). This is
/// app-level device settings, not domain data, so it lives in
/// shared_preferences rather than the Drift-backed schemas/*.json entities.
enum StorageMode { local, drive }

class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _storageModeKey = 'storage_mode';
  static const _localeOverrideKey = 'locale_override';

  bool get onboardingComplete =>
      _prefs.getBool(_onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_onboardingCompleteKey, value);

  StorageMode get storageMode {
    final raw = _prefs.getString(_storageModeKey);
    return StorageMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => StorageMode.local,
    );
  }

  Future<void> setStorageMode(StorageMode mode) =>
      _prefs.setString(_storageModeKey, mode.name);

  /// Null means "follow system locale".
  String? get localeOverride => _prefs.getString(_localeOverrideKey);

  Future<void> setLocaleOverride(String? languageCode) {
    if (languageCode == null) return _prefs.remove(_localeOverrideKey);
    return _prefs.setString(_localeOverrideKey, languageCode);
  }
}
