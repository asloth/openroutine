## Why

`MascotSlot` has always been a placeholder. Its own doc comment says so: a hand-drawn stand-in, with the API shaped so the Rive pet could replace the drawing and no call site would move. The pet now exists — `rive/mascot/` builds `mascot.riv` with an idle loop, a celebrate hop, a wave, a thinking loop, a sleepy loop, and a tap reaction.

This change swaps the drawing for the file, on the screens that already show the slot, so we can judge how it feels on the phone before building anything else around it.

## What Changes

- Add the `rive` package and bundle `app/assets/mascot.riv`.
- Render the pet inside `MascotSlot`, keeping its public API: `mood`, `size`, and `semanticLabel`.
- Map `MascotMood` onto the artboard: `focused` holds the thinking loop, `resting` holds the sleepy loop, `cheering` fires the celebrate trigger, `idle` is the resting state of the machine.
- Feed the theme's `MascotPalette` into the artboard's colour properties, so the pet follows the palette and accent the user picked.
- Keep the warm-up-then-settle behaviour: the pet moves for about eleven seconds, then stops advancing. A mood change or a press wakes it again.
- Keep the hand-drawn stand-in as the fallback while the file loads, and if it ever fails to load.

## Capabilities

### New Capabilities

- `mascot` — what the pet reacts to, how it follows the theme, and when it holds still.

## Impact

**Code.** `app/lib/widgets/mascot_slot.dart` (the swap), `app/pubspec.yaml` (dependency and asset). No call site changes: the routines list and the stats screen already pass a mood.

**Storage and schema.** None. Nothing under `schemas/` changes.

**Existing users.** The pet looks different. Nothing else about the app changes.

**i18n.** None. The slot is decorative unless a caller passes `semanticLabel`, which is unchanged.

**Size.** `mascot.riv` is 25KB. The `rive` package brings `rive_native`, which adds a platform library to the APK.
