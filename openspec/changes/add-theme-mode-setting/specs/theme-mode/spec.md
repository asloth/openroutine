## Purpose

Defines the theme mode setting: whether the app follows the phone's own light/dark brightness or
is pinned to Light or Dark regardless of it.

## ADDED Requirements

### Requirement: A theme mode setting overrides the phone's brightness

The app SHALL let the user choose System, Light, or Dark from Settings › Appearance. Choosing Light
or Dark SHALL theme the app with that brightness regardless of the phone's own setting. Choosing
System SHALL follow the phone's brightness, as the app already does.

#### Scenario: Light is chosen on a phone set to dark

- **GIVEN** the phone's system setting is dark
- **WHEN** the user chooses Light in Settings › Appearance › Theme
- **THEN** the app renders with its light theme

#### Scenario: Dark is chosen on a phone set to light

- **GIVEN** the phone's system setting is light
- **WHEN** the user chooses Dark in Settings › Appearance › Theme
- **THEN** the app renders with its dark theme

#### Scenario: System is chosen

- **WHEN** the user chooses System in Settings › Appearance › Theme
- **THEN** the app renders with whichever theme matches the phone's current brightness, and keeps
  matching it if the phone's brightness changes later

### Requirement: The theme mode defaults to System

When no theme mode has been stored, the app SHALL follow the phone's own brightness, exactly as it
did before this setting existed. An unrecognized stored value SHALL also resolve to System.

#### Scenario: No theme mode has been chosen

- **WHEN** the app starts with no stored theme mode
- **THEN** it themes itself according to the phone's current brightness

#### Scenario: A stored theme mode is not recognized

- **GIVEN** a stored theme mode value the build does not know
- **WHEN** the app starts
- **THEN** it themes itself according to the phone's current brightness

### Requirement: The setting is independent of accent color and background palette

Choosing a theme mode SHALL NOT change the accent color or background palette, and choosing an
accent color or background palette SHALL NOT change the theme mode.

#### Scenario: Changing the theme mode leaves the accent alone

- **GIVEN** a chosen accent color
- **WHEN** the user changes the theme mode
- **THEN** the accent color is unchanged

### Requirement: The home screen widget and notifications keep following the system theme

The Android home screen widget and notifications are not themed through `MaterialApp` and SHALL
continue to follow the phone's own system theme regardless of this setting.

#### Scenario: The app is pinned to Dark while the phone is set to light

- **GIVEN** the theme mode is set to Dark and the phone's system setting is light
- **WHEN** the home screen widget or a notification renders
- **THEN** it follows the phone's light system theme, not the app's Dark override
