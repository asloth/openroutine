## Why

There's no way for someone using OpenRoutine to tell you what's wrong or what they'd like. The app has no backend and promises that nothing leaves the device, so feedback can't be collected in the background, and a third-party feedback SDK would break that promise.

## What Changes

- Add a **Send feedback** row to Settings › About. It opens the person's own email app with a message addressed to the project's feedback inbox, a subject, room to write, and a short block of details (app version and build, operating system, app language) they can read, edit, or delete before sending.
- If the phone has no email app, show the address with a **Copy** action instead of failing silently.

## Capabilities

### New Capabilities

- `send-feedback`: how someone sends feedback from the app without the app sending anything itself.

## Impact

**Code.** A new `app/lib/services/feedback/feedback_email.dart` that builds the `mailto:` link, a launcher provider so tests can stand in for the platform, and one row in `settings_screen.dart`. Unit and widget tests.

**Dependencies.** None. `url_launcher` and `package_info_plus` are already in use.

**Storage and schema.** None. No file under `schemas/` changes.

**Privacy.** Nothing is sent by the app. The details block is plain text in the draft, visible and editable before the person chooses to send it.

**i18n.** New strings in `app_en.arb` and `app_es.arb`.

**Rollback.** Remove the row. Nothing is persisted.
