## Context

See `proposal.md` — Why. `PalettePicker` and `AccentPicker` (`app/lib/widgets/palette_picker.dart`,
`app/lib/widgets/accent_picker.dart`) already share a swatch and semantics pattern; `AccentPicker`'s
doc comment says as much. The two widgets are rendered back to back in
`app/lib/screens/settings/settings_screen.dart` under a single `_SectionHeader(l10n
.settingsAppearanceSection)`. `paletteName()`, which both widgets currently call for their swatch
labels, lives in `palette_picker.dart` "so the palette stays a pure colour value with no dependency
on l10n."

## Goals / Non-Goals

**Goals:**

- Make the boundary between the two pickers visible without touching `settings_screen.dart` or
  moving either widget.
- Give the accent picker's swatches names that answer "which color?" instead of "which theme?".

**Non-Goals:**

- Merging, reordering, or removing either picker. Background palette and accent are separate
  settings on purpose (`openspec/changes/add-accent-color/proposal.md`).
- Renaming any `theme*` string, `Palette` id, or the background picker's own swatch labels.
  `PalettePicker` keeps `paletteName()` — a theme picker naming its swatches by theme is correct.
- Touching the custom-hue palette swatch. It stays `themeCustom` in both pickers; `AccentPicker`
  has no custom entry at all (see `add-accent-color/design.md`'s Non-Goals), so `accentName()`'s
  fallback for an unrecognized id is unreachable in practice and exists only so the function is
  total.

## Decisions

### `PalettePicker` gets `AccentPicker`'s exact header shape, not a new one

The new title (`titleMedium`) and helper (`bodySmall`, `onSurfaceVariant`) `Padding` blocks in
`PalettePicker` copy `AccentPicker`'s padding values (`AppSpacing.element` horizontal,
`AppSpacing.base` above the title, `AppSpacing.base / 2` between title and helper,
`AppSpacing.base` below the helper) verbatim.

*Rationale:* the defect is that one picker looks titled and the other doesn't. Matching the
existing shape exactly is what makes the two read as siblings; inventing a distinct header for the
palette picker would trade "looks like one section" for "looks like two different kinds of
section."

### A new `accentName()` function, not a parameter on `paletteName()`

`accentName(AppLocalizations, Palette)` is a second top-level function in `palette_picker.dart`,
with the same signature as `paletteName()`, rather than a `bool asAccent` flag or similar on the
existing function.

*Alternative considered:* one function with a mode flag. Rejected — the two names are answers to
different questions ("which look?" vs. "which color?"), not two formattings of the same answer, and
a flag would hide that at every call site. Two small `switch` expressions living next to each other
are easier to audit for "did every built-in get a real answer" than one function with a branch
inside each case.

### Color words are chosen by eye against each palette's light `primary`, not derived from hue or id

`warm_paper` → Terracotta, `ink_iris` → Indigo, `sea_glass` → Teal, `plum` → Magenta, `slate` →
Blue, `moss` → Green.

*Rationale:* `Palette.fromSeed`'s generated `primary` doesn't always match what its id promises —
`plum`'s light primary renders as a pink-magenta, not the dark fruit color the name suggests
(`app/lib/theme/palette.dart`'s recipe holds hue and saturation constant but the id was chosen for
mood, not gamut position). Naming from the rendered swatch, the thing someone is actually looking
at, is what makes the label trustworthy; naming from the id would just move the "the name doesn't
match what I see" defect from the picker level down to the word level.

*Alternative considered:* deriving the word programmatically from `seedHue` (e.g., a hue-range
table). Rejected for six values — a generated mapping adds a second thing to get right (the range
boundaries) for the same result, and a person's read of "what color is this" doesn't line up with
even hue boundaries when saturation and lightness also shift the perceived color, as `plum` shows.

## Risks / Trade-offs

**Six new color words are one more thing to translate and keep in sync across ARB files.** → True,
and unavoidable for the fix — the whole defect is that the existing words were wrong for this
purpose. Kept to plain, short, common words (`CLAUDE.md`'s writing-style rules apply to these too)
to keep translation low-effort.

**Matching `AccentPicker`'s header exactly means duplicating four `Padding` blocks' worth of
layout rather than extracting a shared header widget.** → Accepted for this slice. `CLAUDE.md`
asks for restyling in place and minimal diffs; a shared `_PickerHeader` widget is a reasonable
follow-up but would touch both files' internals for no visible difference today.

## Migration Plan

None. Presentation only, nothing persisted changes shape, and every existing stored `theme_palette`
and `accent_color` value keeps resolving exactly as it did before.
