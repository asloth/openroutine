## Why

Two appearance defects, both visible on device and neither caught by tests.

`SegmentedButton` is the only interactive component the theme never configures. Fifteen component themes are defined; that one was missed, so it falls back to Material's defaults and paints its selected segment with `secondaryContainer` while every chip in the app uses `primaryContainer`. In the hand-tuned warm paper palette this passes as a muted green and reads as merely inconsistent. In a generated palette it is worse: generated schemes preserve warm paper's hue offsets, and secondary sits roughly 120° from the base, so the teal `sea_glass` palette renders its selected segment magenta. The Scheduled/Flexible toggle on the routine form is where this shows.

The default palette is `warm_paper`, and it is the wrong default for this user. It is also spelled out in five separate places, so changing it means finding all of them rather than editing one.

## What Changes

- Add a `segmentedButtonTheme` that uses the same colour roles as the existing chip theme, so a selected segment matches the rest of the app in every palette.
- Introduce a single named default palette, and point the fresh-install fallback and both `AppTheme` builders at it instead of repeating `warmPaper`.
- Change that default to `sea_glass`.
- Record in `DESIGN.md` that `warm_paper` remains the normative reference palette — every other palette is still generated from its HSL structure — while the shipped default is now `sea_glass`.

## Capabilities

### New Capabilities

- `appearance-defaults` — what a fresh install is themed with, and the requirement that themed components follow the selected palette's roles rather than framework defaults.

## Impact

**Code.** `app/lib/theme/theme.dart` (new component theme, default parameters), `app/lib/theme/palette.dart` (named default), `DESIGN.md`. Widget tests for both behaviours.

**Storage and schema.** None. The palette is persisted as an opaque string and `sea_glass` is already a valid stored value — it is what this device holds right now. No file under `schemas/` changes.

**Existing users.** Anyone who has already chosen a palette is unaffected: the default only applies when nothing is stored. Someone who deliberately chose warm paper keeps it.

**i18n.** None.

**Rollback.** Reverting restores `warm_paper` as the default and drops the component theme. Nothing is persisted differently, so there is nothing to unwind.
