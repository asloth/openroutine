## Context

See `proposal.md` — Why. `Palette` currently bundles two things a user might want to vary
independently: a background/surface identity (`surface`, `surfaceContainer*`, `outline`, the
neumorphic shadow pair) and an accent identity (`primary`, `primaryContainer`, and the pair each is
`on`). `PaletteSetting` already covers the first. This change adds a second, parallel setting for
the second, and a merge step that combines them into the `ColorScheme` the app actually themes with.

## Goals / Non-Goals

**Goals:**

- Let the accent vary independently of the background palette, defaulting to `Palette.inkIris`.
- Keep every accented color at or above the same AA bar the palette recipe already holds itself to.
- Give routine cards a single, explicit color source (`RoutineCardColors`) instead of reaching into
  `ColorScheme.primaryContainer` and hoping it's still the accent's.
- Keep `surfaceTint` untouched, so Material's elevation overlay on menus and dialogs doesn't turn
  purple just because the accent did.

**Non-Goals:**

- A custom hue for the accent. The accent picker offers `Palette.builtIns` only; the existing
  custom-hue sheet stays scoped to the background palette.
- Changing what the palette picker does, or which colors it governs. Surfaces, secondary, tertiary,
  and the neumorphic pair are all still the palette's.
- Making the fixed "upcoming" green themeable. It's deliberately outside both settings.

## Decisions

### The accent is merged into the base scheme, not swapped in wholesale

`Palette.withAccent(base, accent)` takes the base `ColorScheme` (from the chosen palette) and an
accent `ColorScheme` (from `Palette.inkIris` or whichever built-in is chosen) and returns the base
with five roles replaced: `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, and
`inversePrimary`. Everything else — `surface` and every container step, `secondary`, `tertiary`,
`outline`, `surfaceTint` — passes through from the base untouched.

*Alternative considered:* let the accent setting pick a whole `Palette` and theme with that palette
directly, ignoring the background palette's own primary. Rejected: that's indistinguishable from
just having one setting, which is the problem this change exists to fix. The merge is what makes
the two settings actually independent.

*Why `_meet` runs again here:* the accent's own `primary` already clears 4.5:1 against *its own*
`surface` (that's `palette_test.dart`'s existing contract). It doesn't automatically clear against a
*different* palette's `surface` — sea glass's ground isn't ink iris's ground. `withAccent` pushes the
accent `primary` through the same `_meet` helper the generator uses, against the base scheme's actual
`surface`, before handing it back. `onPrimaryContainer` is assumed to hold against `primaryContainer`
because both come from the same accent palette, which already guarantees that pairing.

### `surfaceTint` stays the base palette's, not the accent's

Material 3 tints elevated surfaces (menus, dialogs, popups) with `surfaceTint`, which defaults to
`primary`. If the merge touched it, every elevated surface across the app would tint purple the
moment someone picked an accent other than their palette's own — a much bigger visual change than
"routine cards and buttons are purple." `withAccent` deliberately leaves `surfaceTint` alone.

### `RoutineCardColors` is a new `ThemeExtension`, not a read of `colorScheme.primaryContainer`

A card that wants the accent's fill reads `context.routineCardColors.fill`, the same pattern
`NeumorphicContext` and `MascotPalette` already use. Reading `Theme.of(context).colorScheme.primaryContainer`
directly would work today, but nothing would stop a future change to the merge step (or to Material's
own role semantics) from quietly detaching it from "the accent, specifically." Naming it pins the
one thing routine cards actually depend on.

### The accent default is `Palette.inkIris`, never `Palette.defaultPalette`

`Palette.defaultPalette` (`sea_glass`) is what the *background* defaults to, and that's a separate
decision from what the *accent* defaults to. Product wants purple regardless of which palette ships
as the background default next. Hard-coding `AccentSetting`'s fallback to `Palette.inkIris` — not to
`Palette.defaultPalette` — keeps those two defaults from accidentally recoupling the next time either
one changes.

## Risks / Trade-offs

**Two independent settings is more state to reason about than one.** → True, and it's the entire
point of the change. The merge function is the one place that complexity lives; everything else
(the picker, the pref key, the notifier) is a copy of a pattern the codebase already has for the
palette.

**A contrast matrix across every palette × every accent is more test surface than the existing
per-palette check.** → It's also the only way to actually verify the claim in the Goals section.
Six palettes as base times six as accent times two brightnesses is 72 checks, each cheap and pure —
no widget pump required.

## Migration Plan

None. Nothing persisted changes shape; `accent_color` is a new, independent key that defaults to
absent, and absent resolves to purple.
