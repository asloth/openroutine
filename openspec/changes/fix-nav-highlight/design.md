## Context

See `proposal.md` — Why. `_Destination` wraps its icon-and-label `Column` in a `Padding` with
`EdgeInsets.symmetric(horizontal: 0, vertical: 5)`, inside an `AnimatedContainer` that paints the
selected fill with `AppRadius.pillBorder`, inside a `ConstrainedBox` capping the whole destination
at `maxWidth: 140` (with a `minWidth`/`minHeight` of `AppSpacing.touchTargetMin`, 48dp, for the
touch target). With zero horizontal padding, the `AnimatedContainer`'s width is exactly the
`Column`'s intrinsic width — which is the label's rendered width, since the label is wider than the
22dp icon. Measuring the real Lexend font at 12px confirms the numbers behind the bug report:
"Routines" renders about 52dp wide and the destination's content stacks up to about 51dp tall (22dp
icon + 4dp gap + ~15dp label line + 10dp vertical padding) — close enough to square that the pill
radius rounds it into a near circle.

## Goals / Non-Goals

**Goals:**

- Make the highlight visibly wider than tall, at both the default text scale and the label's 1.6x
  scale cap.
- Keep the bar on screen at 360dp width with the longer Spanish label, at the 1.6x cap.

**Non-Goals:**

- Retuning icon size, vertical padding, colors, the outer pill, the bottom gap, or the touch target
  minimum. None of those are what the user flagged, and the brief asks to restyle in place, not
  redesign.
- Handling text scales beyond 1.6x differently than today. `_labelScaleCap` already stops the label
  itself from growing past 1.6x; this change doesn't touch that ceiling or the wrap behavior past
  it.

## Decisions

### Horizontal padding of 14dp, added around the existing column

`_horizontalPadding = 14.0` is a named constant next to `_iconSize`, applied via
`EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: 5)` — the vertical inset is
untouched. 14dp roughly doubles the shortest label's rendered width without making the pill
noticeably wider than the app's other pill shapes (chips, the outer nav bar itself), and it's the
value named directly in the brief.

*Alternative considered:* deriving the padding from the destination's height, so the pill's aspect
ratio holds steady regardless of icon or font size. Rejected as unnecessary indirection: the icon
size and label font are fixed constants already, so a fixed padding constant gives the same result
with less to follow.

### `maxWidth` raised from 140 to 150

Padding is added inside the `ConstrainedBox`, so it competes with the label for the same budget.
The width that matters is the worst case: "Estadísticas" at the 1.6x label scale cap measures about
114dp on its own (measured against the real bundled Lexend 600-weight font, the weight the selected
state uses). Add the 28dp the new padding contributes on both sides and the destination needs about
142dp to stay on one line — 2dp more than the old 140dp cap allowed. 150dp clears that with a small
margin for rendering variance across devices, without meaningfully changing how much room the bar
needs: two destinations at 150dp each, plus the 4dp gap between them and the outer pill's own 10dp
of padting, is 314dp — comfortably inside a 360dp screen, and still short of it even if both
destinations happened to hit the cap at once (they don't, since only one label is ever the long
one).

*Alternative considered:* leaving `maxWidth` at 140 and accepting that "Estadísticas" wraps a line
earlier than it used to. Rejected: the label's own 1.6x cap exists specifically so it can hold one
line at that scale; letting the container's width undo that the moment padding is added would trade
one visual defect for a smaller one instead of fixing the bug cleanly.

## Risks / Trade-offs

**14dp is a judgment call, not a derived value.** → True. The brief calls out "about 14 dp"
directly, and the resulting aspect ratio (roughly 1.5–1.6x width to height across both labels at
both scales checked) reads clearly as a pill rather than a circle without ballooning past the
touch-target-sized icon it surrounds.

**Widget tests can't reproduce the exact on-device pixel measurements.** → `flutter test` doesn't
load the bundled Lexend font unless a test explicitly does, so a label's rendered width in a widget
test using the framework's substitute font differs from the real device. The tests this change
adds don't depend on absolute pixel values for that reason: they assert the highlight is wider than
tall and that it leaves a margin around the label on both sides — properties that hold regardless
of which font renders the label — and separately confirm the bar's total width stays within 360dp,
which `maxWidth` guarantees regardless of font metrics.

## Migration Plan

None. Presentation only; nothing persisted changes shape.
