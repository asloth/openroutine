## Purpose

Defines what an OpenRoutine build may write to a Drive folder whose schema another build owns, and what the user is told when it may not.

The capability exists because the folder is shared, visible, and writable by any version the user has installed. docs/SPEC.md §4 settles the direction of trust between versions — an older client reads a newer folder and refuses to write it — and this capability is where that rule is enforced. The refusal has to be a property of the write path rather than a side effect of a version parse failing somewhere upstream, because the failure it prevents is silent: every push serialises through this build's models, `schemas/export.schema.json` permits unknown properties, and a field a newer client added would pass validation on the way in and be gone on the way out.

Schema-version note: this capability reads `schema_version` and changes nothing about it. No file under `schemas/` and no value in `SchemaVersion` is altered.

## ADDED Requirements

### Requirement: A folder on a newer schema is read-only

When the Drive folder declares a `schema_version` that this build cannot write, the client SHALL NOT write anything to that folder. This includes `routines.json`, `meta.json`, `README.md`, the `completions/` folder, and every completion shard.

The client SHALL continue to read the folder. A file it can interpret SHALL still be merged into local data on the normal last-writer-wins terms.

Queued work SHALL remain queued. The client SHALL NOT clear a dirty flag for work it did not upload, so that everything pending is uploaded on the first sync after the app is updated.

#### Scenario: Local edits are waiting for a folder that is ahead of this build

- **GIVEN** the Drive folder declares a schema version newer than this build writes
- **AND** the device has local routine changes queued
- **WHEN** a sync runs
- **THEN** nothing is uploaded
- **AND** the local changes are still queued
- **AND** the local data is unchanged

#### Scenario: The folder is missing files this build would normally create

- **GIVEN** the Drive folder declares a schema version newer than this build writes
- **AND** the folder has no `README.md` and no `completions/` folder
- **WHEN** a sync runs
- **THEN** neither is created

#### Scenario: A completed run is waiting to be recorded

- **GIVEN** the Drive folder declares a schema version newer than this build writes
- **AND** a completion shard for the current month is queued
- **WHEN** a sync runs
- **THEN** the shard is not rewritten
- **AND** the month is still queued

#### Scenario: The folder is on a schema this build writes

- **GIVEN** the Drive folder declares a schema version this build supports
- **WHEN** a sync runs
- **THEN** it pulls and pushes as normal

### Requirement: The block is reported as its own state

A refusal to write on schema grounds SHALL be reported as a distinct sync outcome, separate from a transient failure, an offline device, and a lapsed grant.

The client SHALL NOT schedule a retry for it and SHALL NOT accumulate retry backoff, because no elapsed time makes a build able to write a format it does not have. The recorded reason SHALL name the version that blocked the write.

The user SHALL be told, in Settings, that their changes are staying on this device and that updating the app is what resolves it. That string SHALL exist in every shipped locale.

#### Scenario: The user opens Settings while blocked

- **GIVEN** a sync was refused because the folder is on a newer schema
- **WHEN** the user opens Settings
- **THEN** the sync row says the folder needs a newer version of the app and that changes are staying on this device
- **AND** it does not say that sync failed or that it will retry

#### Scenario: Time passes after a refused sync

- **GIVEN** a sync was refused because the folder is on a newer schema
- **WHEN** no app update has been installed
- **THEN** no retry is scheduled
- **AND** no retry backoff has accumulated

#### Scenario: An operator inspects the recorded reason

- **GIVEN** a sync was refused because the folder is on a newer schema
- **WHEN** the recorded sync error is read
- **THEN** it names the folder's schema version

### Requirement: The folder's schema authority must be consistent

The client SHALL treat `meta.json` and `routines.json` as declaring one authority. Two versions that this build writes identically — patch releases of the same minor line — SHALL count as one authority. Two versions that differ otherwise SHALL be refused as inconsistent rather than merged, and that refusal SHALL also write nothing.

#### Scenario: The folder is caught between two writes

- **GIVEN** `meta.json` and `routines.json` declare different schema versions
- **WHEN** a sync runs
- **THEN** it refuses before merging anything into local data
- **AND** nothing is uploaded
- **AND** the local data is unchanged
