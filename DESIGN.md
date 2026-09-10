---
version: alpha
name: OpenRoutine
description: Local-first routine app for iOS and Android, built on a warm, low-arousal "warm paper" palette and a neumorphic surface idiom.
colors:
  primary: "#A9502F"
  onPrimary: "#FFFFFF"
  primaryContainer: "#F6DCCF"
  onPrimaryContainer: "#4E1F0E"
  secondary: "#44694F"
  onSecondary: "#FFFFFF"
  secondaryContainer: "#D3E8D6"
  onSecondaryContainer: "#1B3623"
  tertiary: "#8A5A18"
  onTertiary: "#FFFFFF"
  tertiaryContainer: "#F7E4BF"
  onTertiaryContainer: "#432B06"
  error: "#B3261E"
  onError: "#FFFFFF"
  errorContainer: "#F9DEDC"
  onErrorContainer: "#5F1412"
  surface: "#F6F1E9"
  onSurface: "#2E2822"
  onSurfaceVariant: "#574E44"
  surfaceContainerLowest: "#FFFCF6"
  surfaceContainerLow: "#F2EBE1"
  surfaceContainer: "#EDE5D9"
  surfaceContainerHigh: "#E7DED0"
  surfaceContainerHighest: "#E1D6C6"
  surfaceDim: "#DCCFBD"
  surfaceBright: "#FFFCF6"
  outline: "#7C7063"
  outlineVariant: "#D5C9B9"
  inverseSurface: "#3A332C"
  inverseOnSurface: "#F4EEE6"
  inversePrimary: "#FFB59A"
  neumorphicShadow: "#DFD3C3"
  neumorphicHighlight: "#FFFDF8"
  mascotBody: "#D08F66"
  mascotInk: "#3A2A1E"
  mascotBlush: "#B4553A"
typography:
  displayLarge:
    fontFamily: Lexend
    fontSize: 40px
    lineHeight: 1.2
    fontWeight: 600
    letterSpacing: -0.8px
  headlineLarge:
    fontFamily: Lexend
    fontSize: 32px
    lineHeight: 1.3
    fontWeight: 500
  headlineSmall:
    fontFamily: Lexend
    fontSize: 24px
    lineHeight: 1.3
    fontWeight: 600
  titleLarge:
    fontFamily: Lexend
    fontSize: 20px
    lineHeight: 1.3
    fontWeight: 600
  titleMedium:
    fontFamily: Lexend
    fontSize: 16px
    lineHeight: 1.4
    fontWeight: 600
  labelCaps:
    fontFamily: Lexend
    fontSize: 14px
    lineHeight: 1
    fontWeight: 600
    letterSpacing: 0.7px
  labelSmall:
    fontFamily: Lexend
    fontSize: 12px
    lineHeight: 1
    fontWeight: 600
    letterSpacing: 0.6px
  action:
    fontFamily: Lexend
    fontSize: 18px
    lineHeight: 1
    fontWeight: 500
  bodyLarge:
    fontFamily: Inter
    fontSize: 20px
    lineHeight: 1.6
    fontWeight: 400
  bodyMedium:
    fontFamily: Inter
    fontSize: 16px
    lineHeight: 1.6
    fontWeight: 400
  bodySmall:
    fontFamily: Inter
    fontSize: 14px
    lineHeight: 1.5
    fontWeight: 400
rounded:
  small: 4px
  medium: 8px
  card: 12px
  pill: 9999px
spacing:
  base: 8px
  element: 16px
  container: 24px
  section: 32px
  touchTargetMin: 48px
---

## Overview

OpenRoutine helps someone get through a routine they already find hard to start. To lower that activation energy, the interface is warm and low-arousal rather than efficient-looking: an oat-paper ground, terracotta actions, moss progress, and honey accents. Nothing in the app scolds — `error` is reserved for mechanical failures like a failed import, never for a missed routine or an overrun step.

## Colors

`primary` carries every primary action. `secondary` is the timer ring's "in progress" green — it means running, not succeeded, so the ring keeps that color while a step is still going. `tertiary` carries accents, plus the "taking a little longer" end of the estimate zones.

Every foreground and background pair meets WCAG AA: 4.5:1 for body text, and 3:1 for large text and UI edges. A new pairing must clear the same bar before it ships.

The mascot's three colors are fixed across both themes. It's a creature, not a surface — recoloring it per theme reads as two different pets — and the container roles are the wrong tool anyway, since `primaryContainer` vanishes on the light ground and sinks into the dark one. `mascotInk` is contrast-checked against `mascotBody` (5.4:1), not against whatever the app is painted on behind it.

The app ships several palettes and lets the user choose one in Settings › Appearance, because "cozy" isn't a universal fact — the same terracotta reads as warm to some people and as brown to others. Changing a palette changes the ground as well as the accent; an accent-only swap leaves the app still looking like the color the user rejected.

The tokens above are `warm_paper`, the one literal hand-tuned palette. It's the reference this document describes, but it's not what a fresh install is themed with — the shipped default is `sea_glass`. Those are deliberately different things: warm paper is the scheme every other palette is generated *from*, so it stays the normative description of the system's structure even when it's not the one on screen. Read the tokens above as the shape of a palette, not as the colours the app opens in. Every other shipped palette is generated from it at a different base hue, reusing its HSL structure: the same lightness ladder, the same saturation falloff across the surface roles, and the same hue offsets between primary, secondary, and the neutrals. Generate a new palette that way rather than hand-picking one, or it ends up looking like a hue-rotated screenshot instead of a coherent scheme. Palette identifiers are persisted to preferences, so they're stable keys and never get localized.

## Themes

The frontmatter carries the light theme. Dark isn't `ColorScheme.fromSeed` of the light one — seeding lands on a blue-black ground and throws away the point of the palette. Evening routines are the most likely to run in dark mode, so the dark theme is hand-built on a warm ink ground with lifted terracotta and moss that clear AA against it.

| Token | Light | Dark |
| --- | --- | --- |
| primary | `#A9502F` | `#F0A484` |
| onPrimary | `#FFFFFF` | `#4A1C08` |
| primaryContainer | `#F6DCCF` | `#6B3016` |
| onPrimaryContainer | `#4E1F0E` | `#FFDBCC` |
| secondary | `#44694F` | `#9CC5A2` |
| onSecondary | `#FFFFFF` | `#12301B` |
| secondaryContainer | `#D3E8D6` | `#2C4A34` |
| onSecondaryContainer | `#1B3623` | `#D3E8D6` |
| tertiary | `#8A5A18` | `#E7BE7C` |
| onTertiary | `#FFFFFF` | `#412A05` |
| tertiaryContainer | `#F7E4BF` | `#5D3F0D` |
| onTertiaryContainer | `#432B06` | `#F7E4BF` |
| error | `#B3261E` | `#F2B8B5` |
| onError | `#FFFFFF` | `#601410` |
| errorContainer | `#F9DEDC` | `#8C1D18` |
| onErrorContainer | `#5F1412` | `#F9DEDC` |
| surface | `#F6F1E9` | `#1C1815` |
| onSurface | `#2E2822` | `#EDE4D9` |
| onSurfaceVariant | `#574E44` | `#CFC2B4` |
| surfaceContainerLowest | `#FFFCF6` | `#14100E` |
| surfaceContainerLow | `#F2EBE1` | `#241F1B` |
| surfaceContainer | `#EDE5D9` | `#29231F` |
| surfaceContainerHigh | `#E7DED0` | `#342D28` |
| surfaceContainerHighest | `#E1D6C6` | `#3F3833` |
| surfaceDim | `#DCCFBD` | `#1C1815` |
| surfaceBright | `#FFFCF6` | `#423A34` |
| outline | `#7C7063` | `#998C7E` |
| outlineVariant | `#D5C9B9` | `#4D453D` |
| inverseSurface | `#3A332C` | `#EDE4D9` |
| inverseOnSurface | `#F4EEE6` | `#332C26` |
| inversePrimary | `#FFB59A` | `#A9502F` |
| neumorphicShadow | `#DFD3C3` | `#100D0B` |
| neumorphicHighlight | `#FFFDF8` | `#2E2823` |

The mascot tokens are identical in both themes.

## Typography

Two typefaces split the work. Lexend carries anything structural or actionable — headings, hero numbers, button labels. Inter carries prose. Both are bundled rather than fetched at runtime, so type works offline like the rest of the app.

The scales map onto Material 3's text roles, so stock widgets inherit them without per-screen overrides. For roles the design pass never named, interpolate from the ones it did rather than leaving them at Material's defaults — a single unstyled widget breaks the typographic voice.

Anything that ticks — the countdown, running totals — needs tabular figures. Proportional digits change width as their value changes, so the number jitters horizontally on every tick.

## Layout

`spacing.base` is the unit — every other step is a multiple of it. Reach for a named step rather than an inline value, so a reviewer can tell a deliberate gap from a typo-sized one. `element` separates siblings within a group, `container` marks the screen edge, and `section` separates groups that aren't related to each other.

`touchTargetMin` is a floor, not a step in the scale.

## Elevation and depth

Depth here is neumorphic, not Material elevation. Every raised surface casts two shadows: a warm sand shadow offset down and to the right, and a near-white cream highlight offset up and to the left, both at equal blur. Both are tinted rather than neutral — a grey shadow on a warm ground is what makes neumorphism read as moulded plastic.

The pair only reads as depth against a ground whose value sits between the two, and that's what `surface` is for. Apply the treatment over a container role instead, and it flattens.

Larger elements scale the offset and blur together rather than adopting new values — that keeps the light-source relationship consistent at a bigger radius. The pressed state inverts the two shadows inward; it's a state of the same surface, not a separate component.

## Motion

Motion values aren't tokens in this document. The `DESIGN.md` schema has no motion category, and values placed in one get dropped from every export, so `app/lib/theme/motion.dart` is the normative source, and this section records how to apply it.

Reach for a named duration and curve rather than writing either at the call site. The point isn't that any one number is correct — it's that two controls doing the same kind of thing move the same way, and that's impossible to hold by hand across screens.

Motion that answers a direct user action resolves within 300ms. Past that point, the user has already finished the thought the animation is still illustrating. Motion that reports ongoing progress rather than answering a tap is exempt, because nobody's waiting on it.

Easing carries direction. Something arriving decelerates into place; something leaving accelerates away. Using the wrong half of that pair is the most common way motion ends up feeling backwards, and it's not subtle once you've seen it. Something that's present both before and after does both, easing out of where it was and into where it's going.

Linear easing is reserved for indicators that map onto elapsed time or completion. Nothing physical starts and stops at a constant speed, so linear motion applied to an object reads as mechanical.

An interactive control deforms while held, by no more than five percent in either direction. A control that doesn't deform at all reads as dead, and that's the more common failure — more common than deforming too much. Where motion should overshoot and settle, use the spring curve rather than an elastic one: an elastic curve can't be interrupted and re-targeted without snapping, and interruption is exactly what a gesture does.

When several elements enter as a group, keep the delay between them under 50ms. Past that, the group stops arriving together and starts loading one item at a time.

Navigation uses one shared transition for every route, not a choice per destination — the arriving screen fades in and rises a short distance, while the departing one fades out. A full-width slide was rejected deliberately: it's a large directional gesture that asserts hierarchy between screens, and that's the wrong register here. A pure cross-fade was too weak, because every screen shares the same warm ground, and a fade alone can read as a repaint rather than a navigation. Route pages must carry a distinct key — two pages of the same type sharing a key get treated as one route being updated, and nothing animates at all.

Every animated duration passes through the reduced-motion resolver rather than reaching a widget directly. Flutter doesn't apply the platform's reduced-motion setting to a duration handed to an implicit animation or to a hand-driven controller, so a widget that skips the resolver keeps animating for someone who asked the system to stop. Suppressed motion resolves straight to the end state rather than not running at all, so nothing is left holding its previous state.

## Shapes

`rounded.card` is the default. `rounded.pill` is for anything that reads as an action.

## Components

`NeumorphicTheme` is a theme extension that exposes the raised and pressed surface treatments, so the depth idiom is configured once and consumed rather than rebuilt. `NeumorphicCard`, `NeumorphicCircleButton`, and `NeumorphicPillButton` are the shared owners of that treatment. A new surface that needs depth extends this set rather than composing shadows locally — that's what keeps the light source consistent across screens.

Interactive neumorphic controls own their pressed state, so a caller supplies the action, not the visual feedback.

### Tinted surfaces

"Tinted paper" is the approved direction that replaces neumorphism, one redesigned screen at a time: a flat, tinted fill instead of the shadow pair, and no stock Material chrome — no `AppBar` strip, `TabBar`, `NavigationBar`, or FAB shadow. Depth comes from color contrast against the surface behind a control, not from a shadow.

`TintedCard` is the flat-surface equivalent of `NeumorphicCard`: a solid fill with a required foreground color, no shadow, an ink response and a small press deform when it's tappable. `SoftCircleButton` replaces `NeumorphicCircleButton` the same way, in a neutral or accent fill. `PageHeader`, `SectionLabel`, `SegmentedProgress`, and `PillSegmentedControl` cover the layout and progress roles a stock `AppBar`, section heading, `LinearProgressIndicator`, and `TabBar` would otherwise fill — each with no bar, no elevation, and no shadow of its own. All six live under `app/lib/widgets/tinted/`.

Every tinted-surface widget takes its colors from `Theme.of(context).colorScheme` or from a caller-supplied color, never a literal — the same discipline as the neumorphic set, applied to a flat fill instead of a shadow pair.

The two idioms coexist for as long as the redesign is in progress. A screen the redesign hasn't reached yet keeps its neumorphic widgets; nothing here retires `NeumorphicTheme` or its widgets while a single screen still depends on them.

## Do's and don'ts

- Don't hand-pick a color in a screen. If a screen needs a color that isn't a token, the design system is missing a role.
- Don't ship an interactive target below `touchTargetMin`. That's a bug, not a style choice.
- Don't derive the dark scheme by seeding from the light one.
- Don't recolor the mascot per theme.
- Don't localize a palette identifier; it's a persisted key.
- Don't render ticking numbers without tabular figures.
- Don't write a duration or a curve at a call site; reach for a motion token.
- Don't hand a duration to a widget without passing it through the reduced-motion resolver.
- Don't animate an object linearly; linear is for progress indicators only.
