## Context

See `proposal.md` — Why. This change is one of three landing around the same idea. The other two
own the form (require days for both modes) and the Today screen (filter flexible routines by day).
This one owns only the data already on disk: it has to run before, or land safely independent of,
either of those, because the day the Today filter ships is the day an empty list starts meaning
something different than it does today.

`app/lib/services/storage/drift/app_database.dart` already has a `schemaVersion` getter and an
`onUpgrade` `MigrationStrategy` with one `if (from < N)` branch per version, most recently v7's
removal of the `triggers` table. `app/lib/services/storage/drift/tables.dart` defines
`Routines.scheduleDays` as `text().map(const DayListConverter()).withDefault(const Constant(''))()` —
already exactly the column this change needs, storing days as a comma-joined list of `DayOfWeek`
enum names (`DayListConverter`, same file).

## Goals / Non-Goals

**Goals:**

- Every flexible routine with an empty day list reads as "all seven days" after the upgrade,
  matching how it already behaves today (always due, since nothing filtered on days before).
- Nothing else in the database changes shape or value.

**Non-Goals:**

- Changing `tables.dart` or the stored column shape. `schedule_days` already exists and doesn't
  need a new default, a new column, or a type change — only a value rewrite for rows that qualify.
- Touching the form or the Today screen. Those are separate changes, requiring and consuming days
  respectively; this one only makes sure the data they'll both work with makes sense.
- Backfilling scheduled routines. A scheduled routine with an empty day list is invalid input the
  form has never produced — inventing days for it would be guessing at what the user meant, which
  isn't this migration's job.

## Decisions

### A raw `UPDATE`, not a per-row read-modify-write

The migration runs a single `customStatement` — `UPDATE routines SET schedule_days = ? WHERE
schedule_mode = ? AND schedule_days = ''` — rather than reading every routine through Drift's query
builder, computing the new value in Dart, and writing it back row by row.

*Rationale:* the `WHERE` clause already expresses the entire selection criteria as a SQL predicate,
and every matching row gets the identical new value. There's no per-row computation this needs Dart
for. `app_database.dart`'s v7 branch already establishes `customStatement` as the pattern for
migration SQL that isn't a straightforward `addColumn`.

*Alternative considered:* select flexible routines with empty days via the generated `Routines`
table, then loop and call `update(...).write(...)` per row. Rejected — same result, more code, and
it forces every row into memory during the migration instead of letting SQLite do the work.

### The values come from `DayOfWeek.values` and `ScheduleMode.flexible.name`, not string literals

The migration computes `DayOfWeek.values.map((day) => day.name).join(',')` and passes
`ScheduleMode.flexible.name` as bound parameters, rather than writing `'mon,tue,wed,thu,fri,sat,sun'`
and `'flexible'` directly into the SQL string.

*Rationale:* both enums are already imported into `app_database.dart` for the generated `textEnum`
converters. Deriving the values from them means a hypothetical future reorder of `DayOfWeek` (it
hasn't happened, and shouldn't) can't silently desync this migration from `DayListConverter`'s
actual output. It also keeps the stored format provably identical to what the converter itself
would produce for "every day," rather than a hand-typed string that happens to match today.

### The `WHERE` clause is the entire scope — no companion Dart-side filtering

`schedule_mode = 'flexible' AND schedule_days = ''` is deliberately narrow. It does not touch
`deleted_at` — soft-deleted flexible routines with empty days are backfilled too.

*Rationale:* a soft-deleted routine can be restored by import/export or a future undo feature, and
there's no reason its schedule should look different from an active routine's just because it's
currently hidden. Scoping the `UPDATE` to `deleted_at IS NULL` would create exactly the kind of
"only sometimes correct" data the Invariants section of `CLAUDE.md` warns about, for no benefit.

## Risks / Trade-offs

**This assumes "all seven days" is the right backfill for every existing flexible routine, with no
way to tell which ones the user actually meant to run less often.** → True, and it's the explicit
product decision recorded in the task: nothing disappears from Today, and existing flexible
routines keep behaving as they do now. There's no way to recover "meant to run less often" from an
empty list — that information was never captured. A user who wants a flexible routine on fewer days
can edit it after the upgrade with the new form, once it ships.

**Running before the Today-filter change means the backfill is invisible until that change lands;
running after means a brief window where flexible routines have already stopped showing up.** →
This change doesn't control landing order — it only makes the eventual state correct whenever the
filter arrives. Because the migration is idempotent (`WHERE schedule_days = ''` only matches rows
that still need it) and runs once per device on next open, landing order between the three changes
doesn't change the outcome on a real device, only how long the gap is before Today reflects it.

## Migration Plan

This *is* the migration. `schemaVersion` moves from 7 to 8; the `onUpgrade` branch runs once per
device, the first time the app opens after the update, and is idempotent — a device already at v8
never re-runs it, and a device with no matching rows leaves the `UPDATE` a no-op.
