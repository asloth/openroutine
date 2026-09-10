## Why

The routines list is the app's home screen, and it's still stock Material: an `AppBar`, a
`TabBar`, and neumorphic cards. `add-tinted-surfaces` landed the flat-surface widgets the
"tinted paper" redesign needs, and `add-accent-color` gave routine cards their own color
source. This change spends both on the one screen everyone opens first.

Nothing about where a control sits or what it does is changing — the settings gear still
opens Settings, the tabs still swipe, the Low Mode pill still starts Low Mode, the FAB still
creates a routine. Only the surfaces change.

## What changes

- Replace the `AppBar` with a `PageHeader`: the title and a neutral `SoftCircleButton` for
  Settings, on a screen the app now paints status-bar contrast for itself.
- Replace the `TabBar` with a `PillSegmentedControl`, still driven by the existing
  `TabController` so a swipe on the `TabBarView` still moves it.
- Replace moment-group headings with `SectionLabel` and retune the vertical rhythm around it
  (12px label-to-cards, 28px between groups, 12px between cards).
- Replace each routine's `NeumorphicCard` with a `TintedCard` filled with the accent
  (`context.routineCardColors.fill`/`onFill`), and turn "Start Low Mode" into a filled pill.
- Restyle the FAB through `floatingActionButtonTheme` alone: no elevation, no shadow, a
  perfect circle.
- Add enough bottom list clearance for both the FAB and the floating nav bar a parallel
  change is adding.

## Capabilities

### New Capabilities

- `routines-list` — the home screen's presentation: `PageHeader`, `PillSegmentedControl`,
  `SectionLabel`, and `TintedCard` surfaces, with every control keeping its existing action,
  navigation target, and copy.

## Impact

**Code.** `app/lib/screens/routines_list/routines_list_screen.dart` (restyled in place),
`app/lib/theme/theme.dart` (`floatingActionButtonTheme` only — no other agent touches this
file). `app/test/screens/routines_list/routines_list_screen_test.dart` gets new coverage for
the header, the segmented control, the tinted cards, and text-scale tolerance.

**Screens.** Only this one. Four sibling changes restyle other screens in parallel; none of
them touch this file.

**Storage and schema.** None. This is presentation only.

**i18n.** None expected — every string this screen shows already exists (`appTitle`,
`settingsTitle`, `routinesTabScheduled`/`Flexible`, `routinesStepCount`,
`routinesLowModeSetupGuidance`, `routinesStartLowMode`, `routinesNewRoutine`,
`routinesEmptyScheduled`/`Flexible`, `routinesLoadError`, `routinesNoTrigger`).

**Rollback.** Reverting this change restores the `AppBar`/`TabBar`/`NeumorphicCard` version
and the previous `floatingActionButtonTheme`. Nothing persisted changes shape, so there's
nothing to migrate either direction.
