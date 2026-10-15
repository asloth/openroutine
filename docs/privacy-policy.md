# OpenRoutine privacy policy

**Effective date:** 2026-10-09

OpenRoutine is a free, open-source routine and visual-timer app for Android and iOS. It's built so your routines stay yours. This page explains what the app does with your data, in plain language.

The short version: we don't collect anything. There's no OpenRoutine server, no account, no analytics, no ads, and no crash reporting. Your routines live on your phone and, if you choose, in your own Google Drive.

## Who we are

OpenRoutine is an open-source project (MIT license) maintained by Sara Benel. The source code is public at [github.com/asloth/openroutine](https://github.com/asloth/openroutine), so you can check everything on this page for yourself.

## What we collect

Nothing. The developer doesn't receive, store, or have access to your routines, completion history, settings, or any information about you or your device. The app doesn't contain analytics, advertising, tracking, or crash-reporting tools, and it doesn't ask you to create an account.

## What the app stores on your device

OpenRoutine keeps this information in the app's private storage on your phone:

- **Your routines and steps:** names, emojis, durations, schedules (days and start times), reminder choices, and which steps are marked essential for Low Mode.
- **Your history:** a record of the routines and steps you've completed, which the app uses for your streaks and statistics.
- **Your settings:** language, theme, accent color, reminder lead time, sound on or off, and whether you've finished onboarding.
- **A random install ID:** a generated identifier that the app writes into your sync files so it can tell your devices apart. It isn't linked to you, and it's never sent to us.
- **Home screen widget data:** if you add the Android widget, the app shares a copy of your routine list (names, start times, step counts) and your colors with the widget, inside your phone.

This information stays on your phone unless you choose to connect Google Drive or share an export. Android's own backup may include app data, depending on your phone's settings. That's controlled by your phone and Google, not by OpenRoutine.

## Google Drive (optional)

Connecting Google Drive is optional. Every feature works without it.

If you select **Connect Google Drive**, OpenRoutine asks Google for permission to use your Drive. After that, the app creates a folder named **OpenRoutine** in your Drive and keeps these files in it:

- `routines.json`, with your routines and steps.
- `completions/`, with your completion history in monthly files.
- `meta.json`, with the data format version, the install ID, and the last sync time.
- `README.md`, a short note that explains the files to you or to any AI agent you choose to point at them.

The app talks directly from your phone to Google's Drive servers over HTTPS. Nothing passes through a server we run.

### What the `drive.file` permission means

OpenRoutine requests only one Google permission: `https://www.googleapis.com/auth/drive.file`. It's Google's narrowest Drive permission. It lets the app see and change only the files and folders the app itself created. It can't see, list, read, or change any other file in your Drive, such as your documents or photos.

The app doesn't read your Google profile, contacts, calendar, or any other Google service. It uses the permission only to sync your routines between your devices and keep a backup you control.

### Your Drive, your files

The files in your OpenRoutine folder are yours. You can open them, copy them, edit them, or delete them. If you give an AI agent access to your Drive, it can read those files too. That's your decision, and it's governed by that agent's own privacy policy. OpenRoutine doesn't connect to any AI service.

Google's handling of your Drive data is covered by the [Google Privacy Policy](https://policies.google.com/privacy). OpenRoutine's use of information received from Google APIs adheres to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements.

### Disconnecting

You can select **Disconnect Google Drive** in Settings at any time. You can also revoke OpenRoutine's access from your [Google Account permissions page](https://myaccount.google.com/permissions). Either way, the app stops syncing. Your Drive files stay where they are until you delete them.

## Notifications and alarms

OpenRoutine asks for notification permission when you first start a timer, not when you open the app. It uses notifications to tell you when a step's time is up and, if you set days and a start time, to remind you before a routine begins.

All notifications are scheduled on your phone. There are no push notifications from a server. On Android, the app re-schedules pending notifications after your phone restarts.

You can turn notifications off in your phone's system settings. The timer keeps working on screen.

## Sounds and vibration

The app plays short sounds when you finish a step or a routine (you can turn this off in Settings), and it can play a sound or vibrate with a notification. These sounds are bundled in the app. The app doesn't use your microphone or camera.

## Sharing and exporting

If you export a routine or all of your data, the app hands a JSON file to your phone's share sheet, and you pick where it goes. If you import a file, you pick it from your phone. The app doesn't send or receive anything on its own.

## Sending feedback

If you select **Send feedback** in Settings, the app opens a draft in your own email app, addressed to openroutine@sara.coffee. The draft includes the app version, your phone's operating system and version, and the app's language, so we can reproduce problems. You see all of it before you send, and you can edit or delete any of it.

Nothing is sent unless you send the email yourself. It travels through your email provider, like any other email. We use what you write only to reply and to improve OpenRoutine, and we don't add it to any mailing list. To have your emails deleted, write to the same address.

## What we don't do

- We don't sell, rent, or share your data. We don't have it.
- We don't track you across apps or websites.
- We don't show ads.
- We don't use your data to train AI models.
- We don't ask for your location, contacts, photos, or microphone.

## Deleting your data

You're in control of all of it:

- **On your phone:** delete a routine or step in the app, or uninstall the app (or clear its storage in your phone's settings) to remove everything stored locally. The app first marks a deleted routine as deleted, rather than erasing it right away, so your devices stay in sync. Uninstalling the app removes it for good.
- **In Google Drive:** delete the **OpenRoutine** folder in your Drive. If you disconnect first, no further changes are synced.
- **From us:** there's nothing to delete, because we don't hold any of your data.

## Children

OpenRoutine doesn't knowingly collect personal information from anyone, including children. Because the app doesn't collect data and has no accounts, it's suitable for all ages. Connecting Google Drive requires a Google Account, and Google sets its own age requirements for those. If you're a parent or guardian and you have questions, reach out using the contact below.

## Changes to this policy

If the app's data practices change, we'll update this page and the effective date before the change ships. Because the project is open source, every change to this page is public in the [repository history](https://github.com/asloth/openroutine/commits/main/docs/privacy-policy.md).

## Contact

Questions, privacy requests, or concerns? Write to [openroutine@sara.coffee](mailto:openroutine@sara.coffee), or open an issue at [github.com/asloth/openroutine/issues](https://github.com/asloth/openroutine/issues).
