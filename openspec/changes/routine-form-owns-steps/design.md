## Context

See `proposal.md` for the why. Slice 1 restyled the form and left the old chain in place: `RoutineFormScreen._save` writes an empty routine, then `pushReplacement`s to Routine Detail and `push`es the step form on top. This design covers slice 2.

What's already there:

- `StepFormScreen` writes straight to storage. In add mode it reads `routineStepsProvider` to compute `order`.
- `StorageAdapter` saves one record per call. `LocalAdapter.reorderSteps` already runs in a Drift transaction, and `DriveAdapter` wraps every write in `_mutate`, which marks the whole routines tree dirty. So one mutation that touches several records is safe for sync.
- `routineEstimate()` in `services/routines/estimate.dart` sums the explicit durations, and Routine Detail rounds them up to whole minutes.
- `routineFormSaveWith` (`{save} · {summary}`) is already in both ARB files but isn't used yet.

## Goals / Non-Goals

**Goals:**

- Nothing reaches storage until Save, and Save writes the routine and its steps together.
- A routine can't exist without at least one step.
- Adding, editing, reordering, and removing steps all happen on the form, for new and existing routines alike.

**Non-Goals:**

- Removing step management from Routine Detail. There are two doors for now, as the proposal says.
- Changing the step form's own fields, templates, or look.
- Fixing existing routines that already have no steps. They still open and can be edited. They can't be saved again until they have a step.

## Decisions

### One storage call writes the routine and its steps

Add `saveRoutineWithSteps(Routine routine, List<RoutineStep> steps, {Set<String> removedStepIds = const {}})` to `StorageAdapter`. `LocalAdapter` runs it in one Drift transaction: upsert the routine, upsert each step, and soft-delete each removed id. `DriveAdapter` wraps it in a single `_mutate`.

*Alternative considered:* calling `saveRoutine`, then `saveStep` in a loop from the form. That was rejected. A failure halfway through leaves the half-built routine this change exists to prevent, and on Drive it's N sync nudges instead of one.

### The form keeps a draft list and assigns the routine id up front

A new routine gets its `newId()` in `initState`, so draft steps carry the right `routineId` from the start. An existing routine loads its stored steps into the draft once, alongside its other fields.

On Save, the form sets each step's `order` to its index. It passes only the steps that actually changed, and each one gets a fresh `updatedAt`. "Changed" means new, edited, or moved. Removed stored steps go in `removedStepIds`.

*Rationale:* bumping `updatedAt` on unchanged steps would make them win last-writer-wins merges they have no business winning (`docs/SPEC.md` §5).

### The step form gains a draft mode that returns a step

`StepFormScreen` takes an optional `draft` flag and an optional `initial` step. In draft mode it never touches storage. Save pops the built `RoutineStep`, and Delete pops a removal result. It opens through a new `/routines/:routineId/steps/draft` route, with the initial step passed as `extra`. That keeps the app's page transitions. A raw `MaterialPageRoute` wouldn't.

In draft mode, the add case skips `routineStepsProvider`, because the form owns `order`. Templates still show when you add a step.

### The steps list reuses Routine Detail's row

The form shows the draft in a `ReorderableListView` built from the same `_StepRow` Routine Detail uses. That row moves to a shared widget. Selecting a row opens it in draft mode. An inline **Add step** row sits under the list.

### Save reads "Save · N steps, M min" and waits for a step

With no steps, the button reads **Save** and is disabled, and the empty list shows a one-line hint. With steps, the button uses `routineFormSaveWith` and a new plural string, `routineFormStepsSummary`. When every step is untimed, it drops the minutes: **Save · 2 steps**. Minutes round up, the same way Routine Detail does.

### After Save, the form closes

The chain goes away. A new routine pops back to wherever you started, which is usually Today or Routines, and the new routine shows up there.

*Alternative considered:* replacing the form with the new routine's detail. That was rejected because you've already seen every step on the form, and Detail would show the same steps back to you.

## Delivery

Each part fits under 400 lines. The storage lands first, apart from the UI, following the pattern in `5ef5b2a`:

1. **2a, storage:** `saveRoutineWithSteps` on both adapters, with unit tests for the transaction, soft deletes, and a failure that rolls everything back.
2. **2b, step form draft mode:** the route, returning a step instead of writing it, and widget tests.
3. **2c, the form:** the draft list, Add, reorder, and remove, the one-step rule, the label, the diff on Save, and dropping the chain.

## Risks / Trade-offs

**Backing out now throws away more work.** Before, the routine was on disk after the first Save. Now five typed steps disappear with one swipe back. → See the open question below.

**Two doors to the same steps.** Routine Detail still edits steps directly. If the form is open for a routine while Detail changes it, the form's Save wins. That can't happen today, because both screens can't be open on the same routine at once, but it's worth knowing before either screen changes.

## Open questions

- **Confirm before discarding a draft?** A `PopScope` that asks "Discard this routine?" when the draft has unsaved changes. It's cheap, and it needs two new strings in both ARB files. It's recommended, but it isn't in the proposal.
