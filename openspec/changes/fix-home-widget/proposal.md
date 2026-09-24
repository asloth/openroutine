# Fix the home screen widget's tap and colors

## Why

Two things are broken on the widget:

- **Closing a run you started from it throws.** A tap used `go()` to jump straight to the timer, which left the timer as the only page. Its Close button and the back gesture both pop, and popping the only page throws "There is nothing to pop".
- **It ignores your colors.** It shipped with a copy of the warm-paper palette in its resources. The app's default is now Ink Iris, and whichever palette you choose in Settings never reaches the widget.

## What changes

- A widget tap resets to the routine list and pushes the timer on top, so Close and Back land on the list, whatever screen the app was on.
- The published snapshot gains an optional `theme`: your theme mode and your palette's colors for light and dark. The widget tints its background, text, and dividers with them, and republishes when you change the accent or theme mode.

The snapshot is internal, not part of `schemas/`, so this isn't a breaking change. `theme` is optional, and a widget without it keeps its resource colors.

## What doesn't change

The widget's layout, its contents, the tap target, and Android-only scope.
