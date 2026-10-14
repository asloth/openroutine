## Context

See `proposal.md`. The running timer's mascot rests in `idle` and plays one-shot reactions from
`MascotCue`s that `_TimerScreenState._react` reads off timer-state changes. `MascotSlot` stops
advancing the Rive controller about 11 seconds after any change, so the pet never moves forever.

## Goals / Non-Goals

**Goals:**

- Ochi holds a coffee through any step planned for more than 5 minutes, and takes an occasional sip.
- Keep the calm rule: a still pose most of the time, with a short movement now and then.

**Non-Goals:**

- Reacting to how long a step has actually run. The trigger is the planned duration.
- Coffee anywhere other than the running timer.

## Decisions

### The planned duration decides

A step whose `durationSeconds` is over 300 gets the coffee from its first second. A step of exactly
5 minutes, or one with no time, doesn't. It's predictable, and the mug is there for the whole of a
long step rather than appearing partway through.

### The screen fires the sips, the slot only holds the cup

`_TimerScreenState._syncSips` runs from the same listener as the other reactions. While a long step
runs, a 45-second `Timer.periodic` sets a fresh `MascotCue(MascotReaction.sip)`. The key is the
step's index and id, so the timer's per-second ticks don't restart it. Pausing, a short step, or
the end of the run cancels it, and `dispose` does too. Keeping the clock on the screen keeps
`MascotSlot` free of timers and lets the existing cue tests cover sips.

Each sip wakes the slot for its usual warm-up, then it settles back to a still pose. Under reduced
motion the slot never advances, so a sip cue changes nothing on screen.

### The mug is pinned hidden in every other animation

Rive keeps the last value of any property a state doesn't key. Every existing animation now keys
the mug and steam as hidden, so a reaction fired while Ochi holds the cup tucks it away during the
blend, and idle never inherits a visible mug. The coffee states pin every property the other
animations key, using the rest values from `idle` and the reactions.

### Steam in `faceColor`

The plan was `accentColor`, but the wisps sit over the fur, not the screen behind it. Cream reads
on every palette's body in both themes, and `accentColor` is meant to contrast with the background.

## Risks / Trade-offs

- A sip that lands while a reaction plays is dropped. The next one comes 45 seconds later.
- Resuming after a pause starts the 45-second countdown over.
