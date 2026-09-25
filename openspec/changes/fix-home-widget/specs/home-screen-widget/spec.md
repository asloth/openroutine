# Home screen widget

## MODIFIED Requirements

### Requirement: A row tap opens that routine's timer

Tapping a routine row SHALL open `/routines/:routineId/timer` on top of the routine list.

#### Scenario: Closing a run started from the widget
- **WHEN** a run started from the widget is closed or backed out of
- **THEN** the routine list shows
- **AND** nothing throws

### Requirement: The widget uses your colors

The widget SHALL draw with the palette chosen in Settings and SHALL follow the theme mode setting. When the mode is system, it SHALL follow the system's dark mode on Android 12 and later, even while the app is closed.

#### Scenario: Changing the accent
- **WHEN** you choose a different accent in Settings
- **THEN** the widget is republished with that palette's light and dark colors
