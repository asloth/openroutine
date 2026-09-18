## Why

Until now, the create/edit form only let you choose days for `scheduled` routines. For `flexible`
ones, it hard-forced `days: []`. That means every flexible routine on a real device has an empty
day list.

Two other changes are landing alongside this one: the form will require days for both modes, and
the Today screen will only show a flexible routine on the days it's actually due. Once that ships,
an empty day list stops meaning "show up every day" and starts meaning "never show up." Every
flexible routine already on the user's phone would vanish from Today with no warning and no way to
fix it from the UI, since the form has no "no days selected" state to recover from.

We're backfilling those routines to all seven days instead, so nothing disappears and they keep
behaving exactly as they do today: always due.

## What Changes

- Bump the Drift `schemaVersion` from 7 to 8.
- Add an `onUpgrade` branch that sets `schedule_days` to all seven days (`mon,tue,wed,thu,fri,sat,sun`)
  for every routine where `schedule_mode = 'flexible'` and `schedule_days = ''`.
- Leave everything else alone: scheduled routines, flexible routines that already have days, and
  every other column and table.

## Capabilities

### New Capabilities

- `local-storage-migration` — what a Drift schema upgrade is required to do to existing on-device
  data, distinct from the column-level schema shape defined in `tables.dart`.

## Impact

**Code.** `app/lib/services/storage/drift/app_database.dart` only — the `schemaVersion` getter, its
doc comment, and one new `onUpgrade` branch. No change to `tables.dart`; `schedule_days` already
exists as a column and needs no alteration.

**Storage and schema.** Drift schema version only, not the JSON `SchemaVersion` used in Drive's
`meta.json`. Nothing under `schemas/` changes — `days` is already valid for both schedule modes
there, and this change writes data, not shape.

**Existing users.** Every flexible routine with an empty day list moves to all seven days on next
app open. A flexible routine that was somehow saved with days already (for example, from a Drive
pull written by a build that already required them) is left untouched. A scheduled routine with an
empty day list is bad data the form never produces, so the migration doesn't invent days for it —
that's a case for the form's own validation, not a backfill.

**i18n.** None. This is a silent data migration with no UI surface.

**Rollback.** Reverting this change restores `schemaVersion` to 7. Any device that has already
upgraded to 8 keeps its backfilled days — the migration doesn't run in reverse, and there's nothing
destructive to undo. A subsequent reinstall of the old build simply never reads `schemaVersion`
again once the database is already newer.
