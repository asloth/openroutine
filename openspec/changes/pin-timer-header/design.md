## Context

See `proposal.md` — Why. `routine_detail_screen.dart` already solves this same shape of problem: a
`SafeArea` wrapping a `Column`, a fixed header `Padding`/`Row`, and an `Expanded` `ListView` for
everything below it. The timer screen's running view never got that split; it's one `ListView` with
the header as its first child.

## Goals / Non-Goals

**Goals:**

- Make the header immune to scroll offset, matching `routine_detail_screen.dart`'s structure.
- Keep the unscrolled screen pixel-identical: same padding, same gap before the mascot.

**Non-Goals:**

- Restyling the header or reordering its controls.
- Touching `_Summary`, which has no circular control in its header area — its `MascotSlot` is
  decorative artwork inside the scrollable content, not a fixed control that needs pinning.

## Decisions

### Move the header out of the `ListView`, not just reorder it

The header row becomes a `Padding` sibling of an `Expanded(ListView(...))` inside a `Column`. The
`ListView`'s old top padding (8) and the `SizedBox(height: 28)` gap before the mascot become the new
`ListView`'s top padding (28), so the unscrolled layout doesn't move: same 8px above the header,
same 28px between the header and the mascot below it.

*Alternative considered:* keeping a single `ListView` and using a `SliverPersistentHeader` to pin the
row. Rejected — it's more machinery for the same result, and it doesn't match the simpler pattern
`routine_detail_screen.dart` already established for this exact problem.

## Risks / Trade-offs

**A `ListView` that virtualizes far enough can drop an off-screen child from the render tree.**
That's what made this bug easy to demonstrate in a test: dragging a long run's list far enough
un-mounts the header entirely when it's a scrolling child, rather than merely moving it. Once it's a
`Column` sibling of the `Expanded` `ListView`, it can't be dropped — it isn't part of the scrollable
at all.

## Migration Plan

None. Presentation only.
