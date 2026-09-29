## Context

See `proposal.md`. `_Summary` laid its content out in a `ListView` with a fixed 56px top pad, so a
short summary hugged the top of the screen.

## Goals / Non-Goals

**Goals:**

- Ochi and the summary sit in the middle of the screen when they fit.
- A short, tasteful confetti moment on a finished run, in the active palette.

**Non-Goals:**

- Any sound. In-app sounds are their own change.
- Changing Ochi's cheering animation, or the order of the finished screen's controls.

## Decisions

### Centered `Column` in a `SingleChildScrollView`

A `LayoutBuilder` gives the viewport height, and a `ConstrainedBox` with that `minHeight` lets
`MainAxisAlignment.center` center the content when it fits and scroll when it doesn't. The content
is short, so losing the `ListView`'s lazy building costs nothing.

### Hand-rolled painter instead of a confetti package

About 180 lines of `CustomPainter` with a fixed seed. It keeps the pieces in the palette's
`primary`, `secondary`, `tertiary`, and container roles, which accent-relative colour requires, and
avoids a dependency for one moment. The pieces follow a closed-form path (drag plus gravity), so
the painter holds no per-frame state and repaints from a single `AnimationController`.

### Burst from Ochi, not rain from the top

The confetti pops out of Ochi's center, so it reads as Ochi's party rather than a screen effect.
It paints over its child without clipping, and `CustomPaint` doesn't hit-test, so Back to today
stays tappable throughout.

## Risks / Trade-offs

- A stopped run gets no confetti. That's deliberate: stopping early isn't a failure, but it isn't a
  party either.
