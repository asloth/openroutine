## Why

Statistics is buried. It lives behind the three-dot overflow menu in the top-right corner, alongside Import and Settings — three unrelated things in one anonymous menu, none of them visible until you open it. A screen worth building is a screen worth finding, and right now Stats is two taps deep behind an icon that gives no hint it's there.

The overflow menu also mixes two different kinds of thing. Statistics is a *place* you go and look around. Import is an *action* you perform once and finish. Settings is a place too, but a rarely-visited one. Putting all three behind the same dots treats them as interchangeable.

## What Changes

- Add a bottom navigation bar with two destinations: **Routines** and **Stats**. Both are places, both are visible without opening anything.
- Move **Settings** to a gear icon in the top-right, where the overflow menu used to be. It stays one tap away without spending a permanent slot in the bottom bar.
- Move **Import** into Settings, in the existing Data section directly above `Export all`. Import and export are the same idea pointed in opposite directions, and neither is somewhere you navigate to — they're things you do.
- Delete the overflow menu.
- Each destination keeps its own navigation stack and scroll position, so switching to Stats and back leaves the routine list exactly where it was, including which of the Scheduled/Flexible tabs was open.

## Capabilities

### New Capabilities

- `app-navigation` — how a user reaches the app's top-level destinations, which things qualify as destinations rather than actions, and what happens to a destination's state when it is left and returned to.

## Impact

**Code.** `app/lib/main.dart` (the router grows a `StatefulShellRoute`), `app/lib/screens/routines_list/routines_list_screen.dart` (overflow menu out, gear in), `app/lib/screens/stats/stats_screen.dart` (becomes a destination root rather than a pushed page), `app/lib/screens/settings/settings_screen.dart` (an Import row in the Data section), and a new shell widget hosting the bar. Widget tests for the bar, for state preservation, and for both relocated entry points.

**Routes.** `/routines` and `/stats` become shell branches. `/settings` and `/import` stay ordinary pushed routes, so every existing deep link keeps working — including the notification tap into `/routines/<id>` and the home screen widget's `/routines/<id>/timer`.

**Storage and schema.** None. Navigation holds no persisted state and nothing under `schemas/` changes.

**Existing users.** The three-dot menu disappears. Anyone who learned it will find Stats promoted to the bottom bar and Settings behind the gear in the same corner the menu used to occupy. Import is the one thing that genuinely moves, from the overflow to Settings.

**i18n.** Three new keys in `app_en.arb` and `app_es.arb` together: the two bottom bar labels and the settings icon's tooltip. The Import row reuses the existing `routinesMenuImport`.

**Accessibility.** Bottom bar labels have to survive a large text scale — the same failure mode that sliced the step template names. Two destinations rather than three or four is what makes that comfortable.

**Rollback.** Reverting restores the overflow menu and returns `/stats` to a pushed route. Nothing is persisted differently, so there is nothing to unwind.
