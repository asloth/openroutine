## Purpose

Defines how OpenRoutine hands its notifications to Android and what it promises about when they arrive. The capability exists because Play restricts exact alarms to alarm clock and calendar apps, and an exact schedule without the permission fails silently: nothing errors on screen, and the notification never appears.

## ADDED Requirements

### Requirement: The app declares no exact alarm permission

The Android manifest SHALL NOT declare `USE_EXACT_ALARM` or `SCHEDULE_EXACT_ALARM`.

#### Scenario: The manifest is built

- **WHEN** the Android manifest is read
- **THEN** it declares neither `USE_EXACT_ALARM` nor `SCHEDULE_EXACT_ALARM`

### Requirement: Notifications fire while the device is idle, without exact timing

Every scheduled notification SHALL use an inexact schedule mode that still fires while the device is idle. The app SHALL NOT request an exact schedule, because Android rejects one from an app without the permission.

#### Scenario: A step starts

- **WHEN** a step's end and its mid-step nudges are scheduled
- **THEN** each one is scheduled inexact and allowed while idle

#### Scenario: Routine reminders are scheduled

- **WHEN** routine reminders are scheduled
- **THEN** each one is scheduled inexact and allowed while idle
