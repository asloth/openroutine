## Why

`docs/SPEC.md` §4 states the rule for two devices on different app versions: "Clients on older schemas must read newer files gracefully (unknown fields ignored) and refuse to write." Only the read half was built.

The refusal to write existed by accident, not by rule. `DriveApiClient` already parses `meta.json`'s `schema_version` into `DriveAuthoritySnapshot.schemaAuthority`, but nothing in the push path consults it. A folder ahead of this build was stopped one level earlier, by the preflight consistency check calling `SchemaVersion.parseSupported` and throwing — which lands in the same `FormatException` handler as a corrupt file. So the case behaved like a transient server problem: `SyncOutcome.failed`, a growing backoff, a retry timer that will never succeed, and "Sync failed — will retry" in Settings. The one thing the user needed to know — *your edits are not leaving this device, and updating the app is what fixes it* — was the one thing they were not told.

Why it matters that the rule is a rule: every push serialises through `ExportBundle.toJson`, and `schemas/export.schema.json` sets `additionalProperties: true`. A field a newer client added passes validation on the way in, does not survive the round trip through this build's models, and would be written back to Drive without it. The same is true of a completion shard, which is rebuilt line by line from parsed `CompletionLog`s. One push from an old phone would silently erase the newer phone's data — from the folder the user can see in their own Drive. A refusal that depends on the shape of an unrelated consistency check is not a guarantee against that; a gate on the write path is.

## What Changes

- Classify the Drive folder's schema authority in the preflight instead of throwing on it: a version newer than this build's is recorded, not treated as malformed remote data.
- Add a write gate to `DriveSync._run`, immediately after the pull and before every mutation. When the folder is on a newer schema, nothing is written: no `routines.json`, no `meta.json`, no `README.md`, no completion shard, no `completions/` folder.
- Add `SyncOutcome.remoteSchemaNewer` and `SyncStatus.remoteSchemaNewer` so the block is its own state rather than a flavour of failure, and do not schedule a retry for it — the same reasoning already applied to a revoked grant.
- Keep queued work queued, so everything uploads once the app is updated.
- Tell the user, in Settings, in both shipped locales.

## Capabilities

### New Capabilities

- `drive-write-gate` — what an OpenRoutine build may write to a Drive folder that another build's schema owns, and what the user is told when it may not.

## Impact

**Code.** `app/lib/services/storage/drive/drive_sync.dart` (authority classification, write gate, new outcome), `app/lib/services/storage/drive/sync_queue.dart` (a recorder that does not accumulate backoff), `app/lib/state/sync_provider.dart` (new status, no retry), `app/lib/screens/settings/settings_screen.dart` (one label). Tests in `app/test/services/storage/drive/drive_sync_test.dart` and `app/test/l10n/sync_status_strings_test.dart`.

**Storage and schema.** None. No file under `schemas/` changes, `SchemaVersion` is untouched, and nothing new is persisted — the block is derived on every run from what the folder says about itself. The change is about which writes are *not* made.

**Existing users.** Anyone whose devices are on one version sees no difference. Anyone with a device behind their others stops uploading to Drive and gets told why, instead of silently overwriting the newer device's routines or watching a retry timer fail forever.

**i18n.** One new string, `syncStatusNewerSchema`, added to `app_en.arb` and `app_es.arb` together.

**Rollback.** Revert the commit. Nothing is persisted differently and no Drive file changes shape, so there is nothing to unwind — the folder is left exactly as the newer client wrote it, which is the point. The only thing lost on rollback is the refusal itself.
