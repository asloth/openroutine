## Context

See `proposal.md`. The sound comes from `~/Documents/openroutine-sounds/make_sounds.py`, which
synthesizes the drafts. The resource is its `ochi_hello.wav`, re-encoded to Ogg Vorbis at `-q:a 5`
(7 KB).

## Decisions

### A new channel id, and delete the old one

Android ignores a changed sound on an existing channel, so the id moves to `_v2`, following the
pattern in `notification_service.dart`. `retiredChannelIds` lists ids to delete in `init()`.
Deleting a channel that doesn't exist is a no-op, so fresh installs are fine.

### Ogg in `res/raw`

Android plays Ogg natively, and it's the smallest format. `RawResourceAndroidNotificationSound`
names it without its extension.

## Non-Goals

- iOS sound (see `proposal.md`).
- The step nudge, step boundary, and in-app sounds. The boundary stays silent on purpose.
