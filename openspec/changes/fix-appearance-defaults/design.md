## Context

See `proposal.md` — Why. `AppTheme._build` already configures fifteen component themes from the palette's `ColorScheme`; this adds the sixteenth. `Palette.fromStorageId` is the single resolution point for a persisted identifier, but it names `warmPaper` twice as a fallback, and `AppTheme.light`/`dark` name it twice more as default parameters.

## Goals / Non-Goals

**Goals:**

- Make the default palette a single named thing, so changing it is one edit.
- Make a forgotten component theme detectable by a test rather than by noticing it on a phone.

**Non-Goals:**

- Re-tuning any palette's colours. The generated schemes are unchanged.
- Auditing every remaining component for role correctness. This fixes the one that is wrong and adds the test that would catch the next one in the same place.

## Decisions

### `warm_paper` stays the normative palette, but stops being the default

`DESIGN.md` continues to document warm paper's tokens as the design system's reference, and `Palette.fromSeed` still derives every other palette from its HSL structure. Only the shipped default changes.

*Alternative considered:* re-documenting `DESIGN.md` against sea glass. Rejected because warm paper is the generative source — the lightness ladder, saturation falloff and hue offsets that make every other palette hold together are *its* structure. Documenting a derived palette as the reference would describe the output while hiding the rule that produced it. `DESIGN.md` gains a sentence distinguishing the reference palette from the shipped default instead.

### The default is a named constant, not a repeated literal

A single `Palette.defaultPalette` replaces the four `warmPaper` fallbacks.

*Rationale:* the reason this change is bigger than one line is that the default was written four times. Naming it means the next change to it is one line, and it distinguishes "the palette we ship" from "the palette everything is derived from", which are now different things and were previously the same by accident.

### The segmented button borrows the chip's roles rather than inventing its own

`selectedColor` uses `primaryContainer`, matching the existing `chipTheme`.

*Alternative considered:* giving the segmented button its own distinct role to differentiate it from chips. Rejected: a selected segment and a selected chip communicate the same thing, and the app already made that decision for chips. Two roles for one idea is how palettes drift apart.

## Risks / Trade-offs

**A test asserting one component's colour does not prove the other fifteen are right.** → True, and worth stating plainly rather than implying broader coverage. The test added here pins the component that was actually wrong; a general "no component falls back to framework defaults" assertion is not expressible against Flutter's theming, since an unset component theme is indistinguishable from a deliberately-default one.

**Changing the default affects only new installs.** → Intended, and the reason the spec includes a scenario for it: someone who deliberately chose warm paper must keep it. This device already stores `sea_glass`, so the change will not be visible on it — the fix is verifiable only on fresh state.

## Migration Plan

None. Presentation only, nothing persisted changes shape, and stored `sea_glass` values are already valid.
