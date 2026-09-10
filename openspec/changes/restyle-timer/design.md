## Context

See `proposal.md` — Why. `add-tinted-surfaces` landed `SoftCircleButton` and `SegmentedProgress`
under `app/lib/widgets/tinted/`, and `add-accent-color` landed `context.routineCardColors`
(`RoutineCardColors`, a `ThemeExtension`) with a `timerGround` token. Both are consumed here for
the first time — no other screen has adopted the tinted-paper widgets yet, so there's no sibling
convention to match beyond what those two changes' own specs already promise.

## Goals / Non-Goals

**Goals:**

- Move the running screen's ground, its progress indicator, and its three circular controls to
  the tinted-paper widgets, with no change to what any control does or where it sits.
- Keep the ring's accent color and the estimate-zone yellow exactly as they behave today —
  `TimerClock` isn't touched.
- Keep every existing test's behavioral intent intact; only the finder for the two circular
  controls changes type.

**Non-Goals:**

- Restyling `_Summary` (the completion screen) beyond what it already inherits from the theme.
  It keeps its current layout and only the accent-driven `FilledButton` colors change, which it
  gets for free from the theme — no code in this screen needs to change for that.
- Touching `TimerClock`, `timer_machine.dart`, or `timer_provider.dart`.
- Adding an `AppBar`. The screen has never had one; there's nothing to wrap in
  `AnnotatedRegion<SystemUiOverlayStyle>`.

## Decisions

### The ring stays on `colorScheme.primary`, which is the accent — and that's correct

`CircularProgressIndicator` in `TimerClock` already reads the theme's `primary` (falling back to
`tertiary` only in the estimate's yellow zone). Since `add-accent-color` landed, `primary` *is* the
user's chosen accent, purple by default. That's intentional, not a regression to fix: `secondary`
(the palette's own green) is reserved for "a routine is coming up soon" on the home screen, a fixed
status color independent of both the palette and the accent. If the ring used green too, "running"
and "coming up" would share a color and the distinction the design system draws between them would
disappear. So this change makes no change to `TimerClock` at all — the ring already does the right
thing by inheriting the theme.

### `SegmentedProgress` gets `onSurface`, not the accent

The brief specifies `color: onSurface` for the step-progress segments, not the accent's `primary`.
That keeps the accent reserved for actions (Done, the ring, the pause/restart fills) rather than
spreading it across a second surface, and it matches how `SegmentedProgress`'s own spec describes
the widget as palette-agnostic — the caller picks the role.

### Close moves from a bare `IconButton` to a neutral `SoftCircleButton`

The brief calls for "a neutral 48px `SoftCircleButton` with an X icon" at the same position, with
the same tooltip and abandon-confirm flow. `SoftCircleButton`'s default style is already
`neutral`, and its default size is already 48, so the call site only needs `icon`, `tooltip`, and
`onPressed` — no style or size override.

### Pause/Resume and Restart move from `NeumorphicCircleButton` to accent `SoftCircleButton`s

`_CircleAction` becomes a thin wrapper around `SoftCircleButton(size: 64, style:
SoftCircleButtonStyle.accent)`, keeping its own `icon`/`label`/`onPressed` API so the call sites in
`_Running` don't change. The existing code comment explaining why these controls are neutral
rather than `secondaryContainer`-tinted (so they don't shout louder than Done) is replaced: under
tinted paper they're deliberately accent-colored circular controls, matching the mockup, and Done
stays the one full-width, unambiguously primary action beneath them.

### Do later's label becomes explicit `onSurface`

`TextButton.icon`'s default color already resolves to `colorScheme.primary` through
`textButtonTheme` — which, post-accent, is the same purple Done uses. Left alone, "Do later" would
visually compete with Done for primary-action attention, which the brief calls out by name. Setting
its `style: TextButton.styleFrom(foregroundColor: colorScheme.onSurface)` keeps it visually
secondary without changing its position, icon, or the existing show/hide rule.

## Risks / Trade-offs

**None material.** This is a call-site-only change to one screen; the widgets it adopts are
already tested in isolation by `add-tinted-surfaces`, and the color source it reads
(`routineCardColors.timerGround`) is already tested in isolation by `add-accent-color`.

## Migration Plan

None. No persisted state, schema, or provider shape changes.
