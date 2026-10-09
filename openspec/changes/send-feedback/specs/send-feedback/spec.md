## Purpose

Lets someone send feedback about OpenRoutine through their own email app, so the app never sends anything itself.

## ADDED Requirements

### Requirement: Settings offers a way to send feedback

Settings › About SHALL include a Send feedback row. Selecting it SHALL open the person's email app with a draft addressed to the project's feedback address, with a subject, space to write first, and a details block holding the app version and build, the operating system, and the app language.

#### Scenario: Someone selects Send feedback

- **WHEN** the person selects Send feedback
- **THEN** their email app opens with a draft to the feedback address
- **AND** the draft's body starts with space to write, followed by the details block

#### Scenario: Spaces survive the trip to the email app

- **WHEN** the draft is built
- **THEN** spaces in the subject and body are encoded as `%20`, not `+`

### Requirement: No email app is not a dead end

If no app can open the draft, the app SHALL show the feedback address with an action to copy it.

#### Scenario: The phone has no email app

- **GIVEN** no app can handle a `mailto:` link
- **WHEN** the person selects Send feedback
- **THEN** a message shows the feedback address with a Copy action
