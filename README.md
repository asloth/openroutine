<p align="center">
  <img src="docs/store/icon-512.png" alt="OpenRoutine app icon" width="96">
</p>

# OpenRoutine

> Your routines. Your data. Your agent.

OpenRoutine helps you start a routine and stay with it, one step at a time. Build a routine from
small timed steps, and a visual timer walks you through them. It's a free, open-source Flutter app
for Android and iOS, with no account and no OpenRoutine server. Your routines stay on your phone
and, if you choose, sync as plain JSON files to your own Google Drive.

[Website](https://openroutine.sara.coffee) · [Privacy policy](docs/privacy-policy.md) ·
[Product spec](docs/SPEC.md) · [Guide for AI agents](docs/for-agents.md) ·
[Contributing](CONTRIBUTING.md)

## What you can do

- **Follow a routine with Timer Mode.** A visual countdown runs for the current step, with pause
  and skip, and a gentle notification tells you when a step's time is up.
- **Build routines fast.** Add steps with emojis and durations, set optional days and start times,
  or start from ready-made step templates for morning, evening, study, and self-care.
- **Use Low Mode on harder days.** Mark the steps that matter most, then run only those. Finishing
  a Low Mode routine still counts.
- **Track streaks and history.** The Streaks tab shows your progress by week, month, or all time.
- **Start from your home screen.** On Android, a home screen widget starts a routine in one tap.

The app runs in English and Spanish, with light, dark, and system themes and a choice of accent
colors. Ochi, a small mascot, cheers you on along the way.

## Your data stays yours

- **Works offline.** Routines live in a local database on your phone. Google Drive is optional.
- **Narrow Drive access.** Drive sync uses the `drive.file` scope, so the app sees only the
  `OpenRoutine` folder it creates. You can revoke access at any time.
- **Open format.** Routines are plain JSON files that follow the public schemas in
  [`schemas/`](schemas/). You can read them, copy them, or share them through import and export.
- **No ads, analytics, or tracking.** The only network traffic is to Google's Drive API, and only
  after you connect Drive. See the [privacy policy](docs/privacy-policy.md).
- **MIT licensed.** There's no Pro tier and no feature gating.

## Get the app

Version 1.0.0 is in this repository. There's no store link here yet, so for now you build it from
source. Follow [Run the app](#run-the-app) below.

## Work with an AI agent

OpenRoutine has no API of its own. The integration surface is the published JSON schema plus your
own Google Drive. If you connect Drive in OpenRoutine and give an AI agent access to the same Drive
account, try a prompt like one of these.

**Review adherence without editing:**

> Read `OpenRoutine/routines.json` and `OpenRoutine/completions/` in my Drive.
> Summarize which routine steps I skip most often and which regularly overrun.
> Do not change any files.

**Propose a smaller routine:**

> Read my evening routine and its completion history in the `OpenRoutine`
> folder. Propose a version I can finish in 20 minutes. Show the exact changes
> first, but do not write them until I confirm.

<details>
<summary>More prompts: add a routine, apply a confirmed edit</summary>

**Add a routine safely:**

> Read `OpenRoutine/README.md`, `OpenRoutine/routines.json`, and the OpenRoutine
> agent guide. Design a study routine for deep work and Spanish practice. After
> I approve it, add schema-valid routine and step records with UUIDv7 IDs, keep
> `step_ids` and `order` consistent, and use current UTC timestamps.

**Apply a confirmed edit:**

> Rename the routine with ID `<routine-id>` to "Short evening reset". Preserve
> every other field and unknown field, bump only that routine's `updated_at` to
> the current UTC time, validate the full document, and write it back.

</details>

The [agent guide](docs/for-agents.md) covers the schemas, valid enums, merge rules, tombstones,
timestamp requirements, and safe-edit examples. OpenRoutine itself never talks to an AI service.

## Develop the app

The Flutter app lives in [`app/`](app/). It needs Flutter **3.41.4**, the version pinned in
`app/.fvmrc` and used by CI. Run these commands from `app/`:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Generated files (`*.freezed.dart`, `*.g.dart`, and the localization classes) aren't committed, so
run code generation before you analyze a fresh clone. CI runs `analyze` and `test` on every pull
request through [`.github/workflows/flutter-ci.yml`](.github/workflows/flutter-ci.yml).

### Run the app

Google Drive support needs OAuth client IDs that aren't in this repository. To run with Drive,
copy `app/dart_define.example.json` to `app/dart_define.json`, fill in your own client IDs, and
pass the file on every run and build:

```bash
flutter run --dart-define-from-file=dart_define.json
flutter build apk --debug --dart-define-from-file=dart_define.json
```

Without the flag, the app runs in Local-only mode, and every Drive control shows as unavailable.
That's expected for a fresh clone. If Drive looks broken, check the flag first.

Before you open a pull request, read [`CONTRIBUTING.md`](CONTRIBUTING.md). It lists the project
rules, such as keeping both ARB files in step and treating `schemas/` as a public API. Features go
through [OpenSpec](openspec/) change proposals.

## Develop the website

The public website is a small Jekyll site in [`site/`](site/): a home page plus the privacy
policy, which the build copies in from [`docs/privacy-policy.md`](docs/privacy-policy.md) so the
repository keeps one copy.

It's published two ways:

- **GitHub Pages**, at <https://asloth.github.io/openroutine/>, through
  [`.github/workflows/pages.yml`](.github/workflows/pages.yml) on every push to `main` that
  touches the site or the privacy policy.
- **A container**, at <https://openroutine.sara.coffee>, built from
  [`site/Dockerfile`](site/Dockerfile).

To preview the container build, run this from the repository root, then open
<http://localhost:8080>:

```bash
docker build -f site/Dockerfile -t openroutine-site .
docker run --rm -p 8080:80 openroutine-site
```

## Repository layout

```
openroutine/
├── app/        # Flutter app (Android and iOS)
├── docs/       # Spec, architecture, agent guide, privacy policy, store and publishing notes
├── openspec/   # Change proposals and delivery process
├── rive/       # Source for the Ochi mascot animations
├── schemas/    # JSON Schema: the public data contract
└── site/       # Public website (Jekyll)
```

## More documentation

- [`docs/SPEC.md`](docs/SPEC.md): the full product and technical spec
- [`docs/architecture.md`](docs/architecture.md): a short architecture overview
- [`docs/for-agents.md`](docs/for-agents.md): how agents read and edit routine files safely
- [`docs/store-listing.md`](docs/store-listing.md): Play listing text, Data safety answers, and
  permissions
- [`docs/publishing.md`](docs/publishing.md): signing and the Play release checklist
- [`DESIGN.md`](DESIGN.md): the visual design system

## License

MIT. See [`LICENSE`](LICENSE).
