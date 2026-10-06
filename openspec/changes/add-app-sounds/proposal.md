## Why

Finishing a step or a routine is silent, and the mid-step nudge uses the phone's default tone. Ochi already says hello when a routine is due. These sounds give the rest of a run the same voice.

## What Changes

- Finishing a step (and moving to the next one) plays a short pop.
- Finishing a routine plays Ochi's wheee followed by a boing, together with the confetti.
- Skipping a step or stopping early plays nothing.
- The mid-step nudges (halfway and near the end) play Ochi's bip bip boo on a new Android channel, `step_progress_nudge_v2`. The old `v1` channel is deleted on startup.
- Settings gets a **Sounds** switch, on by default. It covers the in-app sounds only. Notification sounds follow the phone's notification settings.

## Capabilities

### New Capabilities

- `app-sounds` — when the app plays its own sounds, and how you turn them off.

## Impact

**Code.** New `services/sounds/app_sounds.dart` and `state/sound_provider.dart`. `RoutineTimer` plays the sounds. `NotificationService` moves the nudge to a v2 channel. Settings gets a switch.

**Dependencies.** Adds `audioplayers`.

**Storage and schema.** One new local preference, `sounds_enabled`. Nothing under `schemas/` changes.

**i18n.** `settingsSounds` and `settingsSoundsSubtitle` in both ARB files.

**Platforms.** iOS plays the in-app sounds. Its nudge notification keeps the default tone until the `.caf` files are added to the Xcode project, the same as the hello reminder.
