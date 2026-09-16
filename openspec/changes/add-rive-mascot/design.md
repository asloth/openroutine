## Why the swap lives inside the widget

`MascotSlot` was written as a slot, not a drawing, precisely so this change would be local. The mood enum stays the vocabulary screens speak; the artboard's triggers and flags stay private to this file.

## Mood mapping

| `MascotMood` | Artboard |
|---|---|
| `idle` | the state machine's resting state: breathing, blinks, glances |
| `focused` | `isThinking` — thought dots, eye up |
| `resting` | `isSleeping` — eye closed, slow breathing, Z's |
| `cheering` | the `celebrate` trigger — a two-hop jump, then back to idle |

`wave` and `tap` also exist in the file. `tap` fires from the artboard's own listeners when the pet is pressed. `wave` has no mood yet, so nothing fires it.

## Colour

The artboard's colours are data-bound rather than baked, so the pet takes `MascotPalette.body` and `.ink` from the theme, plus `colorScheme.onSurfaceVariant` for the thought dots and Z's — those float outside the pet and have to contrast with the screen, not the fur. The generated palettes already push the body until it clears the dark ground and the ink until it clears the body, so one set of values works in both themes, as `colors.dart` intends.

## Stillness

Rive loops forever by default, which fights both the product's calm goal and `pumpAndSettle` in widget tests. The controller is set inactive after the warm-up. Reduced motion skips the warm-up entirely. Because an inactive controller also stops hit testing, a `Listener` above the widget wakes the pet on a press, so a poke still works after it has settled.

## Fallback

`RiveWidgetBuilder` reports loading and failure states. Both render the previous hand-drawn painter, which stays in the file. That keeps the layout intact on a platform where `rive_native` cannot load, and it is what the widget tests exercise.
