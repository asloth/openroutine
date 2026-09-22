## Context

See `proposal.md` — Why. Both defects share a shape: an exception type that nothing on the path catches. The import path drops a `FormatException` thrown by generated model code; the sync path drops a `DriveAmbiguousDiscovery` thrown by folder discovery. In both cases the layer that could say something useful never hears about it.

## Goals / Non-Goals

**Goals:**

- End both paths in a message the user can act on.
- Close the gap between what the schemas declare and what the validator enforces, so the schema stays the contract it claims to be.
- Make the model-parse boundary in `ImportService` total, so a value the schema can't constrain can't escape as a raw exception again.

**Non-Goals:**

- Resolving the duplicate folder for the user. Picking one of two folders means guessing which of their routine histories to keep, and the app can't know.
- The rest of the audit. Indexes, the N+1 reads, backup rules, and reminder re-arming are separate slices.
- Capping input sizes. That's real, and it's a different fix with its own decisions about where the limit lives.

## Decisions

### `format` validation is turned on at the call site, not the schema

`JsonSchema.validate` takes `validateFormats`, and passing `true` there enforces the `date-time` and `uuid` formats the schemas already declare.

*Alternative considered:* declaring the schemas as draft 7, which validates formats by default. Rejected — `schemas/` is a public API, and dropping two drafts to change a client library's default would be a breaking change to the contract for a reason that has nothing to do with the contract.

*Alternative considered:* adding `pattern` constraints for timestamps next to the existing UUID patterns. Rejected for now: it duplicates in a regex what `format: date-time` already says, in both copies of five files. Worth revisiting only if a second client needs the constraint expressed without format support.

### `ImportService` owns the model-parse boundary

`ExportBundle.fromJson` is wrapped, and a `FormatException` or `ArgumentError` from it becomes `ImportException(ImportFailureReason.schemaViolation)`.

*Rationale:* format validation closes the case the audit confirmed, but not the class. The schema constrains types, enums, and patterns; the models also parse. Any value that satisfies the first and defeats the second lands here, and the screen already knows how to show a schema violation. Catching at the screen instead would fix the one symptom and leave `validateJsonString` able to throw raw exceptions at any other caller.

`ArgumentError` is included because a value outside a Dart enum throws that rather than a `FormatException`. Errors aren't usually caught, but this one is a data defect crossing a trust boundary, not a bug in the code.

### A duplicate folder is its own sync outcome, not a generic failure

`SyncOutcome.ambiguousFolder` and `SyncStatus.ambiguousFolder` join the existing sets, and Settings gets a string that names the problem and the fix.

*Alternative considered:* recording it as a retryable failure, which is one line. Rejected because it's false twice over. Retrying can't help — the second folder is still there on the next run, so the app would back off and retry forever against a condition only the user can clear — and "Sync failed — will retry" tells someone whose Drive needs tidying to wait instead.

It follows `remoteSchemaNewer` exactly: recorded through `recordUnwritableRemote`, no retry scheduled, pending changes left pending and uploaded once the duplicate is gone.

### Escaping and sanitizing are done the way the codebase already does them

The notification route reuses `Uri.encodeComponent`, matching `widgetLaunchRoute`. The export file name keeps `[A-Za-z0-9-_ ]` and collapses the rest, so a name full of punctuation still produces a file name.

*Rationale:* neither is exploitable today — ids are schema-constrained UUIDs, and `share_plus` builds its temp path in a shape that makes traversal fail — but both are one line, and "safe because of something two layers away" is the kind of reasoning that stops being true after a refactor.

## Risks / Trade-offs

**Turning on format validation could reject a file that imported before.** → Only if that file was already invalid against the published schema. Every bundle the app writes uses `DateTime.toIso8601String` and v7 UUIDs, which satisfy both declared formats, and the UUID format is additionally pinned by a `pattern` that was already enforced. A test imports a bundle written by `ExportService` to keep that true.

**`json_schema` decides what `format: date-time` means.** → Its `date-time` check is stricter than `DateTime.parse`, so a value could in principle be rejected by the validator and still parse. That's the safe direction: the failure is a clear schema-violation message rather than a stuck screen.

**A new enum value in `SyncOutcome` and `SyncStatus` reaches every exhaustive switch over them.** → That's the point: the analyzer names each place that has to decide, and `--fatal-infos` makes a missed one a build failure rather than a silent fallthrough.
