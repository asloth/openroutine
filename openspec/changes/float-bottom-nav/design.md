## Context

See `proposal.md` — Why. `AppShell` (`app/lib/screens/shell/app_shell.dart`) hosts a
`StatefulNavigationShell` under a stock `NavigationBar`, wired up by
`replace-overflow-with-bottom-nav`. `add-tinted-surfaces` landed the flat-surface widget
set (`TintedCard`, `SoftCircleButton`, `PageHeader`, `SectionLabel`,
`SegmentedProgress`, `PillSegmentedControl`) that four parallel changes are applying to
individual screens; none of those six widgets fit a two-destination bottom bar, so this
change adds a seventh, purpose-built one rather than stretching an existing one to a job
it wasn't shaped for.

## Goals / Non-Goals

**Goals:**

- Remove the last piece of stock Material navigation chrome from the shell.
- Keep every behavioral guarantee `app-navigation` already established: two
  destinations, no overflow menu, state preserved across a switch, a second tap on the
  current destination returning to its root.
- Give the body room to scroll under the bar, and make that room discoverable through
  ordinary `MediaQuery` padding rather than a constant a screen has to know about.
- Keep the bar's labels legible at a text scale well past what Material's own bar
  tolerates.

**Non-Goals:**

- Touching a screen. Four parallel changes own that; this change owns the shell alone.
- Adding, removing, or reordering a destination. Still Routines and Statistics, in that
  order — see `replace-overflow-with-bottom-nav/design.md` for why it's two rather than
  three.
- A new `ThemeExtension` or new `ColorScheme` role. Every color the pill uses —
  `surfaceContainerLowest`, `outlineVariant`, `primaryContainer`, `onPrimaryContainer`,
  `onSurfaceVariant` — already exists on `ColorScheme`.

## Decisions

### A dedicated widget, not a stretched `TintedCard`

`TintedCard` takes one fill and one foreground color; this bar needs two destinations
that independently animate between a filled and an unfilled state, plus the pill's own
border and padding rules. Coercing that into `TintedCard` composition would need as much
code as a small purpose-built widget, with a worse fit — `TintedCard`'s docs describe a
single tappable surface, not a bar of them. `floating_nav_bar.dart` is new for the same
reason `tinted.dart`'s widgets are siblings rather than one widget doing six jobs.

### Per-destination `AnimatedContainer`, not `Material.animationDuration`

`Material` animates a `color` change on its own, but its curve is fixed internally
(`Curves.fastOutSlowIn`) and isn't a caller-supplied parameter. Every other animated
value in this codebase — `TintedCard`'s press deform, `SoftCircleButton`'s press deform
— passes both a duration *and* a curve through `AppMotion` and the reduced-motion
resolver. Wrapping the fill in an explicit `AnimatedContainer` keeps that same
discipline instead of relying on a framework default that happens to animate but that
this change didn't choose. `Material` still hosts the `InkWell` for its ripple; it just
isn't asked to animate anything itself.

### `Scaffold.extendBody`, not a manual `SafeArea` offset in the body

Flutter's own `Scaffold` already does the thing the brief for this change asks for:
with `extendBody: true`, the body's ambient `MediaQuery.padding.bottom` becomes
`max(the device's safe-area inset, the bottomNavigationBar's rendered height)` (see
`scaffold.dart`'s `_BodyBuilder`). That means a screen that pads its list by
`MediaQuery.of(context).padding.bottom` — the ordinary, portable way to clear a bottom
bar — sees the pill's real height without this change needing to publish a constant
for it. The alternative, a hand-rolled `SafeArea` wrapped around the pill from inside
the body, would only help screens that specifically knew to add it, and would drift out
of sync with the pill's height the moment either side changed independently.

### A textScaler clamp at 1.6x, applied only to the label

Material's `NavigationBar` clamps its own labels at 1.3x regardless of what the system
asks for — undocumented in the framework's public API, but real: past that scale, its
label stops growing. This bar has no such built-in ceiling, and the brief for this
change asks for none unless one turns out to be necessary.

One is. With the icon stacked above the label rather than beside it, each destination's
width is set by its label alone, and two of them sit side by side inside one pill on
whatever phone the app is running on. At an uncapped 2.0x system scale, the longer of
the two locale strings (`Estadísticas`) laid out twice overflows a 360px-wide phone —
confirmed by running the widget test at that scale before adding the clamp, not assumed.
1.6x is the floor this change's brief allows, chosen deliberately over anything lower:
it's already more room to grow than Material's own bar gives its labels, and every
increment closer to 2.0x buys more of the system's actual request. Past 1.6x, a
destination's `maxWidth` of 140 logical pixels — chosen so two destinations plus the
pill's fixed chrome (5px padding, 4px gap, 1px border on each side) stay under a 360px
phone's width with room to spare — lets a label wrap to a second line rather than force
the pill wider than the screen, the same trade `PageHeader` makes for a long title.

The icon itself needs no clamp: `Icon` sizes in logical pixels and doesn't scale with
text, so it holds its 22px size at any system text scale.

### Semantics via one `Semantics(excludeSemantics: true)` node per destination

Wrapping each destination in a single explicit `Semantics` node — carrying `selected`,
`button: true`, and the destination's label — and excluding the descendant tree (the
`InkWell`, `Icon`, and `Text` beneath it) keeps exactly one semantics node per
destination, reporting exactly the state a screen reader needs: which label, and
whether it's the one currently selected. Letting the descendant `InkWell` contribute its
own semantics alongside would either duplicate the label or merge in default button
semantics that don't carry the `selected` flag at all.

## Risks / Trade-offs

**Two bottom-navigation specs now exist side by side.** `app-navigation` (rendering
requirement retired by this change) and `bottom-navigation` (this change's new
capability) describe the same bar from two angles — what it must do, and what it must
look like doing it. Kept separate rather than merged, because the four parallel
tinted-surface changes will each retire an analogous rendering detail from their own
screen's existing spec without touching this one; a merged spec would need edits from
changes that have no reason to know this bar exists.

**A pill this compact leaves less room per destination than a full-width bar had.**
Accepted: the brief's own numbers (5px padding, 4px gap, ~248px total width at 1.0x) are
what a floating pill needs to read as one shape rather than a Material bar with its
corners rounded off. Two destinations, not three or four, is what keeps that width
workable at a large text scale — the same reasoning `replace-overflow-with-bottom-nav`
already used to cap the bar at two.

## Migration Plan

None. Presentation only; nothing persisted changes shape, and no route or destination
changes. A user's first launch after the update shows the floating pill instead of the
bar, with the same two destinations in the same order.
