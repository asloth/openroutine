## Purpose

Defines the app-wide motion contract for OpenRoutine: the perceptual bounds every animation must satisfy, how easing communicates whether something is arriving or leaving, and how motion degrades when the platform or the user asks for less of it. The contract exists so that motion reads as one deliberate system rather than as per-widget choices, and so that a reviewer can tell a conforming animation from a non-conforming one without re-litigating taste.

## ADDED Requirements

### Requirement: Bounded duration for user-initiated motion

Motion that responds directly to a user action SHALL complete within 300 milliseconds. Motion that is not user-initiated — ambient or continuous indicators — is exempt from this bound, because it is not blocking the user's next action.

#### Scenario: A tap triggers a transition

- **WHEN** the user taps a control that animates a change of state
- **THEN** the resulting motion completes within 300 milliseconds of the tap

#### Scenario: A continuous indicator runs longer than the bound

- **GIVEN** an indicator that communicates ongoing progress rather than responding to a tap
- **WHEN** it animates
- **THEN** it MAY exceed 300 milliseconds without violating this requirement

### Requirement: Easing communicates direction of travel

Motion SHALL ease so that its curve reflects whether an element is arriving or leaving. Entrances SHALL decelerate into place — fast on arrival, settling gently. Exits SHALL accelerate away — building momentum before departure. An entrance that accelerates, or an exit that decelerates, reads as the opposite of what is happening.

#### Scenario: An element enters the screen

- **WHEN** an element animates into view
- **THEN** its easing decelerates toward its final position

#### Scenario: An element leaves the screen

- **WHEN** an element animates out of view
- **THEN** its easing accelerates away from its starting position

### Requirement: Linear easing is reserved for continuous progress

Linear easing SHALL be used only for indicators that map directly onto elapsed time or completion, such as a progress ring or bar. Motion that represents an object moving SHALL NOT use linear easing, because nothing physical starts and stops at a constant speed.

#### Scenario: A progress indicator advances

- **GIVEN** an indicator whose value maps onto elapsed time
- **WHEN** it advances
- **THEN** it MAY animate linearly

#### Scenario: An element changes position or size

- **WHEN** an element animates its position, scale, or opacity as an object
- **THEN** it does not animate linearly

### Requirement: Press feedback stays within subtle deformation

An interactive control SHALL give visible feedback on press, and that feedback SHALL deform the control by no more than five percent in either direction — a scale between 0.95 and 1.05 inclusive. Feedback outside that range reads as a glitch rather than as a press; no feedback at all leaves the control feeling dead.

#### Scenario: The user presses an interactive control

- **WHEN** the user presses a control that accepts input
- **THEN** the control visibly responds
- **AND** its scale stays within 0.95 to 1.05

### Requirement: Sequenced entrances stay within the stagger budget

When several elements enter together as a group, the delay between consecutive elements SHALL NOT exceed 50 milliseconds. Beyond that, a list stops reading as one group arriving and starts reading as items loading one at a time.

#### Scenario: A list of items enters as a group

- **WHEN** multiple sibling elements animate in as a sequence
- **THEN** the delay between consecutive elements is at most 50 milliseconds

### Requirement: Comparable elements animate identically

Elements that belong to the same class of interaction SHALL use the same duration and easing as each other. Two controls that do the same kind of thing at different speeds read as an inconsistency, not as emphasis.

#### Scenario: Two controls of the same kind animate

- **GIVEN** two controls that perform the same class of interaction
- **WHEN** each animates in response to the same kind of user action
- **THEN** both use the same duration and the same easing

### Requirement: Reduced-motion requests are honoured

When the platform reports that the user has asked for reduced or disabled animations, motion SHALL resolve immediately to its end state rather than playing. The user SHALL NOT be left in a partial or frozen intermediate state, and no interaction SHALL become unavailable as a result of motion being suppressed.

#### Scenario: The platform reports that animations are disabled

- **GIVEN** the platform reports that the user has disabled animations
- **WHEN** an animated state change occurs
- **THEN** the interface renders the end state immediately
- **AND** every control that would be reachable after the animation is reachable

#### Scenario: The platform reports no such preference

- **GIVEN** the platform reports no reduced-motion preference
- **WHEN** an animated state change occurs
- **THEN** the motion plays under the bounds defined by this capability
