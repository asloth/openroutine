## Purpose

Defines what the app owes a person when data they can produce themselves — a hand-edited or agent-written import file, a Drive folder they copied — makes an operation impossible. The capability exists because the failures that strand a screen aren't the ones the code anticipates; they're the ones that reach a layer with no handler for them, where the only evidence is a spinner that never stops.

## ADDED Requirements

### Requirement: An import that can't be read ends in a message

The app SHALL report an unreadable import file to the user and return the import screen to a state they can act from. It SHALL NOT leave the screen busy after a failure.

Validation SHALL enforce the formats the published schemas declare, so a value the contract already forbids is rejected before it reaches a model.

An import file that satisfies the schema but can't be parsed into the app's models SHALL be reported as a schema violation rather than escaping as an unhandled error.

#### Scenario: A timestamp isn't a date

- **GIVEN** an import file whose `exported_at` is not a valid date-time
- **WHEN** the user chooses it
- **THEN** the import is rejected as a schema violation, and the screen shows that message instead of staying busy

#### Scenario: A value defeats the models but satisfies the schema

- **GIVEN** an import file that passes schema validation but can't be parsed into the app's models
- **WHEN** the user chooses it
- **THEN** the import is rejected with a schema-violation message rather than an unhandled error

#### Scenario: A file the app wrote itself

- **GIVEN** an export file this build produced
- **WHEN** the user imports it
- **THEN** it validates and previews as it did before format validation was enforced

### Requirement: A Drive folder the app can't identify is reported, not retried

When more than one folder in Drive carries the app's folder name, sync SHALL stop with an outcome of its own and record why. It SHALL NOT retry on a timer, because no amount of waiting removes the duplicate, and it SHALL NOT report the condition as a generic sync failure.

The app SHALL NOT choose between the candidate folders on the user's behalf.

Pending local changes SHALL stay pending and SHALL be uploaded on the first run after the duplicate is resolved.

#### Scenario: Two folders share the app's name

- **WHEN** a sync runs and folder discovery matches more than one folder
- **THEN** sync reports the ambiguous-folder outcome, and Settings shows a message naming the duplicate as the cause

#### Scenario: Two folders share the app's name when connecting

- **WHEN** the user connects Google Drive and folder discovery matches more than one folder
- **THEN** connecting reports the ambiguous-folder outcome, and Settings shows the same message instead of reporting the app as up to date

#### Scenario: The duplicate is still there

- **GIVEN** a sync that stopped on an ambiguous folder
- **WHEN** no retry timer has been scheduled
- **THEN** the app waits for the user rather than syncing again on its own

#### Scenario: The duplicate is removed

- **GIVEN** local changes that were waiting while the folder was ambiguous
- **WHEN** a later sync finds a single folder
- **THEN** those changes are uploaded

#### Scenario: The user asks to sync again

- **GIVEN** Settings showing the ambiguous-folder message
- **WHEN** the user selects the Drive row
- **THEN** the app offers to sync rather than disconnect, and selecting it approves the one folder Drive now holds and syncs, whichever of the two folders the user kept

### Requirement: A Drive folder no approval covers waits for the user

When no cutover approval covers the folder Drive holds, because it was removed or replaced, sync SHALL stop with an outcome of its own. It SHALL NOT retry on a timer, because only the user can approve a folder, and Settings SHALL offer the action that does.

#### Scenario: The approved folder is gone

- **GIVEN** an approval for a folder that no longer exists
- **WHEN** a sync runs
- **THEN** sync reports that it's waiting for approval, schedules no retry, and keeps pending changes pending

#### Scenario: The user approves the folder

- **GIVEN** Settings showing that sync is waiting for approval
- **WHEN** the user selects Sync now
- **THEN** the app approves the folder Drive holds now, creating it if none exists, and syncs

### Requirement: Untrusted values are escaped before they become routes or file names

A value that arrives from outside the app's own UI SHALL be escaped before it's used as a URL path segment, and sanitized before it's used as a file name.

#### Scenario: A notification carries a routine id

- **WHEN** the user taps a routine reminder
- **THEN** the id from the payload is escaped before it becomes part of the route

#### Scenario: A routine name contains path characters

- **WHEN** the user exports a routine whose name contains separators or other characters a file name can't carry
- **THEN** the exported file name keeps the readable part of the name and drops the rest
