## ADDED Requirements

### Requirement: Reminders sound like Ochi

On Android, a routine reminder SHALL play Ochi's hello sound, bundled with the app, on its own
notification channel. The app SHALL delete reminder channels that earlier builds created and no
longer uses.

#### Scenario: A reminder plays the hello

- **GIVEN** a routine with a reminder
- **WHEN** the reminder fires on Android
- **THEN** it plays Ochi's hello rather than the system default sound

#### Scenario: The old channel goes away

- **GIVEN** a device that has the `routine_reminder_v1` channel from an earlier build
- **WHEN** the app starts notifications
- **THEN** that channel is deleted
