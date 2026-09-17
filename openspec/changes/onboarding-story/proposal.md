## Why

Onboarding still shows the M2 feature slides: an icon, a title about Drive, one about the timer, one about agents, and a storage-choice page. None of it explains how a routine works, so people land on an empty home without knowing what a scheduled or a flexible routine is, or that it's fine to skip a step.

The redesign's onboarding opens with "Routines that stick, without the setup." This change turns onboarding into a short story, carried by the Rive mascot, that teaches the routine model and ends in the routine builder.

## What Changes

- Replace the three slides and the storage-choice page with five beats: hello, scheduled routines, flexible routines, going step by step with skipping, and making your first routine.
- Show a five-segment progress bar and keep Skip on every beat.
- Give the mascot a move for each beat: it wakes up and waves, runs in and jumps when the reminder rings, bounces, cheers a done step and nods at a skipped one, and celebrates at the end.
- Add three moves to the Rive file (`run`, `jump`, and `bounce`), behind new view model triggers, and expose them, plus `celebrate`, as `MascotReaction`s.
- End by opening the routine builder with Scheduled or Flexible already selected.
- Drop the storage-choice page. Everyone starts Local-only and can connect Drive from Settings.

## Capabilities

### New Capabilities

- `onboarding` — the beats onboarding shows, what the mascot does on each, and where it hands off.

## Impact

**Code.** `app/lib/screens/onboarding/`, `app/lib/widgets/mascot_slot.dart`, `app/lib/screens/routine_form/routine_form_screen.dart` (a starting mode), the `/routines/new` route, `app/assets/mascot.riv`, and their tests.

**Storage and schema.** None. The storage mode still defaults to Local-only.

**i18n.** New onboarding strings in both `app_en.arb` and `app_es.arb`. The old slide and storage-choice strings go away.

**Rollback.** Reverting restores the old slides. Nothing is persisted differently.
