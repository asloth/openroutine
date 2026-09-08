# Contributing to OpenRoutine

Thanks for your interest in OpenRoutine. This is an early-stage, part-time open-source project — please be patient with response times.

## Dev setup

- Use Flutter **3.41.4** (stable channel). Other versions might work, but CI is pinned to this one.
- Run these from `app/`:
  ```
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  ```
- CI (`.github/workflows/flutter-ci.yml`) runs `analyze` and `test` on every pull request. Make sure both pass locally before you open a PR.

### Running the app

Google Drive support compiles in OAuth client IDs that are **not** in this repo
(see [`docs/SPEC.md`](docs/SPEC.md) §13). Copy
`app/dart_define.example.json` to `app/dart_define.json`, fill in your own
IDs, and pass the file on every run and build:

```
flutter run   --dart-define-from-file=dart_define.json
flutter build apk --debug --dart-define-from-file=dart_define.json
```

Without the flag, `DriveConfig.isConfigured` is false, and the app runs
Local-only, with every Drive control disabled and labeled "Coming soon".
That's correct behavior for a fresh clone with no IDs — but it looks exactly
like a broken Drive integration if you forgot the flag, so check that first.

## Project rules (non-negotiable)

These come from [`docs/SPEC.md`](docs/SPEC.md) §13 and apply to every contribution:

- **No required backend.** Every feature must work with either the Google Drive adapter or the Local-only adapter alone.
- **Keep the storage adapter interface pure.** Don't let Drive-specific types leak into `models/` or `screens/`. Adding a new adapter (iCloud, etc.) must never require touching the UI.
- **Validate, don't crash.** Validate all JSON reads against `schemas/*.json`. On a mismatch, log the problem and degrade gracefully — never crash, and never write a file that violates its schema.
- **Never call it "sign in."** Frame Google Drive connection as "Connect Google Drive" / "Connected" in all UI copy — never "Sign in with Google." See §15.3 for why this matters for App Store review.
- **Every user-facing string goes through i18n.** No hardcoded English in `screens/` or `widgets/`. Add keys to `app/lib/l10n/app_en.arb` and `app_es.arb` together.
- **Schema changes are API changes.** If you change the shape of a Routine, Step, Trigger, or CompletionLog, bump the version in the relevant `schemas/*.json` file and update it in the same PR. The schemas are the public contract for agent integrations — treat them like a public API, because they are one.
- **This repo is public.** Never commit API keys, OAuth client secrets, signing keys, `.env` files, or personal identifiers. Use `.gitignore` and GitHub Actions secrets. Write commit messages as if a stranger will read them, because they will.

## Commit messages

Keep commit messages short, imperative, and in the present tense (`fix:`, `feat:`, `docs:`, `chore:` prefixes are welcome but not required). Explain *why* in the body when it isn't obvious from the diff.

## Questions

Open a GitHub issue.
