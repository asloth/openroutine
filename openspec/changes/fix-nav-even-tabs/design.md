## Context

See `proposal.md` — Why. `FloatingNavBar` builds a `Row(mainAxisSize: MainAxisSize.min)` whose
children are `Flexible(child: _Destination(...))`. `Flexible` defaults to `FlexFit.loose`, so each
child is laid out at its own preferred (intrinsic) size, up to the space available — there's no
mechanism that ties one destination's width to another's. Each `_Destination` is sized by its
`ConstrainedBox` (`minWidth`/`minHeight` of `AppSpacing.touchTargetMin`, `maxWidth: 150`) wrapping
an `AnimatedContainer` whose own size follows its `Column`'s content plus
`_horizontalPadding` (14dp) on each side. "Today" is short, so its slot — and the
`AnimatedContainer` highlight inside it — comes out closest to as wide as it is tall. "Routines" is
the longest label, so its slot is the widest, and the bar's three slots visibly differ.

## Goals / Non-Goals

**Goals:**

- Make all three destination slots the same width: the width of the widest one, whichever
  destination that happens to be, in either shipped locale.
- Keep the pill's total width within the screen at a 360dp width, at both the 1.6x and 2.0x label
  scale caps already covered by the existing tests.
- Keep every other visual property untouched: icons, label styling, colors, the border, the pill's
  position and bottom gap, destination order, the 1.6x scale cap, semantics, and tap behavior.

**Non-Goals:**

- Retuning `_horizontalPadding`, `maxWidth`, icon size, or any other constant `fix-nav-highlight`
  already settled. This change only ties the three slots' widths together; it doesn't change how
  wide any individual destination's content wants to be.
- A generalized N-destination layout. Three is the fixed count `FloatingNavBar` ships with; nothing
  here assumes more.

## Decisions

### `IntrinsicWidth` around the `Row`, `Expanded` instead of `Flexible` for each slot

Wrapping the `Row` in `IntrinsicWidth` and switching each destination's flex wrapper from
`Flexible` to `Expanded` gives every slot the same width. `RenderFlex`'s intrinsic-width
computation for flex children (`Expanded`/`Flexible` with `flex > 0`) is documented as: the largest
flex child's own preferred width, multiplied by the sum of the flex factors. `IntrinsicWidth` asks
the `Row` for that value, then lays the `Row` out at that fixed width. With three `Expanded`
children of equal `flex: 1` (the default), the `Row` then divides that width three ways equally —
which, by construction, is exactly the widest child's own width. `Expanded`'s tight fit (as opposed
to `Flexible`'s loose fit) is what forces each slot, and so the `AnimatedContainer` highlight inside
it, to actually fill that shared width rather than staying at its own smaller preferred size.

The existing `ConstrainedBox` (`maxWidth: 150`) on each `_Destination` still bounds the widest
child's own preferred width during the intrinsic-width pass, before `IntrinsicWidth` reads it — so
the 360dp-screen guarantee `fix-nav-highlight` established for a single destination holds for the
shared slot width too.

*Alternative considered:* a `CustomMultiChildLayout` that measures each destination and lays them
out at the max. Rejected: `IntrinsicWidth` + `Expanded` is a few lines using ownership Flutter
already provides for exactly this shape (equal-width flex children), against a hand-rolled layout
delegate that would duplicate what `RenderFlex` does natively.

*Alternative considered:* a fixed pixel width per destination, sized to the longest label across
both locales. Rejected: it reintroduces a hand-measured magic number the way the old `maxWidth: 140
→ 150` change in `fix-nav-highlight` did, and it stops adapting if a label changes length — the
`IntrinsicWidth` approach adapts automatically to whichever destination is currently the widest.

## Risks / Trade-offs

**`IntrinsicWidth` costs an extra layout pass.** → True, but bounded: it's asked to lay out the same
three-destination `Row` twice (once to measure, once to render) on every rebuild. At three fixed
children, this is not a hot path — `FloatingNavBar` rebuilds only on nav taps and text-scale or
theme changes, not per frame.

**Equal widths could, in principle, force a destination past `maxWidth: 150`.** → Can't happen here:
the value `IntrinsicWidth` reads is each child's own `computeMaxIntrinsicWidth`, which already
routes through the `ConstrainedBox`'s `maxWidth: 150` clamp. The shared slot width is the widest
already-clamped value, so it can never exceed 150 itself.

## Migration Plan

None. Presentation only; nothing persisted changes shape.
