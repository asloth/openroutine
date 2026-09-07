## ADDED Requirements

### Requirement: Navigation between screens is animated

Moving between screens SHALL animate rather than replacing one screen with the next instantaneously. The transition SHALL obey the duration bound and the directional easing this capability already defines: the arriving screen decelerates in, the departing screen accelerates out.

The transition SHALL be defined once and shared by every route, so that navigation feels the same everywhere rather than varying by destination.

#### Scenario: The user navigates to another screen

- **WHEN** the user navigates from one screen to another
- **THEN** the arriving screen animates in rather than appearing instantly
- **AND** the animation completes within the duration bound for user-initiated motion

#### Scenario: The user navigates back

- **WHEN** the user navigates back to the previous screen
- **THEN** the departing screen animates out rather than disappearing instantly

#### Scenario: Navigation under reduced motion

- **GIVEN** the platform reports that the user has disabled animations
- **WHEN** the user navigates between screens
- **THEN** the destination screen is presented immediately
- **AND** every control on it is reachable

### Requirement: Continuous ambient motion stops under reduced motion

Motion that repeats indefinitely without being triggered by the user — a looping idle animation, a breathing or pulsing decoration — SHALL NOT play when the platform reports that animations are disabled. It SHALL settle at a resting appearance rather than freezing at an arbitrary point in its cycle.

This is distinct from the existing requirement covering animated state changes. A state change that is suppressed still reaches its end state; ambient motion has no end state to reach, so it must have a defined resting appearance instead.

#### Scenario: Ambient motion with animations disabled

- **GIVEN** the platform reports that the user has disabled animations
- **WHEN** a surface with continuous ambient motion is displayed
- **THEN** it does not animate
- **AND** it renders at its resting appearance

#### Scenario: Ambient motion with no preference set

- **GIVEN** the platform reports no reduced-motion preference
- **WHEN** a surface with continuous ambient motion is displayed
- **THEN** it animates continuously

#### Scenario: Ambient motion is exempt from the user-initiated duration bound

- **GIVEN** a surface whose motion repeats indefinitely and is not triggered by the user
- **WHEN** it animates
- **THEN** it MAY run longer than the bound on user-initiated motion, because nothing is waiting on it
