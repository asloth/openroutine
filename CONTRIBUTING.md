# Contributing to OpenRoutine

Thanks for your interest in OpenRoutine. This is an early-stage, part-time open-source project — please be patient with response times.

## Dev setup

- Flutter **3.41.4** (stable channel). Other versions may work but CI is pinned to this one.
- From `app/`:
  ```
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  ```
- CI (`.github/workflows/flutter-ci.yml`) runs `analyze` and `test` on every pull request. Please make sure both pass locally before opening a PR.

## Project rules (non-negotiable)

These come from [`docs/SPEC.md`](docs/SPEC.md) §13 and apply to every contribution:

- **No required backend.** Every feature must work with either the Google Drive adapter or the Local-only adapter alone.
- **Keep the storage adapter interface pure.** No Drive-specific types may leak into `models/` or `screens/`. Adding a new adapter (iCloud, etc.) must never require touching the UI.
- **Validate, don't crash.** All JSON reads are validated against `schemas/*.json`. On a mismatch, log and degrade gracefully — never crash, and never write a file that violates its schema.
- **Never call it "sign in."** Google Drive connection is framed as "Connect Google Drive" / "Connected" in all UI copy, never "Sign in with Google." See §15.3 for why this matters for App Store review.
- **Every user-facing string goes through i18n.** No hardcoded English in `screens/` or `widgets/`. Add keys to `app/lib/l10n/app_en.arb` and `app_es.arb` together.
- **Schema changes are API changes.** Any change to the shape of a Routine, Step, Trigger, or CompletionLog requires a version bump in the relevant `schemas/*.json` file **and** a PR that updates it in the same change. The schemas are the public contract for agent integrations — treat them like a public API, because they are one.
- **This repo is public.** Never commit API keys, OAuth client secrets, signing keys, `.env` files, or personal identifiers. Use `.gitignore` and GitHub Actions secrets. Write commit messages as if a stranger will read them, because they will.

## Commit messages

Short, imperative, present tense (`fix:`, `feat:`, `docs:`, `chore:` prefixes welcome but not required). Explain *why* in the body when it isn't obvious from the diff.

## Questions

Open a GitHub issue.
