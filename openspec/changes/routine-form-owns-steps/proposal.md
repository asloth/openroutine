# Build the whole routine on one screen

## Why

A routine with no steps can't be run, but the form can't stop you making one.
It holds only a name and a schedule, so it saves an empty routine and then
pushes you into the step form to finish the job — a chain the code itself
calls out:

> A brand-new routine has no steps, and a routine with no steps cannot be run
> — so "saved" is never the end of the job here.

Back out anywhere along that chain and an empty routine is already on disk.
Save is also a checkmark in the app bar, the quietest control on a screen
whose whole purpose is to produce one thing.

## What changes

**The form owns its steps.** A steps list with an inline Add step, held in
memory until you press Save. Nothing reaches storage until then, so backing
out leaves nothing behind.

**A routine needs at least one step.** Save is disabled until there is one,
so an empty routine can no longer exist.

**Save becomes the main control**: a full-width filled button pinned to the
bottom, reading `Save · 2 steps, 5 min` so you can see what you're about to
make without counting it yourself.

**The fields get the redesign's treatment**: the name as a large borderless
field hinting "Name it", the schedule and days grouped on one white card,
`Scheduled` renamed to `At a set time`, a `REPEAT` label over single-letter
day toggles, and `−` / `+` steppers on the start time for a nudge, with the
time itself still opening the picker for a jump.

## Delivery

Two slices:

1. The restyle, with the chain to the step form still in place.
2. Steps inside the form, the one-step rule, and the count on the button.

## What doesn't change

The step form itself keeps its emoji picker, templates, duration and Low Mode
marker. It gains a draft mode that returns a step instead of writing it.

Routine Detail keeps its own step management. Editing an existing routine now
has two doors, which is worth tidying later but is not this change.
