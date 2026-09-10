## Why

The app is moving to an approved visual direction called "tinted paper": flat, tinted
surfaces instead of the neumorphic shadow pair, and no stock Material chrome (an AppBar
strip, `TabBar`, `NavigationBar`, or a FAB's drop shadow). Nothing about where controls
sit is changing — only how surfaces render.

Screens will move to the new look in later, separate changes. This change adds the
shared building blocks those changes will use: tokens and widgets, with no screen
wired up to them yet. Landing the foundation on its own keeps each reviewable slice
small, the same pattern the storage layer used ahead of its UI (commit `5ef5b2a`).

## What Changes

- Add two corner radii to `AppRadius`: `tinted` (20) and `hero` (24), each with a
  matching `BorderRadius` constant.
- Add two static text styles to `AppTypography`: `pageTitle` and `sectionLabel`. These
  are additions, not new `TextTheme` roles, so no existing screen is affected.
- Add six widgets under `app/lib/widgets/tinted/`, exported from one barrel file:
  `TintedCard`, `SoftCircleButton`, `PageHeader`, `SectionLabel`, `SegmentedProgress`,
  and `PillSegmentedControl`.
- Document the new widgets in `DESIGN.md` under Components, alongside the neumorphic
  idiom they will eventually replace on redesigned screens.

## Capabilities

### New Capabilities

- `tinted-surfaces` — the flat-surface widget set and its tokens: what each widget
  requires, how it reads color, how it handles press feedback and reduced motion, and
  the accessibility floor (hit target, text-scale tolerance) every one of them meets.

## Impact

**Code.** `app/lib/theme/spacing.dart` (two radii), `app/lib/theme/typography.dart`
(two styles), six new files under `app/lib/widgets/tinted/` plus a barrel,
`DESIGN.md`. One widget test file per new widget under `app/test/widgets/tinted/`.

**Screens.** None. No screen imports or renders these widgets yet — that's later,
separate change work.

**Storage and schema.** None.

**i18n.** None expected. Every string in these widgets is caller-supplied (labels,
tooltips, titles); the widgets carry no user-facing copy of their own.

**Rollback.** Deleting the new files and reverting the two token additions and the
`DESIGN.md` section fully undoes this change — nothing else in the app references
them yet.
