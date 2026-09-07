## Purpose

Defines when the app interrupts someone *during* a step rather than at its boundary, which steps are allowed to do it, and what such an interruption may do. The capability exists because the app's only existing notification arrives when a step's estimate has already run out — useful as a record, useless as a rescue. A mid-step nudge is the one notification in this app whose job is to break attention rather than to mark a moment, so the rules about which steps may fire one, and how quiet it is allowed not to be, belong in the spec rather than in a constant.

It also fixes the boundary between two defaults that are easy to conflate: what an absent stored value means, and what the app suggests when someone creates a step. They are different, and only the first is a compatibility guarantee.

## ADDED Requirements

### Requirement: A step carries its own mid-step reminder opt-in

Each step SHALL persist whether it nudges the user partway through its estimate. The setting SHALL be a property of the step, not of the routine, the run, or the app, because the property being expressed — that this activity is one a person drifts out of — is a property of the activity.

The stored value SHALL default to false. A step that has never been asked SHALL NOT fire a mid-step reminder.

#### Scenario: A step created before this capability existed

- **GIVEN** a step stored before mid-step reminders existed
- **WHEN** the app reads it
- **THEN** its mid-step reminder is off, and running the step behaves exactly as it did before

#### Scenario: Two steps in one routine disagree

- **GIVEN** a routine with one step opted in and one step opted out
- **WHEN** the routine runs
- **THEN** only the opted-in step nudges during it

### Requirement: An opted-in step nudges at half and four-fifths of its estimate

While an opted-in step is running, the app SHALL notify the user at 50% and at 80% of that step's estimate, measured from when the step started.

Each nudge SHALL be scheduled with the operating system against an absolute time rather than held in process, so that it fires whether or not the app survives.

The estimate used SHALL be the one in force when the step starts, so that a step whose estimate was revised by the calibration prompt nudges against the revised value on its next run without any stored reminder state changing.

#### Scenario: A ten-minute opted-in step runs

- **GIVEN** an opted-in step estimated at ten minutes
- **WHEN** it starts
- **THEN** the user is notified five minutes in and eight minutes in, in addition to the existing notification at ten minutes

#### Scenario: The app is killed mid-step

- **GIVEN** an opted-in step running with its nudges scheduled
- **WHEN** the app's process does not survive to the nudge times
- **THEN** the nudges still fire

### Requirement: Short and open-ended steps never nudge

A step whose estimate is under two minutes SHALL NOT fire either mid-step reminder, even when opted in. Three alerts inside ninety seconds is not a reminder.

A step with no explicit time SHALL NOT fire either mid-step reminder, because there is no estimate to take a fraction of.

The floor SHALL be evaluated when the step starts, against the estimate in force at that moment.

#### Scenario: An opted-in step is estimated at ninety seconds

- **GIVEN** an opted-in step estimated at ninety seconds
- **WHEN** it starts
- **THEN** no mid-step reminder is scheduled, and only the existing end-of-estimate notification fires

#### Scenario: An opted-in step has no explicit time

- **GIVEN** an opted-in step with no explicit time
- **WHEN** it starts
- **THEN** no mid-step reminder is scheduled

### Requirement: A mid-step reminder is audible and felt

A mid-step reminder SHALL play sound and vibrate. It exists to reach someone whose attention has left the routine, and a silent notification does not do that.

It SHALL be delivered on a notification channel separate from the end-of-estimate notification, so that the end-of-estimate notification remains silent and so that a user who wants to mute mid-step reminders can do so at the operating-system level without losing the quiet boundary marker.

#### Scenario: Both kinds of notification fire during one step

- **WHEN** an opted-in step fires its mid-step reminders and then its end-of-estimate notification
- **THEN** the mid-step reminders sound and vibrate and the end-of-estimate notification stays silent

### Requirement: A pending nudge never outlives its step

When a step ends, is skipped, is deferred, or its run is abandoned, every pending mid-step reminder for that step SHALL be cancelled.

When a run is paused, pending mid-step reminders SHALL be cancelled; on resume they SHALL be rescheduled against the recomputed remaining time, because they are absolute times and a paused step's marks have moved.

#### Scenario: A step is finished early

- **GIVEN** an opted-in step running with nudges pending
- **WHEN** the user marks it done before the first nudge
- **THEN** no mid-step reminder fires, including during the following step

#### Scenario: A run is paused past a nudge time

- **GIVEN** an opted-in step paused before its 50% mark
- **WHEN** the run resumes
- **THEN** the nudge fires at the 50% mark of the time actually spent on the step, not at the time it was originally scheduled for

### Requirement: The suggested value for a new step is not the stored default

When the user creates a new step, the form SHALL start with the mid-step reminder turned on, so the capability is discoverable rather than hidden behind a switch nobody finds.

This SHALL be a property of the form's initial state only. It SHALL NOT change the value an absent field means, and it SHALL NOT alter any step that already exists or arrives by import.

#### Scenario: A new step is created and saved unchanged

- **WHEN** the user creates a step and saves it without touching the reminder control
- **THEN** the step is stored with the mid-step reminder on

#### Scenario: The form default changes after steps already exist

- **GIVEN** steps stored with the mid-step reminder off
- **WHEN** the app is updated to suggest it for new steps
- **THEN** the existing steps still have it off

### Requirement: The step opt-in is an additive, optional part of the public step schema

`schemas/step.schema.json`, and the bundled copy the app validates against, SHALL describe the mid-step reminder opt-in as an optional boolean property defaulting to false. It SHALL NOT be listed as required.

The two schema files SHALL remain byte-identical, because the repository copy is the documented public contract and the bundled copy is what the app actually validates against.

Adding the property SHALL bump the export schema version's minor component, and the app SHALL continue to accept exports written at every earlier supported version. A step document that omits the property SHALL be read as having the reminder off.

#### Scenario: An integration written before this change exports a step

- **GIVEN** a step document with no mid-step reminder property, written against an earlier schema version
- **WHEN** the app imports it
- **THEN** the document validates, and the step is stored with the reminder off

#### Scenario: A file written at the new version reaches an older build

- **GIVEN** an export written at the new schema version
- **WHEN** it is imported by a build that predates the version
- **THEN** the import is refused as newer, the user is told to update, and no local data is changed
