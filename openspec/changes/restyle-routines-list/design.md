## Context

See `proposal.md` — Why. `app/lib/screens/routines_list/routines_list_screen.dart` is the
app's home screen: `DefaultTabController` + `Scaffold(appBar: AppBar(bottom: TabBar(...)))`,
a `TabBarView` of two `_RoutineSectionList`s, `NeumorphicCard` routine cards, and a stock
`FloatingActionButton`. `add-tinted-surfaces` (merged in `399bc94`) added the flat-surface
widget set this change consumes; `add-accent-color` added `context.routineCardColors`. This
is the first screen to actually import `app/lib/widgets/tinted/tinted.dart`.

## Goals / Non-Goals

**Goals:**

- Match the approved 390px mockup's look for this screen using only the existing tinted
  widget set — no new widget, no new `ColorScheme` role.
- Keep every control's action, destination, tooltip, and semantics exactly as they are today.
  Restyle in place; this is not a layout redesign.
- Keep the screen readable and overflow-free at 1.5x and 2.0x text scale, and correct in dark
  mode, without hardcoding a single color.

**Non-Goals:**

- Moving, removing, or regrouping any control. The mockup's layout is a look, not a new
  information architecture.
- Touching any other screen or any other part of `theme.dart` besides
  `floatingActionButtonTheme`.
- Building the floating bottom nav bar itself — a parallel change owns that. This change only
  reserves room for it.

## Decisions

### The status bar gets its own `AnnotatedRegion`, because the `AppBar` it replaced used to set it for free

Removing the `AppBar` removes the one place `SystemUiOverlayStyle` was implicitly set. The
screen now wraps its `Scaffold` body in `AnnotatedRegion<SystemUiOverlayStyle>`, choosing dark
status-bar icons in light theme and light icons in dark theme, with a transparent status bar
so the tinted background shows through behind it. This is a value derived from
`Theme.of(context).brightness`, not a hardcoded choice, so it still follows the user's theme.

### `PillSegmentedControl` gets its `TabController` from `DefaultTabController.of(context)`, not a new one

The screen already wraps itself in `DefaultTabController` so the existing `TabBarView` keeps
working; a `Builder` under it hands both `PillSegmentedControl` and `TabBarView` the same
controller instance via `DefaultTabController.of(context)`. Introducing a second, independent
`TabController` was rejected — it would desync tapping the pill from swiping the view, which
is exactly the behavior this brief asks to preserve.

### The list keeps its own horizontal padding instead of inheriting the screen's

`AppSpacing.element` (16) already equals the mockup's screen padding, so the routine list's
existing `EdgeInsets.fromLTRB(AppSpacing.element, ...)` needs no change — only its header and
pill row are wrapped in an explicit 16px horizontal `Padding`, matching the same number without
introducing a second literal for it.

### Vertical rhythm is spelled out as literals, not new spacing tokens

12px (label-to-cards, between cards) and 28px (between groups) don't match any existing
`AppSpacing` step, and the brief scopes this change to one screen's file plus
`floatingActionButtonTheme` — adding new shared tokens for numbers only this screen currently
uses would be scope creep ahead of a second screen actually needing them. They're written as
named local constants in the screen file with a comment pointing at the mockup, the same way
`_StartTime._width` already documents its own literal.

### The FAB's shape and elevation move to `floatingActionButtonTheme`; its color already lived there

The brief calls for `floatingActionButtonTheme` specifically, not a local
`FloatingActionButton` override, so a later screen that also uses a stock FAB inherits the
same flat, shadowless circle automatically. `backgroundColor`/`foregroundColor` were already
`scheme.primary`/`scheme.onPrimary` — only `elevation` (4 → 0, plus the pressed/focused/hovered
elevations, which default to `elevation` unless overridden and must be pinned to 0 too) and
`shape` (a squircle → `CircleBorder`) change.

### Bottom list padding adds live `MediaQuery` inset instead of a second fixed constant

`MediaQuery.paddingOf(context).bottom` already reflects both the device's safe-area inset and,
once the parallel floating-nav change lands and sets `Scaffold.extendBody`, that bar's height —
Flutter's `Scaffold` feeds an `extendBody` bottom navigation bar's height into the body's
`MediaQuery` bottom padding for exactly this reason. Reading it live means this screen doesn't
need to know the nav bar's height, or whether it exists yet, to clear it correctly.

## Risks / Trade-offs

**Two literal spacing numbers (12, 28) live only in this screen.** Accepted per the decision
above; if a second screen needs the same rhythm, promoting them to `AppSpacing` becomes that
change's job, not this one's.

**`AnnotatedRegion` duplicated per redesigned screen rather than centralized once.** The brief
scopes this change to one screen's file. A shared helper is exactly the kind of cross-screen
change the four parallel agents' file ownership is designed to avoid mid-flight; it can follow
once every screen has actually needed the same treatment.

## Migration Plan

None. No persisted data changes shape. `floatingActionButtonTheme`'s new values apply to every
screen using a stock FAB the moment this change lands, which today is only this one.
