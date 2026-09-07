## Context

See `proposal.md` — Why.

`DriveSync._run` was a fixed pipeline: preflight, ensure folders, pull, push routines, sync completions. The schema authority was consulted in exactly one place, `_preflight`, and only to decide whether `meta.json` and `routines.json` agreed with each other:

```dart
final versions = authorities.map(SchemaVersion.parseSupported).toSet();
if (versions.length > 1) throw const FormatException('Conflicting Drive schema authorities');
```

`parseSupported` throws `UnsupportedSchemaVersionException` for a version this build cannot write, so the newer-folder case never reached the set comparison. It exited through `on FormatException` — the handler written for corrupt remote JSON — and was reported as retryable.

## Goals / Non-Goals

**Goals:**

- Make "refuse to write" a rule of the write path, not a consequence of a version parse throwing somewhere upstream.
- Cover every mutation the sync makes, not only `routines.json`.
- Give the state a name the UI can say something true about, and stop retrying it.

**Non-Goals:**

- Improving how much of a newer bundle this build can read. That is bounded by `LocalAdapter._planImport`, which calls `SchemaVersion.parseSupported` on the bundle and refuses what it cannot merge. Widening it means teaching the models to carry unknown fields through a round trip, which is a schema-owning change and is not this one.
- Changing `SchemaVersion` or anything under `schemas/`.
- Detecting a newer folder from anything other than a declared `schema_version`. A folder whose `meta.json` a user deleted has no authority to read, and this change does not invent one.

## Decisions

### The gate sits between the pull and the first write, not inside `_pushRoutines`

`_run` becomes: preflight → pull → **gate** → ensure folders → push routines → sync completions. One check, placed where the run stops being read-only.

*Rationale:* the rule is "this run may not write", not "this run may not write routines.json". `_ensureFolders` writes `README.md` and creates `completions/`; `_syncCompletions` rewrites a whole shard from parsed lines and strips unknown fields exactly the way `routines.json` does. A guard inside `_pushRoutines` would have left both of those writing to a folder this build does not understand.

*Alternative considered:* an early return in each of the three write methods. Rejected — three silent returns say the rule three times and lose it if a fourth writer is added later. One gate on the pipeline is the invariant.

*Consequence:* `_ensureFolders` moved from before the pull to after the gate. The pull does not depend on it — `_pullRoutines` reads the snapshot `_preflight` already fetched — and `_syncCompletions`, which needs `_completionsFolderId`, still runs after it.

### The preflight records the authority instead of throwing on it

`_authorityIdentity` replaces the bare `parseSupported` in the consistency check. A supported version collapses to the `SchemaVersion` it parses to, so two 1.0 patch releases still read as one authority. A newer version has no enum to collapse to, so it keys on its exact string, and the version is recorded in `_unwritableAuthority`.

*Rationale:* keying a newer version on its own string keeps the inconsistency check honest for a folder caught mid-upgrade between two different future versions — that is still "conflicting authorities", not merely "unwritable". And recording rather than throwing is what turns a folder ahead of this build into something to read rather than something to fail on.

*Trade-off:* the mixed set is `Object` — either a `SchemaVersion` or a `String`. Two types in one set is not lovely, but the alternative is a wrapper type whose only job is to hold one of two things that are already distinguishable by identity.

### The read side reaches the same refusal

A newer `routines.json` throws `UnsupportedSchemaVersionException` from `LocalAdapter._planImport` during the pull, before the gate is reached. `_run` catches it ahead of the `FormatException` clause and, when `isNewer`, funnels into the same refusal; when the version is *older* than anything supported it stays a plain retryable failure.

*Rationale:* both paths mean the same thing to the user, and the pull is attempted rather than skipped on purpose. If the merge later learns to read a newer bundle gracefully — the other half of §4 — the read improves without touching this file and the write stays refused.

### The block is not retried

`SyncQueue.recordUnwritableRemote` records the message without incrementing `_consecutiveFailures`, and `SyncController` schedules no retry for `SyncOutcome.remoteSchemaNewer`.

*Rationale:* this is the `needsReauth` argument, unchanged. Waiting fixes a network problem; it never fixes a build that cannot write a format. The fix is an app update, and a timer rediscovering that costs battery to learn nothing. The dirty flags stay set, so the queued work uploads on the first sync after the update.

*Alternative considered:* reusing `recordAuthExpired`, which is line-for-line the same. Rejected: the two lines are cheap and the name is the documentation — an operator reading `lastError` should not have to know that "auth expired" is where schema blocks were filed.

### Settings says what is happening, not that something failed

`SyncStatus.remoteSchemaNewer` renders `syncStatusNewerSchema`: "Your Drive folder needs a newer OpenRoutine. Changes here stay on this device until you update." `pendingChanges` is left as it is, because the changes really are still pending.

*Rationale:* it follows the Import screen's existing treatment of the same situation (`importErrorNewerSchema`), which already tells the user the file is newer, that nothing was written, and that updating is the fix. Two screens describing one condition should describe it the same way. The Drive row stays a Disconnect action — the grant is fine, the folder is fine, only this build is behind.

## Data-flow note

```
sync()
  │
  ├─ _preflight ────────── read meta.json + routines.json
  │                        classify schema authority
  │                        newer? → _unwritableAuthority = "1.2.0"
  │                        two different authorities? → FormatException
  │
  ├─ _pullRoutines ─────── validate → ExportBundle.fromJson → confirmImport
  │                        (a newer bundle throws here; caught as the same refusal)
  │
  ├─ WRITE GATE ────────── _unwritableAuthority != null
  │                          → recordUnwritableRemote(version)
  │                          → return SyncOutcome.remoteSchemaNewer   ─── nothing below runs
  │
  ├─ _ensureFolders ────── README.md, completions/
  ├─ _pushRoutines ─────── routines.json, meta.json
  └─ _syncCompletions ──── completions/YYYY-MM.ndjson
```

Everything below the gate mutates the folder. Everything above it only reads.

## Risks / Trade-offs

**A newer folder now makes this build read-only rather than erroring, which is quieter.** → Intended, but it is only an improvement if the user is told, which is why the l10n string is part of this change rather than a follow-up. A silent read-only device would be worse than the retry loop it replaces.

**The gate keys on a declared `schema_version`.** → A folder with no `meta.json` and no `routines.json` has no authority, and this build will write it as its own. That is the pre-existing behaviour and the only defensible one: the alternative is refusing to write folders that are simply empty.

**`ExportBundle` still drops unknown fields.** → True, and unchanged here. This change makes the drop unreachable over Drive whenever the folder says it is newer; it does not make the models lossless. That is the schema-owning work `SchemaVersion` and the models will need, and it is called out as a non-goal rather than half-done.

## Migration Plan

None. Nothing persisted changes shape, and no Drive file is touched by this change — by construction, it is the change that stops touching them.
