## Why

Settings › Appearance renders `PalettePicker` and then `AccentPicker` under one "Appearance"
header, and Sara reports it reads as "two sections for choosing a color" she can't tell apart.

`PalettePicker` has no title and no helper — it's a bare row of swatches followed by "{name}
selected". `AccentPicker` below it has a title ("Accent color"), a helper, its own swatches, and
its own "{name} selected". Read top to bottom, the section says: untitled swatches, "Sea Glass
selected", "Accent color", swatches, "Ink & Iris selected" — nothing marks where one picker ends
and the other starts.

The two pickers also share `paletteName()` for their swatch labels, so both pickers can call a
swatch "Warm Paper," "Ink & Iris," or "Plum." Those are theme names, not colors — an orange accent
dot labeled "Warm Paper" makes the color word double as a whole look's name, which is confusing
precisely because the two pickers are asking different questions ("which look?" vs. "which
color?").

## What Changes

- Give `PalettePicker` the same header block `AccentPicker` already has: a title ("Theme") and a
  helper line, with matching padding, so the section reads as two clearly separated pickers instead
  of one untitled and one titled.
- Add an `accentName()` helper that names each built-in accent swatch by its rendered color
  (Terracotta, Indigo, Teal, Magenta, Blue, Green) instead of its theme name, and use it for the
  accent picker's semantics label, tooltip, and "{name} selected" caption. `PalettePicker` keeps
  `paletteName()`.
- Add the six new `accentColor*` strings and the two new `settingsTheme*` strings to both ARB
  files.

Having two pickers is intentional — see `openspec/changes/add-accent-color/proposal.md`. This
change does not merge or remove either picker; it makes the boundary between them legible and gives
each swatch a name that answers the question its own picker is actually asking.

## Capabilities

### New Capabilities

- `appearance-section` — Settings › Appearance's background-palette and accent-color pickers each
  carry their own title and helper, and each names its swatches for the thing it is choosing (a
  theme, or a color).

## Impact

**Code.** `app/lib/widgets/palette_picker.dart` (new header block, new `accentName()` helper),
`app/lib/widgets/accent_picker.dart` (swap `paletteName()` for `accentName()` in the label, tooltip,
and caption), both ARB files. `app/test/widgets/accent_picker_test.dart` (swatch labels are now
color words) and a new `app/test/widgets/palette_picker_test.dart`.

**Storage and schema.** None. No pref key, no stored value, and no file under `schemas/` changes —
this is presentation only.

**Existing users.** No behavior changes: the same two pickers, same swatches, same tap targets,
same order. Only the header and the accent labels change.

**i18n.** Eight new strings (`settingsThemeTitle`, `settingsThemeHelper`, and six
`accentColor*` color words) in `app_en.arb` and `app_es.arb`. No existing strings change.

**Rollback.** Reverting restores the untitled palette picker and the theme-named accent swatches.
Nothing persisted changes shape, so there's nothing to unwind.
