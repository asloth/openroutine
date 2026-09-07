## 1. The write gate

- [x] 1.1 Add a test seeding a Drive folder whose `meta.json` and `routines.json` both declare `1.2.0`, with a local routine queued, asserting the sync returns a distinct `SyncOutcome.remoteSchemaNewer`, uploads nothing, and leaves the work queued — and verify it fails, because the case is reported as `SyncOutcome.failed` by the corrupt-remote-data handler
- [x] 1.2 Add a test asserting the same folder gets no `README.md`, no `completions/` folder and no shard even with a completion month queued, and verify it fails on the outcome for the same reason
- [x] 1.3 Add a test asserting the recorded error names the blocking version and that no retry backoff accumulates, and verify it fails with `consecutiveFailures` at 1
- [x] 1.4 Replace the old "newer or inconsistent authority" test with one covering only the inconsistent half — `meta.json` at 1.1.0 against `routines.json` at 1.0.0 — and verify it still refuses before the local merge
- [x] 1.5 Classify the authority in `_preflight` with `_authorityIdentity`, recording a newer version in `_unwritableAuthority` instead of throwing, and keep the consistency check working for two differing future versions
- [x] 1.6 Move `_ensureFolders` below the gate and add the write gate to `_run` between the pull and every mutation, returning `SyncOutcome.remoteSchemaNewer`, and verify 1.1–1.4 pass
- [x] 1.7 Catch `UnsupportedSchemaVersionException` in `_run` ahead of the `FormatException` clause so a newer bundle refused by the local merge reaches the same refusal, while an unsupported *older* version stays a plain retryable failure

## 2. Not retrying what waiting cannot fix

- [x] 2.1 Add `SyncQueue.recordUnwritableRemote`, which records the reason without incrementing the failure count, and verify 1.3 passes
- [x] 2.2 Add `SyncStatus.remoteSchemaNewer` and handle `SyncOutcome.remoteSchemaNewer` in `SyncController.syncNow` without scheduling a retry, leaving `pendingChanges` untouched

## 3. Telling the user

- [x] 3.1 Add a test asserting `syncStatusNewerSchema` resolves in both shipped locales and that the two differ, and verify it fails to compile because the key does not exist
- [x] 3.2 Add `syncStatusNewerSchema` to `app_en.arb` (with a description) and `app_es.arb` together, following the Import screen's existing wording for the same condition, and verify 3.1 passes
- [x] 3.3 Render it from `SettingsScreen._syncLabel`, leaving the Drive row's connect/disconnect action alone — the grant is not what is wrong

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter gen-l10n` from `app/`
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 4.3 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes above the 291 baseline
- [x] 4.4 Run `openspec validate fix-drive-write-gate --type change --strict` and verify it passes
