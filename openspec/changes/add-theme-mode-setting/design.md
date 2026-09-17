## Context

See `proposal.md` — Why. `MaterialApp.router` already receives both a light and a dark `ThemeData`
(`AppTheme.light(accent)` / `AppTheme.dark(accent)`); Flutter picks between them using `themeMode`,
which defaults to `ThemeMode.system` when left unset. This change adds a stored setting for that
one parameter. It doesn't touch either `ThemeData`, the accent, or the background palette.

## Goals / Non-Goals

**Goals:**

- Let the user pin the app to Light or Dark regardless of the phone's own brightness, or leave it
  on System (the current, unchanged behavior).
- Store the choice the same way every other device setting here is stored — `shared_preferences`,
  read through `AppPrefs`, exposed through a `keepAlive` Riverpod notifier.
- Default every existing install to System, so shipping this changes nothing until someone opens
  Settings.

**Non-Goals:**

- Theming the Android home screen widget or notifications. Neither is a `MaterialApp` consumer, so
  neither reads `themeMode`; both keep following the system theme.
- Changing the accent color or background palette pickers, or anything else in Settings ›
  Appearance besides adding the new row.
- A "high contrast" or other accessibility-driven theme variant. This is strictly light vs. dark vs.
  system.

## Decisions

### `AppPrefs.themeMode` stores a plain string, not Flutter's `ThemeMode`

Every service under `app/lib/services/` is free of Flutter framework imports today —
`app_prefs.dart` imports only `dart:async` and `shared_preferences`. Storing `'system'` / `'light'`
/ `'dark'` as a string keeps that true, matching how `accentId` and `localeOverride` are already
opaque strings. `ThemeModeSetting`, in `app_prefs_provider.dart` — which already imports
`flutter_riverpod` — does the one mapping between that string and Flutter's `ThemeMode` enum, in
both directions.

*Alternative considered:* store `ThemeMode` directly via its `.name`. Rejected: it would pull a
Flutter framework import into a service file that has never needed one, for no benefit — the string
literals are already exactly `ThemeMode.values`' names, so the mapping is a one-line `switch`.

### Missing or unrecognized values resolve to `'system'`, not `null`

`StorageMode` and `AccentSetting` both fall back to a concrete default when the stored value is
absent or unrecognized, rather than surfacing a nullable state the caller has to keep handling.
`AppPrefs.themeMode` follows the same shape: the getter itself resolves anything that isn't exactly
`'light'` or `'dark'` to `'system'`, so `ThemeModeSetting.build()` never has to guess.

### The Theme row sits above the accent picker, not below

The request singles out light/dark as the thing to control; the accent picker is a separate,
existing decision. Placing Theme first in the Appearance section keeps the new, more fundamental
switch above the color choice it applies to, without moving or restyling the accent picker itself.

## Risks / Trade-offs

**A fourth device-setting notifier alongside `StorageModeSetting`, `LocaleOverrideSetting`, and
`AccentSetting`.** → It's a direct copy of an established pattern here, not a new one — the
marginal complexity is one `switch` in each direction.

## Migration Plan

None. `theme_mode` is a new, independent key that defaults to absent, and absent resolves to
System — the app's current behavior.
