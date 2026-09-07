import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Only `local` is selectable in M2 — `drive` is reserved for the
/// visible-but-disabled "Coming soon" option (M4 turns it on). This is
/// app-level device settings, not domain data, so it lives in
/// shared_preferences rather than the Drift-backed schemas/*.json entities.
enum StorageMode { local, drive }

class DriveCutoverApproval {
  const DriveCutoverApproval({
    required this.folderId,
    required this.targetSchemaVersion,
    required this.confirmedAt,
  });

  final String folderId;
  final String targetSchemaVersion;
  final DateTime confirmedAt;
}

class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _storageModeKey = 'storage_mode';
  static const _localeOverrideKey = 'locale_override';
  static const _paletteKey = 'theme_palette';
  static const _reminderLeadKey = 'reminder_lead_minutes';
  static const _installClientIdKey = 'install_client_id';
  static const _driveCutoverFolderIdKey = 'drive_cutover_folder_id';
  static const _driveCutoverVersionKey = 'drive_cutover_version';
  static const _driveCutoverConfirmedAtKey = 'drive_cutover_confirmed_at';

  DriveCutoverApproval? get driveCutoverApproval {
    final folderId = _prefs.getString(_driveCutoverFolderIdKey);
    final version = _prefs.getString(_driveCutoverVersionKey);
    final confirmedAt = _prefs.getString(_driveCutoverConfirmedAtKey);
    if (folderId == null || version == null || confirmedAt == null) return null;
    final parsed = DateTime.tryParse(confirmedAt);
    if (parsed == null) return null;
    return DriveCutoverApproval(
      folderId: folderId,
      targetSchemaVersion: version,
      confirmedAt: parsed,
    );
  }

  Future<void> setDriveCutoverApproval(DriveCutoverApproval? value) async {
    if (value == null) {
      await _prefs.remove(_driveCutoverFolderIdKey);
      await _prefs.remove(_driveCutoverVersionKey);
      await _prefs.remove(_driveCutoverConfirmedAtKey);
      return;
    }
    await _prefs.setString(_driveCutoverFolderIdKey, value.folderId);
    await _prefs.setString(_driveCutoverVersionKey, value.targetSchemaVersion);
    await _prefs.setString(
      _driveCutoverConfirmedAtKey,
      value.confirmedAt.toIso8601String(),
    );
  }

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

  /// A `Palette.storageId` — either a built-in name (`warm_paper`) or a
  /// generated one carrying its hue (`custom:268`). Null means "never chosen",
  /// which resolves to the default palette. Deliberately stored as an opaque
  /// string rather than an enum: the custom option has no fixed set of values,
  /// and `Palette.fromStorageId` already falls back safely for anything it
  /// does not recognise, including ids written by a newer build.
  String? get paletteId => _prefs.getString(_paletteKey);

  Future<void> setPaletteId(String? id) {
    if (id == null) return _prefs.remove(_paletteKey);
    return _prefs.setString(_paletteKey, id);
  }

  /// How far before a routine's start time its reminder fires. Five minutes by
  /// default: firing exactly on the hour tells you you are already late, where
  /// a short lead is enough to finish what you are doing and switch.
  int get reminderLeadMinutes => _prefs.getInt(_reminderLeadKey) ?? 5;

  Future<void> setReminderLeadMinutes(int minutes) =>
      _prefs.setInt(_reminderLeadKey, minutes);
}
