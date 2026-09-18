## Why

The redesign reached routine detail, timer, and home, and each of those draws its own back
control as a 48px `SoftCircleButton` with `Icons.chevron_left`. Four screens haven't caught up —
routine form, step form, settings, and import — and still sit on a stock Material `AppBar`, whose
automatic leading paints the plain `←` arrow. Side by side, the app looks like it's running two
designs at once.

Routine detail also carries a `PopupMenuButton` with a single item: Delete. A menu that always
opens to exactly one choice isn't saving the person a tap, it's costing them one, and the drawn
circle around it duplicates work `SoftCircleButton` already does.

## What Changes

- Add `SoftBackButton`, a `SoftCircleButton` wrapping `Icons.chevron_left` with the platform's own
  back tooltip, and a static helper for placing it as an `AppBar`'s `leading` 16px from the left
  edge and vertically centered.
- Set it as `leading` on every `AppBar` in routine form, step form, settings, and import,
  including each screen's loading, error, and unavailable-state bars.
- Replace routine detail's `PopupMenuButton` with a `SoftCircleButton` showing
  `Icons.delete_outline` directly, running the same confirm-then-delete flow the menu item did.

## Capabilities

### New Capabilities

- `top-bar-navigation` — every screen's back control and routine detail's delete control render as
  `SoftCircleButton`s, not stock Material widgets.

## Impact

**Code.** `app/lib/widgets/tinted/soft_back_button.dart` (new), `app/lib/widgets/tinted/tinted.dart`
(barrel export), `app/lib/screens/routine_form/routine_form_screen.dart`,
`app/lib/screens/step_form/step_form_screen.dart`, `app/lib/screens/settings/settings_screen.dart`,
`app/lib/screens/import/import_screen.dart`, `app/lib/screens/routine_detail/routine_detail_screen.dart`.
Widget tests for the new button and for each touched screen's app bar.

**Storage and schema.** None.

**i18n.** None. The back tooltip comes from `MaterialLocalizations`; `commonDelete` already exists
in both ARB files.

**Existing users.** Presentation only. No behavior changes beyond the delete control needing one
tap instead of two.

**Rollback.** Reverting restores the stock `AppBar` leading and the `PopupMenuButton`. Nothing
persisted changes shape.
