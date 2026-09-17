## Context

See `proposal.md` — Why. `_Running.build` and `_SummaryState.build` each construct their own
`MascotSlot` with a numeric `size:` literal (168 and 124), added independently as the running and
finished screens were built out under `redesign-timer-run`. Nothing in the code says these two
should match; they just happened to start apart, and stayed apart.

## Goals / Non-Goals

**Goals:**

- Make the mascot the same rendered size on the running and finished screens.
- Make that sameness structural — a future edit to one screen's mascot size can't silently
  reintroduce the mismatch without also changing the other screen, because there's only one constant
  to change.

**Non-Goals:**

- Anything inside `MascotSlot` itself (`app/lib/widgets/mascot_slot.dart`). That widget's internals,
  including how it renders at a given `size`, belong to another change.
- Any other visual property of the finished screen: title, summary line, the Adjust estimate card,
  Back to today, padding, spacing, or the mascot's mood logic (cheering, or resting when abandoned).
- The running screen's layout. It already used the size this change keeps; only the constant's
  origin changes, not its value or effect there.

## Decisions

### One private top-level constant, not a shared design-tokens file

`const _mascotSize = 168.0;` lives at the top of `timer_screen.dart`, next to the `export` statement,
with a doc comment saying why it exists. Both `MascotSlot(size: 168, ...)` call sites now read
`size: _mascotSize`.

*Alternative considered:* pulling `168` into a shared spacing/sizing constants file (the way
`AppSpacing` covers touch targets). Rejected as bigger than the fix calls for — this constant only
has two call sites, both in this file, and neither is likely to need a different mascot size for
unrelated reasons. A file-local constant is the smallest change that removes the drift risk.

### The value is 168, not a new number

168 is the running screen's existing size, which is also the one the owner is asking the finished
screen to match ("more big like in the routine run"). The finished screen moves up to it, not the
other way around.

## Risks / Trade-offs

**A bigger finished-screen mascot pushes `Back to today` further down.** The finished screen is a
`ListView`, which only builds children within its viewport plus a small cache extent. Going from a
124px to a 168px mascot (+44px, plus its surrounding `SizedBox`) was enough, at the widget-test
default 800×600 surface, to push `Back to today` past that extent, so `find.text` stopped finding it
without scrolling. → Fixed by having the existing
`finishing the run shows the summary and writes a log` test call `tester.scrollUntilVisible` before
asserting on it. This is a widget-test mechanic, not a real change to what's on the finished screen;
the `ListView` already required scrolling for the calibration card and both buttons beneath it.

## Migration Plan

None. Presentation only; nothing persisted changes shape.
