# Tasks: Replace the overflow menu with a bottom navigation bar

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 260–340 |
| 400-line budget risk | Low |
| 400-line budget at risk | No |
| Chained PRs recommended | No |
| Suggested split | — |
| Delivery strategy | single |
| Chain strategy | — |

Decision needed before apply: No
Chained PRs recommended: No
400-line budget risk: Low

## 1. Strings

- [x] 1.1 Add `navRoutines`, `navStats` and `settingsTitle` to `app/lib/l10n/app_en.arb` and `app_es.arb` together, and run `flutter gen-l10n` — `settingsTitle` replaces `routinesMenuSettings`, which the settings screen was already using for its own title, so one key now names the screen and its tooltip

## 2. The shell and its bar

- [x] 2.1 RED — Add `app/test/screens/app_shell_test.dart` asserting the routine list shows a `NavigationBar` naming Routines and Statistics, and verify it fails because no bar exists
- [x] 2.2 GREEN — Add `app/lib/screens/shell/app_shell.dart`: a `Scaffold` whose `bottomNavigationBar` is a `NavigationBar` driven by a `StatefulNavigationShell`, and wrap `/routines` and `/stats` in a `StatefulShellRoute.indexedStack` in `main.dart`. Verify 2.1 passes
- [x] 2.3 RED — Assert selecting Statistics shows the stats screen, and verify it fails or passes for the right reason
- [x] 2.4 GREEN — Wire the bar's `onDestinationSelected` to `StatefulNavigationShell.goBranch`, and verify 2.3 passes
- [x] 2.5 RED — Assert that leaving the routine list on its Flexible tab, visiting Statistics and returning leaves Flexible selected, and verify it fails against a rebuilt branch
- [x] 2.6 GREEN — `indexedStack` preserved it on its own; no state hoisting was needed. Verify 2.5 passes
- [x] 2.7 Assert the bar's labels stay legible at a 1.5x text scale, reusing the approach in `step_template_card_test.dart` — note Material clamps navigation bar labels to 1.3x, so the test asserts the label is drawn in full at the scale it receives, not that it reaches 1.5x

## 3. Settings moves to the app bar

- [x] 3.1 RED — Assert the routine list has a settings control that opens `/settings`, and verify it fails while only the overflow menu exists
- [x] 3.2 GREEN — Replace `PopupMenuButton` with an `IconButton` carrying `Icons.settings_outlined` and the `settingsTitle` label, and verify 3.1 passes
- [x] 3.3 RED — Assert no `PopupMenuButton` remains on the routine list, and verify it passes once the menu is gone
- [x] 3.4 Delete the now-unused `_OverflowAction` enum and its `routinesMenuSettings` ARB key if nothing else references them

## 4. Import moves into Settings

- [x] 4.1 RED — Add a settings screen test asserting the Data section offers an import control that opens `/import`, and verify it fails
- [x] 4.2 GREEN — Add the import row directly above `Export all` in the Data section, reusing the existing `routinesMenuImport` string, and verify 4.1 passes

## 5. Stats becomes a destination root

- [x] 5.1 RED — Assert the stats screen shows no back button when reached from the bar, and verify it fails because `AppBar` adds one automatically
- [x] 5.2 GREEN — Set `automaticallyImplyLeading: false` on the stats `AppBar`, and verify 5.1 passes
- [x] 5.3 Confirm `ImportScreen` keeps its back button, since it is still pushed

## 6. Existing entry points

- [x] 6.1 Assert a widget launch URI still reaches `/routines/<id>/timer` through the shell — extend `app_router_test.dart` rather than duplicating it
- [x] 6.2 Assert the notification `onOpenRoutine` callback still reaches `/routines/<id>`
- [x] 6.3 Confirm `overridePlatformDefaultLocation` still holds with a shell route present, by re-running the widget-tap case in `app_router_test.dart`

## 7. Verification

- [x] 7.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 7.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or above the current 345 baseline — 354 passing
- [x] 7.3 Run `openspec validate replace-overflow-with-bottom-nav --type change --strict` and verify it passes
- [ ] 7.4 Confirm on the Pixel 9a that the bar renders at the device's own text scale, that Stats opens from it, and that Settings opens from the gear. **Built and installed 2026-09-09; the phone was locked, so nothing has been seen yet.**
