## ADDED Requirements

### Requirement: The pet follows the selected theme

The mascot SHALL take its body and ink colours from the theme's `MascotPalette`, and the colours of anything it shows outside its own silhouette from `colorScheme.onSurfaceVariant`.

#### Scenario: A palette change recolours the pet

- **WHEN** the user picks a different palette or accent
- **THEN** the pet's body and ink follow it, in both light and dark themes

### Requirement: The pet reacts to a mood

The mascot SHALL express `MascotMood` through the artboard, and screens SHALL NOT name animations.

#### Scenario: A routine finishes

- **WHEN** a screen passes `MascotMood.cheering`
- **THEN** the pet plays its celebrate animation once and returns to idle

#### Scenario: A step is running

- **WHEN** a screen passes `MascotMood.focused`
- **THEN** the pet holds its thinking loop until the mood changes

### Requirement: The pet comes to rest

The mascot SHALL stop animating after a short warm-up, and SHALL NOT animate at all when the system asks for reduced motion.

#### Scenario: Left alone on a screen

- **WHEN** the pet has been on screen for its warm-up
- **THEN** it holds still until the mood changes or it is pressed

### Requirement: The slot always draws something

The mascot SHALL render the hand-drawn stand-in while the Rive file loads, and if the file cannot be loaded.

#### Scenario: The runtime is unavailable

- **WHEN** the Rive file fails to load
- **THEN** the slot still draws a pet at the requested size
