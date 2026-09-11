## Why

The user reported the bottom bar's selected highlight as "too narrow." On the Pixel 9a, at the
default text scale, the Routines destination's highlight comes out about as tall as it is wide:
`_Destination` gives its icon-and-label column no horizontal padding, so the highlight's width is
exactly the label's own width — about 54dp for "Routines" at 12px Lexend, against a height of about
51dp for the icon, the gap, the label, and the vertical padding stacked up. `AppRadius.pillBorder`
rounds a shape that close to square into a near circle, and the label's straight-edged rectangle
pokes out of it at both bottom corners.

## What Changes

- Give the destination's icon-and-label column 14dp of horizontal padding, so the highlight reads
  as a wide pill that fully encloses its label rather than hugging it exactly.
- Raise the destination's `maxWidth` constraint from 140 to 150, so the added padding doesn't force
  the longer Spanish label, "Estadísticas," to wrap a line earlier than it needs to at the label's
  1.6x scale cap.

## Capabilities

### New Capabilities

- `floating-nav` — the shape and sizing guarantees the floating bottom bar's selected highlight
  must meet: wide enough to read as a pill, and sized to hold its label rather than crop it.

## Impact

**Code.** `app/lib/screens/shell/floating_nav_bar.dart` only: one padding constant and one
constraint value. No behavior outside `_Destination`'s highlight changes — icon sizes, colors, the
outer pill, the 16dp bottom gap, semantics, the two destinations, and the 48dp minimum touch target
are all unchanged.

**Tests.** A new `app/test/screens/floating_nav_bar_test.dart` exercises the highlight's geometry
directly, without booting the full app shell. `app/test/screens/app_shell_test.dart`'s existing nav
bar coverage is unchanged and stays green.

**Storage and schema.** None.

**i18n.** None. No new user-facing strings.

**Rollback.** Reverting restores the zero-padding, 140dp-capped highlight. Nothing persisted
changes shape, so there's nothing to unwind.
