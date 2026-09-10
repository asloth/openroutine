## Why

Routine cards and primary actions currently take their color from the background palette
(`PaletteSetting`, default `sea_glass`). That couples two decisions that don't belong together: the
paper you read the app on, and the color that says "this is a routine, tap it." Sara wants to pick
them independently — a cool sea-glass ground with a warm accent, say — and the app has no way to
express that today.

Green is also, separately, spoken for: the home screen already uses it to mean "a routine is coming
up soon," and that meaning has to hold regardless of which palette or accent someone picks. It's a
fixed color, not a palette role.

## What changes

- Add an **accent color** setting, independent of the background palette, defaulting to purple
  (`Palette.inkIris`). It's stored the same way the palette is, and it's picked from the same
  built-in list — no custom hue for the accent, at least for now.
- Routine cards and primary actions read their fill from the accent's container roles instead of
  the palette's own `primaryContainer`. The rest of the palette (surfaces, secondary, tertiary,
  neumorphic shadows) is unchanged.
- Add fixed "upcoming" tokens (light and dark) that don't move with either the palette or the
  accent, and a fixed timer-ground token for light mode.
- Add an "Accent color" picker to Settings › Appearance, under the existing palette picker.

## Capabilities

### New Capabilities

- `accent-color` — a routine's cards and primary actions carry a color chosen separately from the
  background palette, with purple as the default and a fixed green reserved for "coming up."

## Impact

**Code.** `app/lib/services/app_prefs.dart` (new pref key), `app/lib/state/app_prefs_provider.dart`
(new `AccentSetting` notifier), `app/lib/theme/palette.dart` (accent-merge helper),
`app/lib/theme/colors.dart` (fixed upcoming/timer-ground tokens), `app/lib/theme/theme.dart`
(`RoutineCardColors` extension, accent-aware `AppTheme.light`/`dark`), `app/lib/main.dart` (wires
the new provider into both themes), `app/lib/widgets/accent_picker.dart` (new), the settings
screen, both ARB files, and `DESIGN.md`.

**Storage and schema.** A new `shared_preferences` key, `accent_color`, modeled exactly on
`theme_palette`. No `schemas/*.json` file changes — this is device-level presentation, not routine
data.

**Existing users.** Everyone gets purple as their accent on first launch after the update, since
nothing is stored yet. Anyone who later picks a different accent keeps it, the same way the palette
setting already works.

**i18n.** Two new strings (a title and a helper line) in `app_en.arb` and `app_es.arb`. No existing
strings change.

**Rollback.** Reverting drops the pref key, the notifier, and the picker. The stored `accent_color`
value (if any) is simply never read again — nothing to migrate either direction.
