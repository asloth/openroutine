# Working on OpenRoutine

OpenRoutine is a local-first Flutter routine app for iOS and Android. There's no backend. Routines
live as plain JSON in the user's own Google Drive, or fully offline on the device.

Read `CONTRIBUTING.md` for the rules that govern contributions, `docs/SPEC.md` for the product
spec, and `openspec/config.yaml` for the delivery process. This file covers what those don't: the
traps that cost time if you don't know about them.

## Toolchain

**`fvm` isn't on your PATH.** The binary lives at `/home/sabera/fvm/bin/fvm`. The global Flutter at
`~/flutter` is 3.24.5 and *can't build this project*. Check `app/.fvmrc` for the pinned version.

Run everything from `app/`:

```bash
/home/sabera/fvm/bin/fvm flutter pub get
/home/sabera/fvm/bin/fvm flutter gen-l10n
/home/sabera/fvm/bin/fvm dart run build_runner build --delete-conflicting-outputs
/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos
/home/sabera/fvm/bin/fvm flutter test
```

**Run code generation before you analyze.** Generated files (`*.freezed.dart`, `*.g.dart`,
`lib/l10n/app_localizations*.dart`) are gitignored, so a fresh clone or worktree has none of them.
Analyze reports roughly 918 errors until `build_runner` runs. Those errors aren't yours.

Regenerate after you change any annotated model, provider, Drift table, or ARB file.

## Don't run `dart format .`

The pinned formatter rewrites about 15 files, most of them unrelated to your change. Worse,
reformatting `app/lib/services/storage/drive/drive_auth.dart` introduces a *new*
`--fatal-infos` failure (`curly_braces_in_flow_control_structures`), which breaks CI.

Format only what you touched:

```bash
/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')
```

## Tests come first

`openspec/config.yaml` sets `strict_tdd: true`. For any behavioral change, write a failing test,
watch it fail, then implement. This is project policy, not a preference.

Test layers that exist: unit (`app/test/services`, `app/test/state`) and widget
(`app/test/screens`). There's no integration or end-to-end setup.

## Invariants that break things quietly

**The two schema copies must stay byte-identical.** `schemas/*.json` at the repo root is the public
contract. `app/assets/schemas/*.json` is the bundled copy. Edit both.
`app/test/services/import_export/schema_validator_test.dart` enforces it.

**`schemas/` is a public API.** Treat any change there as a breaking-change decision, and say so
explicitly in your OpenSpec proposal. Add new fields with a `default`, and leave them out of
`required`, so older files stay valid. `is_core` and `remind_during` are the precedents.

**Bumping `SchemaVersion` breaks test fixtures you didn't touch.** `SchemaVersion.currentValue`
gets written into Drive's `meta.json`, so version literals in `drive_sync_test.dart`,
`local_adapter_test.dart`, and `import_screen_test.dart` all need review. Fixtures that mean
"newer than us" have to move up too.

**Both ARB files move together.** Add every user-facing string to `app/lib/l10n/app_en.arb` *and*
`app_es.arb`. `CONTRIBUTING.md` makes this non-negotiable. No hardcoded English in `screens/` or
`widgets/`.

**Android notification channels are immutable.** Once a channel exists on a device, the OS ignores
changes to its sound, vibration, or importance. To change any of those, create a new channel id.
See the `_v1` suffixes in `app/lib/services/notifications/notification_service.dart`.

**Bump `schemaVersion` and add an `onUpgrade` branch for every Drift schema change.** Installs
carry real user routines, so dropping and recreating the database isn't an option.

## Testing on the device

There's a physical Pixel 9a on USB (`53061JEBF10200`) and no emulator. It's the only Android
target.

```bash
/home/sabera/fvm/bin/fvm flutter build apk --debug --dart-define-from-file=dart_define.json
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Never build for the phone without `--dart-define-from-file=dart_define.json`.** The Google Drive
OAuth client IDs come in through that file. Leave it off and the build still succeeds, still
installs, and still runs — with `DriveConfig.isConfigured` false, so Drive shows up as unavailable
and the app is Local-only. Nothing in the build output says so. This flag belongs on `flutter run`
too.

**Use `adb install -r`, not `flutter install`.** `flutter install` uninstalls the old app first,
which wipes the local database and sends the app back to onboarding. It has already cost this
project a set of routines.

Check your work without touching the phone:

```bash
adb shell monkey -p app.openroutine.mobile -c android.intent.category.LAUNCHER 1
adb logcat -d -t 200 | grep -iE 'FATAL|AndroidRuntime'
adb exec-out screencap -p > screen.png
```

## Delivery

Features go through OpenSpec. Create `openspec/changes/<name>/` with `proposal.md`, `design.md`,
`tasks.md`, `specs/<capability>/spec.md`, and `.openspec.yaml`. Read
`openspec/changes/fix-appearance-defaults/` for the format.

Keep each review slice within 400 lines, or chain the delivery across slices. Landing the storage
foundation separately from the UI is an established pattern here — see commit `5ef5b2a`.

## Writing style

Write everything in the [Microsoft Writing Style
Guide](https://learn.microsoft.com/style-guide/welcome/) voice. This covers docs, commit messages,
PR descriptions, and code comments.

- Warm and relaxed, crisp and clear, ready to lend a hand
- Write like you talk. Use contractions
- Second person, active voice, present tense. Imperative for steps
- Bigger ideas, fewer words
- Sentence-style capitalization for headings, never Title Case
- Never write "simply", "just", "easy", or "obviously"
- Say "select", not "click"
- Serial comma, always

Report results honestly. When tests fail, say so and show the output. A friendly tone never means a
cheerful one.

## Changing the UI

Restyle in place. Don't move or regroup controls that weren't part of the request, and don't treat
a mockup's layout as a request to match it.
