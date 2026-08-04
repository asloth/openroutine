import 'dart:async';

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
  static const _installClientIdKey = 'install_client_id';

  /// Stable per-install UUID, minted on first read. Goes into
  /// `meta.json.last_writer_client_id` so that, looking at a Drive folder two
  /// devices write to, you can tell which one wrote last (docs/SPEC.md §5).
  /// Debugging aid only — nothing keys off it.
  String installClientId(String Function() generate) {
    final existing = _prefs.getString(_installClientIdKey);
    if (existing != null) return existing;
    final minted = generate();
    // Fire-and-forget: worst case a crash before the write lands mints a new
    // one next launch, which costs nothing.
    unawaited(_prefs.setString(_installClientIdKey, minted));
    return minted;
  }

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
