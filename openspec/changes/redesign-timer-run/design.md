## Context

See `proposal.md`. The source is the `isRun` branch of `OpenRoutine.dc.html`. `TimerState` already provides everything the design needs: the current step and index, elapsed time and the estimate zone, `canPostpone`, `skip`, the outcomes recorded so far, and the run order after a step is put off.

## Decisions

### The clock keeps counting up

The design counts down. The timer counts up on purpose, and a step can run past its estimate with no overtime text; the clock changes colour instead. That stays, and the new bar fills to the estimate and then holds full.

### Pause stays, Restart step goes

The design has neither control. Pause stays, because without it there's no way to stop the clock mid-step. It moves into the header as a small control, so Done stays the one obvious action. Restart step is removed.

### The mascot rests instead of thinking

The Rive pet's thinking loop keeps moving for the whole step. The design's own note asks for stillness while a step runs, so the mascot uses its idle mood, which settles after a short warm-up.

### Rest of the run follows the live order

The list reads `TimerState.steps`, so a step put off with Do it last moves to the end of the list, exactly as it will run. A step's mark comes from its recorded outcome: filled when done, struck through when skipped.

### Minutes left

The sum of the estimates for the current step and every step after it, minus the time already spent on the current step, never below zero, rounded up to a whole minute. Steps with no set time add nothing.
