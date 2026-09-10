## Context

See `proposal.md` — Why. `app/lib/theme/neumorphic.dart` is the existing shared-widget
precedent: `NeumorphicCard`, `NeumorphicCircleButton`, and `NeumorphicPillButton` own
their own press state and read color from the theme rather than leaving it to call
sites. The new widgets follow the same shape, but the surface treatment is flat: a
solid fill instead of a shadow pair, so there's no `ThemeExtension` to add — a caller
just hands in a `ColorScheme` role.

`app/lib/theme/motion.dart` already has every token this change needs (`AppMotion.feedback`,
`AppMotion.transition`, `AppMotion.pressScale`, and the reduced-motion resolver on
`BuildContext`). Nothing new is added there.

## Goals / Non-Goals

**Goals:**

- Give later screen-redesign changes a complete, tested set of flat-surface widgets to
  build against, so those changes are pure call-site swaps.
- Keep every widget palette-agnostic: colors come from `Theme.of(context).colorScheme`
  or from a constructor parameter, never a literal or a new `ThemeExtension`. A
  parallel change is still choosing the palette tokens themselves.
- Match the neumorphic widgets' existing conventions for press state, semantics, and
  tooltips, so the two idioms read as siblings during the transition period rather
  than as two unrelated systems.

**Non-Goals:**

- Touching any screen. No screen imports these widgets in this change.
- Removing or deprecating the neumorphic widgets. They stay in use on every screen
  this change doesn't touch — which is all of them.
- New `ColorScheme` roles or palette changes. A parallel change owns `palette.dart`,
  `colors.dart`, and `theme.dart`.

## Decisions

### Flat fill instead of a `ThemeExtension`

The neumorphic idiom needed a `ThemeExtension` because its two shadow colors don't
exist anywhere else in the `ColorScheme`. A flat tint has no such gap — `TintedCard`
takes its fill and foreground straight from constructor parameters (which callers will
usually fill with a `colorScheme` role), and `SoftCircleButton` reads `surfaceContainer`
/ `primaryContainer` directly off `Theme.of(context).colorScheme`. Adding a parallel
extension for a single solid color would be a wrapper with no behavior in it.

### `PageHeader` and `SectionLabel` render no bar or background

Both are explicitly "no stock Material chrome": `PageHeader` is a plain `Row`, not an
`AppBar`, so it carries no elevation, no shadow, and no fixed height beyond the 48px
the spec asks for. This is why a redesigned screen places its own background behind
these widgets rather than the widget supplying one.

### `PillSegmentedControl` drives its pill from `controller.animation`, not `index`

Wiring the pill's position to `controller.index` would only update on tap completion.
Driving it from `controller.animation` (an `Animation<double>` that already tracks a
swipe on a paired `TabBarView`) means the pill's motion cannot be tokenized through
`AppMotion` — it isn't animating with its own duration, it's *following* a gesture, and
the follow itself doesn't move on a timer. The token discipline still applies to the
press deform and to `animateTo`'s own transition, which is the controller's built-in
one.

*Alternative considered:* an internal `AnimationController` driven by `didUpdateWidget`
whenever `controller.index` changes. Rejected: it wouldn't move during a swipe gesture,
only snap after one completes, which fails the requirement that swiping a paired
`TabBarView` moves the pill.

### Press deform is 0.98, not the neumorphic widgets' 0.97

The brief specifies "at most 5%," and 0.98 is what's asked for these widgets
specifically — a flatter surface reads as glitching at a bigger deform than a shadowed
one, so a slightly smaller depress suits it. `AppMotion.pressScale` (0.97) stays the
neumorphic widgets' value; this change does not touch it.

## Risks / Trade-offs

**Two surface idioms coexist during the transition.** Intended — see Non-Goals. The
risk is a screen accidentally mixing both; that's out of this change's control since no
screen is touched here, but it's the reason `DESIGN.md`'s new section says explicitly
that neumorphic widgets stay valid until a screen's own redesign change lands.

**`PillSegmentedControl` couples to `TabController`/`TabBarView` rather than being a
freestanding segmented control.** Chosen because the brief asks for swipe-follow
behavior, which only `TabController.animation` provides for free. A control that
doesn't need swipe (a settings toggle, say) can still use `SegmentedProgress` or a
plain row of `TintedCard`s instead.

## Migration Plan

None. Nothing consumes these widgets yet, so there's nothing to migrate. Each
follow-up change that moves a screen to tinted surfaces plans its own migration.
