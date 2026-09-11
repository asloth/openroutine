## Why

The routine detail screen is the last stop before someone starts a routine, and it still wears the
neumorphic idiom the app is moving away from: an `AppBar` strip, shadowed cards, and a
`primaryContainer` history dot that no longer matches the accent color a routine card carries
everywhere else. `add-tinted-surfaces` landed the flat-surface widget set this screen needs, and
`add-accent-color` gave routine cards a named color source (`context.routineCardColors`). This
change spends both on the one screen: no `AppBar`, a tinted moment chip and summary card, and a
history strip whose dots read the same accent the rest of the app now uses.

Every control keeps its place. This is a restyle, not a redesign: the same actions, in the same
order, reading a flat fill instead of a shadow pair.

## What Changes

- Remove the `AppBar`. Replace it with a 48px top row: a neutral `SoftCircleButton` Back on the
  left, and neutral `SoftCircleButton`s for Share, Edit, and More on the right, 8px apart. More
  keeps today's `PopupMenuButton` and its Delete confirmation, styled as a soft circle with a
  horizontal "more" icon. `SafeArea(bottom: false)` and an `AnnotatedRegion<SystemUiOverlayStyle>`
  replace the status-bar contrast the `AppBar` used to supply for free.
- Render the routine name in `AppTypography.pageTitle` and the moment name as a small tinted chip,
  both reading `context.routineCardColors`.
- Replace the neumorphic summary card with a `TintedCard`, keeping its two-column "Estimated time" /
  "Last 7 days" layout, and restyle the seven history dots as 12px circles whose filled and ringed
  states read `context.routineCardColors.onFill` instead of `colorScheme.primary`.
- Group every step row inside one bordered, clipped container instead of one `NeumorphicCard` per
  step, with a hairline divider between rows and none after the last.
- Everything else — Start Timer's enabled rule and helper text, Add step, reordering, the empty and
  single-step cases, every tooltip and semantics label — stays exactly as it behaves today.

## Capabilities

### New Capabilities

- `routine-detail` — the routine detail screen's structure and behavior: its header controls, the
  summary card and history dots, the step list, and the accessibility floor (hit targets, text-scale
  tolerance) it holds itself to.

## Impact

**Code.** `app/lib/screens/routine_detail/routine_detail_screen.dart` and
`app/test/screens/routine_detail/routine_detail_screen_test.dart`. No shared widget, theme token, or
other screen changes.

**Storage and schema.** None. This is presentation only.

**i18n.** None expected. Every string this screen shows already exists in `app_en.arb` and
`app_es.arb`; the restyle changes how they're laid out, not what they say.

**Rollback.** Reverting the one screen file and its test restores the `AppBar`-and-neumorphic
version. Nothing else in the app references this screen's internals.
