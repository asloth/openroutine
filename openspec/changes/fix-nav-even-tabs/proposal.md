## Why

Two more reports came in from the Pixel 9a: "the today circle is more circular," and "the routines
is more big on the sides." `FloatingNavBar` lays its three destinations out in a
`Row(mainAxisSize: MainAxisSize.min)`, each wrapped in a `Flexible`, so every destination's slot is
only as wide as its own icon or label plus the fixed horizontal padding. "Today" is the shortest
label, so its slot — and so its selected highlight — comes out closest to square of the three.
"Routines" is the longest label, so its slot is visibly wider than the other two, and the bar reads
as uneven.

## What Changes

- Give every destination the same slot width: the width of the widest one. Wrap the row in
  `IntrinsicWidth` and switch each destination from `Flexible` to `Expanded`, so `RenderFlex`
  allocates each flex child the same share of the row's intrinsic width.
- Update the doc comments that described the old, content-sized slot widths (`_horizontalPadding`
  and the `ConstrainedBox` comment on `_Destination`) so they describe the shared-slot-width layout
  instead.

## Capabilities

### Modified Capabilities

- `floating-nav` — adds the guarantee that every destination's slot, and so its selected highlight,
  shares the widest destination's width, on top of the existing pill-shape guarantee from
  `fix-nav-highlight`.

## Impact

**Code.** `app/lib/screens/shell/floating_nav_bar.dart` only: the row wrapper and the flex-child
type for the three destination slots. Icons, the label font, size and weights, colors and theme
roles, the border, the pill's position and bottom gap, destination order, the 1.6x text-scale cap,
semantics, and tap behavior are all unchanged.

**Tests.** Extends `app/test/screens/floating_nav_bar_test.dart` with a test that measures all
three destinations' widths and asserts they match, and a test that the highlight stays a pill when
the shortest label ("Today") is the one selected. The existing large-text-scale and 360dp-fit tests
are unchanged and stay green.

**Storage and schema.** None.

**i18n.** None. No new user-facing strings.

**Rollback.** Reverting restores the content-sized slot widths from `Flexible`. Nothing persisted
changes shape, so there's nothing to unwind.
