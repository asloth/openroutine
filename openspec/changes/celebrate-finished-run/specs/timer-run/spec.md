## MODIFIED Requirements

### Requirement: The finished screen celebrates and returns to today

When a run finishes, the timer SHALL show the mascot cheering, at the same size the mascot has on
the running screen, a finished title, what got done, any estimate adjustment on offer, and a Back to
today action. The content SHALL sit centered on the screen when it fits, and scroll when it
doesn't. A finished run SHALL play a one-shot confetti burst from the mascot in the palette's
colours.

#### Scenario: Back to today

- **WHEN** the user selects Back to today
- **THEN** the timer closes

#### Scenario: The mascot matches the running screen's size

- **GIVEN** a run that just finished
- **WHEN** the finished screen renders
- **THEN** the mascot's rendered size equals the mascot's rendered size on the running screen

#### Scenario: The content is centered

- **GIVEN** a finished screen whose content fits on the screen
- **WHEN** it renders
- **THEN** the content's vertical center matches the screen's

#### Scenario: A finished run gets confetti

- **GIVEN** a run the user finished
- **WHEN** the finished screen renders
- **THEN** confetti bursts from the mascot once and then stops

#### Scenario: A stopped run gets no confetti

- **GIVEN** a run the user stopped early
- **WHEN** the finished screen renders
- **THEN** the mascot rests and no confetti plays

#### Scenario: Reduced motion drops the confetti

- **GIVEN** the device asks for reduced motion
- **WHEN** a finished run's screen renders
- **THEN** the mascot shows and no confetti plays
