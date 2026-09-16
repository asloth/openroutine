## Context

See `proposal.md` — Why. `AppTheme._build` currently takes a background `Palette` and an accent
`Palette`, and calls `Palette.withAccent(palette.scheme(brightness), accent.scheme(brightness))` to
graft the accent's primary identity onto the background's scheme. Everything else — surfaces,
secondary, tertiary, the neumorphic pair, and `palette.mascot` — comes from the background palette
alone. That's the entire defect: two people who pick the same accent but different backgrounds get
different mascots and different card surfaces, which reads as a bug even though both settings did
exactly what they were built to do.

## Goals / Non-Goals

**Goals:**

- One color choice drives the whole theme: surfaces, every `ColorScheme` role, the neumorphic pair,
  and the mascot.
- Delete the code and strings that only existed to support the two-setting model, rather than
  leaving them unreachable.
- Keep the built-in palette generation recipe (`Palette.fromSeed`, warm paper as its normative
  source) untouched — this change removes a *merge* step, not the generator underneath it.

**Non-Goals:**

- Re-tuning any palette's colors. Ink iris, moss, and the rest render exactly as they did before;
  only which roles apply where changes.
- A migration for the stored `theme_palette` value. It's simply never read again — see "Migration
  Plan" below for why that's sufficient.
- Touching `app/lib/screens/shell/floating_nav_bar.dart` or
  `app/lib/screens/routines_list/routines_list_screen.dart`. Both are owned by other work in
  progress; if either needed a theme-related edit for this change, it would be called out here, and
  it doesn't.

## Decisions

### `AppTheme.light`/`dark` take one `Palette`, not two

The signature drops from `light([Palette? palette, Palette? accent])` to `light([Palette? palette])`,
defaulting to `Palette.inkIris`. `_build` reads `palette.scheme(brightness)` directly — no merge.

*Alternative considered:* keep both parameters and simply pass the same value for both at every call
site. Rejected: a two-parameter API that only ever receives the same argument twice is a trap for
the next reader, who has no way to tell "these must match" from "these are independent" without
reading `_build`. Collapsing to one parameter makes the invariant the type signature itself.

### `Palette.withAccent` is deleted, not deprecated

Its whole job was projecting one scheme's primary identity onto a different scheme's surface, which
only existed because backgrounds and accents used to differ. With no merge step, deleting it (and
its 74-case cross-product test in `accent_test.dart`) removes code that can no longer execute
correctly, rather than leaving a tempting, subtly-wrong shortcut for a future feature to reach for.

### The background palette setting is deleted, not hidden

`PaletteSetting`, `paletteSettingProvider`, `AppPrefs.paletteId`/`setPaletteId`, `PalettePicker`, and
the custom-hue sheet are removed outright rather than left in place and simply unwired from
`SettingsScreen`. Sara said the theme colors "are not needed anymore" — leaving the plumbing behind
"in case" is exactly the kind of two-settings-that-look-like-one surface area this change exists to
remove, and dead Riverpod providers and dead widgets cost real review attention the next time
someone reads this file wondering if they're still live.

### `Palette.fromStorageId` and the custom-palette storage plumbing are deleted

`customPrefix`, `customId`, `isCustom`, `storageId`, and `fromStorageId` existed only to round-trip
a custom hue through `shared_preferences` and to resolve `theme_palette`'s stored value back to a
`Palette`. Both call sites are gone. `Palette.fromSeed` — the generator every built-in but warm
paper actually calls — is untouched, since it takes an id and a hue as plain parameters and never
needed the storage layer at all. `Palette`'s `operator ==`/`hashCode` move from comparing
`storageId` to comparing `id`, which is the only identity built-in palettes (the only palettes left
standing) ever had that mattered.

*Alternative considered:* keep `fromSeed`'s custom-hue path "in case a future feature wants it."
Rejected: the recipe itself (`fromSeed` with an arbitrary id and hue) is exactly as available to a
future feature whether or not the specific `customId`/`isCustom` accounting used only by the deleted
picker sticks around. Keeping accounting for a caller that doesn't exist is speculative, not
defensive.

### The stored `theme_palette` value is left on disk, untouched

Sara's phone already has `theme_palette = custom:351` written to `shared_preferences`. This change
doesn't clear it, migrate it, or write anything new to that key — it just stops being read. A
migration step would be work spent moving a value that nothing will ever look at again.

### `Palette.defaultPalette` is deleted; the one remaining default is `Palette.inkIris`

`fix-appearance-defaults` introduced `Palette.defaultPalette` (`sea_glass`) specifically so the
*background* had a named fresh-install fallback independent of the accent's own `inkIris` default.
With no background palette, there is only one default left to name, and `accentSettingProvider`
already names it. `AppTheme.light`/`dark`'s own default parameter and `mascot_slot.dart`'s fallback
both point at `Palette.inkIris` directly now, rather than at a second named constant that would just
alias it.

### `accentName` moves into `accent_picker.dart`

It was defined in `palette_picker.dart` and imported by `accent_picker.dart` with `show accentName`
— an accent-picker concept that happened to live in the file next to it. Deleting
`palette_picker.dart` needs it to move, and `accent_picker.dart` is the only file that still calls
it, so it moves there outright rather than to a new shared location.

## Risks / Trade-offs

**Someone who deliberately picked a background different from their accent loses that combination
with no way back.** → True, and it's the whole point of the change: Sara doesn't want that
combination to be possible. `proposal.md` states the visible consequence plainly rather than
burying it — a fresh install looks different, and an existing install may look different the next
time it starts, and both are the intended result of "one choice colors everything."

**Deleting `Palette.withAccent`'s 74-case cross-product test removes real coverage.** → That
coverage existed to prove an accent's `primary` clears AA against *any* background's surface, a
question that stops existing once there's no background to pair an accent against. What replaces
it is narrower and still real: `theme_test.dart` proves a chosen palette's own surface and mascot
come through unchanged, and the existing `palette_test.dart` AA sweep (every built-in, plus the
generator across the full hue wheel) already proves each palette clears AA against its own surface
— which is now the only surface it's ever themed against.

## Migration Plan

None. `theme_palette` stays on disk, unread. `accent_color` is untouched by this change and keeps
meaning exactly what it already meant. No `schemas/*.json` file changes, and the Drift database
isn't touched.
