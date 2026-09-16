## Context

See `proposal.md`. The design's tab bar is a full-width strip; the user chose to keep the floating pill and add a third destination.

## Decisions

### Today keeps `/routines`

Renaming paths would touch onboarding, the router's initial location, and the home screen widget's launch handling, and onboarding has uncommitted work in progress. Paths are internal, so Today stays at `/routines`, Routines lives at `/library`, and Streaks stays at `/stats`.

### Three destinations shrink instead of overflowing

With two destinations, each could size to its label. Three at 1.6x on a 360dp phone overflowed even with short Spanish labels. The pill now caps itself at the screen width less a 12dp margin, each destination is `Flexible`, and a label that still doesn't fit wraps onto a second line.

### Routines is a plain list for now

It reuses home's routine row. The screen gets its own design round later.
