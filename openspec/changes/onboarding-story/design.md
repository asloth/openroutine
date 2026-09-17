## Context

The Rive pet already has idle, sleep, wave, celebrate, and the in-run reactions. `MascotSlot` takes a mood and a one-time `MascotCue`, and runs for a warm-up before it settles.

## Decisions

**One mascot for the whole story.** The mascot sits on a stage below the page text rather than inside each page, so it's the same pet walking from beat to beat. The text and the demo card swipe; the pet reacts.

**A controller per beat, not timers.** Each beat plays a short script (about 2.4 seconds) on an `AnimationController`, and cues fire as it crosses fixed points. Widget tests can advance it with `pump`, nothing leaves a pending `Timer`, and reduced motion jumps straight to the end state.

**The pet runs in Flutter and in Rive.** Rive's `run` plays the stride on the spot, while a `SlideTransition` carries the slot from off-screen to the centre. Horizontal travel belongs to the layout, and the artboard stays a fixed size.

**Moves are generated.** `rive/mascot/build/gen_story.py` adds `run`, `jump`, and `bounce` to `scene.rml`, pinning every property the other states key, including the feet, so a blend never inherits a stray value.

**The builder takes a starting mode.** `/routines/new?mode=scheduled` (or `flexible`) sets `RoutineFormScreen.initialMode`. Onboarding goes to `/routines` first and pushes the builder on top, so saving or backing out lands on Today.

## Risks

- The mascot's moves can't be seen in widget tests, because tests use the stand-in drawing. Check them on the phone.
