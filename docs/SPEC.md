# OpenRoutine — Product & Technical Spec (v1)

> **Status:** Draft v2 · **Owner:** @asloth · **License:** MIT · **Last updated:** 2026-07-29
>
> *Your routines. Your data. Your agent.*

An open-source, local-first routine app. Your routines live in your Google Drive as plain JSON files you can see, edit, and share. Any AI agent with Drive access — Claude, Codex, or others — can help you manage them.

**No backend. No server to install. No account required.**

---

## 1. Vision & principles

1. **Local-first, user-owned storage.** The app is a client. Routines live in the user's own Drive folder as plain JSON files. No server operated by us ever holds user data.
2. **Zero-cost to run.** No backend to host, scale, or pay for. Sustainable as a solo/OSS project.
3. **Agent-friendly via open schema.** The data format is documented and stable. Any agent that can read a JSON file (Claude with Drive connector, Codex, ChatGPT with file upload, custom scripts) can help manage routines. No custom server, no lock-in.
4. **Open source.** MIT license. No feature gating, no "Pro" tier.
5. **Privacy by design.** Minimal OAuth scope (`drive.file` — app only sees files it created). Users can revoke access anytime. Files live in a visible folder they control.

---

## 2. Scope (v1)

### In scope
- Flutter mobile app (iOS + Android) with core CRUD for routines, steps, triggers, day scheduling
- Timer Mode (playlist-style guided execution)
- Google Drive storage adapter — files stored in a visible `/OpenRoutine/` folder in the user's Drive
- Local-only storage adapter (fallback / offline / opt-out of cloud)
- **Import / Export** — share routine JSON via OS share sheet, import from file
- Published, versioned JSON schema for agent integration
- Completion logging (append-only)
- English + Spanish localization from day 1
- App Store + Play Store submission

### Out of scope for v1 (deferred to v1.5+)
- Custom MCP server for advanced users (optional plugin, v2)
- QR-code routine transfer between phone and PC
- Insights dashboard beyond raw completion history
- Voice reminders, in-app AI, streaks
- iCloud / Dropbox / OneDrive adapters (interface will be ready, implementations later)
- Multi-user or team routines
- Server-side push notifications (local notifications only)

---

## 3. Architecture overview

```
┌────────────────────┐        ┌────────────────────────────┐
│  Flutter app       │◄──────►│  User's Google Drive       │
│  (iOS + Android)   │        │  /OpenRoutine/             │
└────────────────────┘        │    routines.json           │
                              │    meta.json               │
                              │    completions/*.ndjson    │
                              └─────────────▲──────────────┘
                                            │
                                            │ (user's own Drive connector)
                                            │
                              ┌─────────────┴──────────────┐
                              │  Claude / Codex / any      │
                              │  agent with Drive access   │
                              └────────────────────────────┘
```

**Key insight:** There is no custom server. The agent talks to the user's own Google Drive using the user's own Drive connector. OpenRoutine documents the file format publicly, and that IS the agent API.

For local-only users, import/export via the OS share sheet plays the same role.

---

## 4. Data model

All IDs are UUIDv7 (time-sortable). All timestamps are ISO-8601 UTC. Full JSON schemas live in `schemas/` and are the source of truth.

### Routine
```json
{
  "id": "uuid",
  "name": "Morning Routine",
  "trigger_id": "uuid | null",
  "schedule": {
    "mode": "scheduled | flexible",
    "days": ["mon","tue","wed","thu","fri"],
    "start_time": "07:00"
  },
  "step_ids": ["uuid", "uuid", "..."],
  "created_at": "2026-07-29T12:00:00Z",
  "updated_at": "2026-07-29T12:00:00Z",
  "deleted_at": null
}
```

### Step
```json
{
  "id": "uuid",
  "routine_id": "uuid",
  "name": "Brush my teeth",
  "emoji": "🪥",
  "duration_seconds": 180,
  "order": 0,
  "no_explicit_time": false,
  "created_at": "...",
  "updated_at": "...",
  "deleted_at": null
}
```
Constraints: `name` ≤ 50 chars, `emoji` single grapheme, `duration_seconds` null iff `no_explicit_time = true`.

### Trigger
```json
{
  "id": "uuid",
  "name": "Waking up",
  "kind": "manual",
  "created_at": "...",
  "updated_at": "..."
}
```
`kind` is `"manual"` in v1. Enum reserved for `"time"`, `"location"`, `"calendar_event"` in v2.

### CompletionLog (append-only)
```json
{
  "id": "uuid",
  "routine_id": "uuid",
  "started_at": "...",
  "ended_at": "...",
  "outcome": "completed | abandoned",
  "steps": [
    { "step_id": "uuid", "state": "completed | skipped | overrun", "actual_duration_seconds": 210 }
  ]
}
```

### Schema versioning

`meta.json` contains a `schema_version` string (semver). Bumps follow standard semver rules: additive changes = minor, breaking changes = major. Clients on older schemas must read newer files gracefully (unknown fields ignored) and refuse to write.

---

## 5. Storage layout & sync

### File layout in user's Google Drive
```
My Drive/
  OpenRoutine/                    ← visible folder in the user's Drive
    meta.json                     # schema_version, last_writer_client_id, last_sync_at
    routines.json                 # { routines: [...], steps: [...], triggers: [...] }
    completions/
      2026-07.ndjson              # one CompletionLog per line
      2026-08.ndjson
    README.md                     # auto-written, explains the format to humans and agents
```

Splitting completions by month keeps the main file small and lets clients (and agents) lazy-load history. The auto-generated `README.md` inside the folder tells any human or agent that opens it what these files are and links to the schema repo.

### Sync strategy (v1)
- **Read:** on app open + on pull-to-refresh + before every write.
- **Write:** merge → upload full `routines.json`. Conflict resolution = last-writer-wins per routine using `updated_at`. Deletions are soft (`deleted_at`) so an offline client can't resurrect deleted data. Agent edits (which change `updated_at`) win over stale local edits — this is a feature.
- **Completions:** append-only, filename is deterministic (`YYYY-MM.ndjson`), so multiple writers can safely append. Reader dedupes by `id`.
- **Client ID:** each install writes a UUID to local storage; included in `meta.json.last_writer_client_id` for debugging.

Future (v1.5): CRDT-lite per-field merging if LWW proves painful.

### Local cache
- **Flutter:** SQLite via `drift` package. Source of truth for offline reads. Sync worker reconciles with Drive on foreground.

---

## 6. Auth

### Flutter (mobile)
- `google_sign_in` package (v7.1.0+ required — includes Privacy Manifest for App Store submission)
- Scope: `https://www.googleapis.com/auth/drive.file` — grants access **only to files this app creates or opens**. User's other Drive files are never visible to the app.
- Access token refreshed via package; refresh token stored in platform keystore (Keychain / Keystore)
- **UI framing** (critical for App Store review — see §14): Drive connection is presented as **"Connect Google Drive"**, never "Sign in with Google". The app never has a "primary account" concept; it is fully usable in Local-only mode.

Users grant OpenRoutine access to create the `/OpenRoutine/` folder and its contents. Nothing else in their Drive is touched.

---

## 7. Flutter app — screens & states

Use **Riverpod** for state, **go_router** for navigation, **drift** for local persistence, **freezed** for models.

| # | Screen | Notes |
|---|--------|-------|
| 1 | **Onboarding** | 3 slides + storage choice screen. Local-only is the default; Drive is opt-in. |
| 2 | **Routines list** | Tabs: Scheduled / Flexible. Sections by trigger. FAB for new routine. Overflow menu: Import, Settings. |
| 3 | **Routine detail / preview** | Estimated finish window, last 7-day dots, trigger, ordered steps, Start Timer button. Share button in header (exports single routine). |
| 4 | **Create/Edit routine** | Name, trigger picker, day toggles (Mon–Sun), scheduled/flexible switch, start time. |
| 5 | **Add step** | Custom step OR template picker (Morning / Evening / Study / Selfcare — hardcoded seed list in `assets/step_templates.json`). |
| 6 | **Edit step** | Name (≤50), duration presets (n-1, n, n+1) + "no explicit time" toggle, emoji picker (curated ~60-emoji set from `assets/emojis.json`, grouped by category), delete. |
| 7 | **Timer Mode** | Full-screen playlist runner. See §8. |
| 8 | **Import** | File picker → validate JSON → preview → confirm merge or replace. |
| 9 | **Settings** | Storage backend (Local / Google Drive), sync status, connect / disconnect Drive, language, "Export all", about, links to agent-integration docs. |

Design tokens: defined once in `app/lib/theme/`. **The design pass has happened** — the tokens come from the "FocusFlow Routine Timer" Stitch project, whose export carries a full Material 3 role set, so `theme/colors.dart` is a literal `ColorScheme` rather than an approximation from a seed. Primary `#0051c0`, secondary `#006c47`, surface `#f7f9fc`; Lexend for structure and actions, Inter for prose, both bundled as static weights (never fetched at runtime — see §1); radii 4/8/12/full; spacing 8/16/24/32 with a 48px minimum touch target. Neumorphic surfaces (paired light/dark shadows) are a `ThemeExtension` so they adapt to brightness.

The light scheme is the designed one. Dark is derived from the same primary and is approximate — the mockups are light-only, and neumorphism is a light-surface idiom.

Screens are styled from these tokens and their component themes; a screen that needs a local appearance override means a component theme is missing. Note the Stitch project also contains a bottom-nav shell, a "Today" home screen and a Weekly Insights view — **none of these are adopted**; the app keeps the screen set in the table above, and Insights remains out of scope for v1 per §2.

---

## 8. Timer Mode — state machine

```
       start                 tick                       last_step
IDLE ─────────► RUNNING ──────────► RUNNING ──── ... ──────────► COMPLETE
                 │  ▲                 │
        pause    │  │ resume          │ skip / complete_step
                 ▼  │                 ▼
               PAUSED               (advance to next step)
                 │
                 │ back
                 ▼
             (advance to previous step)
```

States: `idle`, `running`, `paused`, `complete`.
Events: `start`, `tick` (1s), `pause`, `resume`, `skip`, `complete_step`, `back`, `reset_step`, `abandon`.

Each event produces a new immutable state (a codegen Riverpod `Notifier` — `StateNotifier` is legacy as of Riverpod 3). On `complete_step` or `skip` we push a step outcome onto a pending `CompletionLog`. On `COMPLETE` or `abandon` we persist the log and append to `completions/YYYY-MM.ndjson`.

A timed step does **not** auto-advance when it reaches zero; it keeps counting into overrun until the user acts. That is what makes `overrun` a reachable `CompletionLog` step state.

### Surviving the background (revised in M3)

**Elapsed time is derived from wall-clock timestamps, never accumulated from ticks.** The state stores when the current step started and how long it has been paused; elapsed time is recomputed on every read. The 1-second `tick` exists only to trigger a repaint, so a tick that is delayed or never delivered — which is exactly what happens while the process is suspended — costs a frame of smoothness rather than correctness.

Local notifications: fire a local push when the app is backgrounded and a step timer expires (uses `flutter_local_notifications`). Each step's expiry is registered as an OS-scheduled exact alarm at the moment the step starts, and cancelled or rescheduled on pause/resume/skip.

This **replaces the foreground service** this section originally called for. Handing the alarm to the OS is strictly more robust — it fires whether or not our process survived, which a foreground service cannot promise — and it avoids declaring an Android 14+ `foregroundServiceType` of `specialUse`, which would need justifying at store review. Since the timer's state no longer depends on a live process either, there is nothing left for the service to keep alive. Exact alarms need `USE_EXACT_ALARM`, which Play permits for apps whose core function is a timer; see §15.14.

---

## 9. Agent integration model

**No custom server. The published schema + user's own Drive access = the agent API.**

### Two paths for users

**Path A — Continuous agent access (Drive users)**
1. User connects Drive in OpenRoutine → `/OpenRoutine/` folder created.
2. User connects their own Google Drive connector to Claude Desktop, Claude Code, claude.ai, or Codex (one-click, already built by Anthropic/OpenAI).
3. User points the agent at the folder or a specific file: "Read `OpenRoutine/routines.json` and analyze which steps I skip most."
4. Agent reads, reasons, and — with user confirmation — writes edits back.

Because sync is Drive-side, changes made by the agent are picked up by the phone on next open.

**Path B — One-off agent help (Local-only or ad-hoc)**
1. User taps "Share" on a routine → OS share sheet → sends JSON to Claude iOS app / email / Files.
2. Agent proposes edits as JSON.
3. User taps "Import" in OpenRoutine → file picker → merge.

### What we ship to enable this

- **`schemas/*.json`** in the repo — versioned JSON Schema for each entity. This is the public contract.
- **`docs/for-agents.md`** — a concise guide written *for AI agents* that explains: folder location, file naming, schema link, valid values (like `days` enum), sync semantics (LWW), and safe-edit patterns ("bump `updated_at` on any write").
- **In-folder `README.md`** — auto-generated on first sync, written into `/OpenRoutine/README.md`. When any human or agent opens the folder, they immediately see what these files are and how to safely edit them.
- **Example prompts** in the repo README ("Copy this into Claude Desktop"):
  - *"Read `OpenRoutine/routines.json` in my Drive. Which steps have I skipped most in the last 30 days based on `completions/`? Propose a shorter evening routine and write the changes back."*
  - *"Design me a study routine for deep work + Spanish practice. Add it to `OpenRoutine/routines.json`."*

### What we deliberately don't build in v1
- Custom MCP server. Deferred to v2 as an optional package for users who want built-in helper tools (`analyze_adherence`, `suggest_routine` prompts). 90%+ of users will never need it.
- QR-code / local-network sync between phone and PC. Deferred to v1.5. Same effect achievable via Drive today.

---

## 10. Import / Export

### Export
- **Single routine**: Share button on routine detail → produces `routine-<name>-<date>.json` containing that routine + its steps + any referenced trigger. OS share sheet.
- **All data**: Settings → "Export all" → produces `openroutine-export-<date>.json` with everything. Useful for backup and for handing to an agent in one shot.

### Import
- Settings → Import (or overflow menu in Routines list) → OS file picker → validate against `schemas/*.json` → show preview screen (X routines, Y steps to add/update) → confirm.
- **Merge strategy:** conflicting IDs → last-writer-wins by `updated_at`. New IDs → added. Import never deletes existing local data.
- Invalid files (schema violation, bad JSON) → clear error message with a link to the schema doc.

### Format
Both single and full exports use the same top-level shape (a subset for single-routine). One format everywhere = agents produce the same file that Import accepts.

---

## 11. Repo layout

```
openroutine/
├── LICENSE                        # MIT
├── README.md                      # user-facing intro + install + agent examples
├── CONTRIBUTING.md
├── docs/
│   ├── SPEC.md                    # this file
│   ├── architecture.md
│   ├── for-agents.md              # how agents interact with the Drive folder
│   └── publishing.md              # store submission playbook
├── schemas/                       # JSON schemas — the public API
│   ├── routine.schema.json
│   ├── step.schema.json
│   ├── trigger.schema.json
│   ├── completion.schema.json
│   └── export.schema.json         # top-level shape for import/export files
├── app/                           # Flutter
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/                # freezed + json_serializable
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── state/                 # Riverpod providers
│   │   ├── services/
│   │   │   ├── storage/
│   │   │   │   ├── storage_adapter.dart      # abstract
│   │   │   │   ├── local_adapter.dart
│   │   │   │   └── drive_adapter.dart
│   │   │   ├── auth/
│   │   │   ├── timer/
│   │   │   └── import_export/
│   │   ├── l10n/                  # ARB files, en + es
│   │   └── theme/
│   ├── assets/
│   │   ├── step_templates.json
│   │   ├── emojis.json            # curated ~60-emoji set, grouped by category
│   │   └── drive_folder_readme.md # written to user's Drive on first sync
│   ├── ios/                       # Xcode + Info.plist + PrivacyInfo.xcprivacy
│   ├── android/                   # Gradle + AndroidManifest.xml
│   └── test/
├── store-assets/                  # icons, screenshots, marketing copy
│   ├── icon/
│   ├── screenshots/               # per device size, en + es
│   ├── app-store/                 # metadata for App Store Connect
│   └── play-store/                # metadata for Play Console
└── .github/workflows/             # CI: lint, test, build, release
```

The Flutter app validates every JSON read against `schemas/*.json` at runtime.

---

## 12. Development milestones

1. **M1 — Skeleton (week 1)**
   Public GitHub repo initialized with LICENSE (MIT), README.md, CONTRIBUTING.md, `.gitignore`. Flutter scaffold with Riverpod + drift + go_router + freezed. Python-free monorepo. CI (lint + test on every PR). Bundle ID + package name registered in App Store Connect and Play Console. JSON schemas drafted in `schemas/`. Curated `emojis.json` seeded.

2. **M2 — Local-only CRUD (week 2)**
   Routines list, create routine, add/edit step, local persistence via drift. Onboarding + storage choice screen. Import/Export via OS share sheet (works locally with no Drive).

3. **M3 — Timer Mode (week 3)**
   State machine, playback UI, completion log persisted locally, local notifications, Android foreground service.

4. **M4 — Drive adapter (week 4)**
   `google_sign_in` (v7.1.0+), `drive_adapter.dart` targeting `/OpenRoutine/` folder in user's Drive, sync worker, in-folder `README.md` write, offline queue.

5. **M5 — Polish + i18n + agent docs (week 5)**
   Spanish translations, empty states, error handling, app icons + splash. `docs/for-agents.md`. README with GIFs and sample agent prompts.

6. **M6 — Store submission (week 6)**
   TestFlight + Play Internal Testing. Screenshots (en + es) per device size. Privacy declarations. Submit for review.

**Total: 6 weeks solo, part-time. ~4 weeks full-time.**

---

## 13. Non-negotiables for Claude Code

When implementing, Claude Code must:
- Never introduce a required backend service. Every feature must work with the Drive adapter or LocalOnly adapter alone.
- Keep the storage adapter interface pure (no Drive-specific types leaking into `models/` or `screens/`). Adding a new adapter (iCloud, Postgres) must not require touching the UI.
- Validate all JSON reads against `schemas/*.json` and log (don't crash) on drift. Never write files that violate the schema.
- Never frame Drive connection as "sign in" in UI copy — it is always "Connect" / "Connected". See §14.
- Every screen must have i18n keys from day 1 (no hardcoded English strings).
- Any change to entity shapes requires a schema bump AND a matching PR to `schemas/`. The schemas are the public API.
- **Repo is public from commit 1.** LICENSE (MIT), README.md, and CONTRIBUTING.md must exist before the initial push. No API keys, OAuth client secrets, signing keys, `.env` files, or personal identifiers ever committed — use `.gitignore` and GitHub Actions secrets. Every commit message is public; keep them professional.

---

## 14. Open questions / assumptions to revisit

- **Multi-device conflict volume** — LWW is fine for solo user with 1-2 devices. Revisit at v1.5.
- **Analytics** — deliberately none in v1. Consider opt-in local telemetry post-v1.
- **Additional locales** — Portuguese would be a natural third (Brazil market). Deferred to v1.5.
- **v2 MCP server** — reserved as an optional plugin for power users who want built-in `analyze_adherence` or `suggest_routine` prompts. Not blocking anything.

---

## 15. Publishing — App Store & Play Store

### 15.1 Identifiers (lock these on day 1)

| Thing | Value |
|---|---|
| Product name | **OpenRoutine** |
| App Store display name | **OpenRoutine** (30-char limit; fits) |
| Play Store name | **OpenRoutine — Your Routines** (50-char limit) |
| iOS Bundle ID | `app.openroutine.mobile` |
| Android package | `app.openroutine.mobile` |
| GitHub org/repo | `github.com/asloth/openroutine` |
| URL scheme (deep links) | `openroutine://` |

Bundle ID and package name **cannot be changed after first store submission** — verify domain and trademark availability before M1 completes.

### 15.2 Developer accounts

- **Apple Developer Program**: $99/year. Enroll as an individual (Sara Benel) — enrolling as an LLC/company requires a D-U-N-S number and takes weeks. Individual is faster and MIT license doesn't require a business entity.
- **Google Play Console**: $25 one-time. Individual account is fine.

### 15.3 Sign in with Apple — exemption reasoning

App Store Rule 4.8 requires Sign in with Apple *only if* a third-party login sets up the user's **primary account**. OpenRoutine qualifies for the **carveout for "client of a third-party service"**:

> *"Your app is a client for a specific third-party service and users are required to sign in to their mail, social media, or other third-party account directly to access their content."*

To keep this exemption solid, we must:
- **Never call it "Sign in with Google"** in UI. Always **"Connect Google Drive"**. The button is a storage adapter connection, not an identity system.
- **Make Local-only mode fully functional** as the default. The app has no "primary account" — there is no login screen at launch.
- **Never gate any feature behind the Google connection.** Every feature works locally.
- **Explain the OAuth scope in the connection screen**: "OpenRoutine will create a folder called 'OpenRoutine' in your Google Drive and store your routines there. It cannot see any other files."
- Include this reasoning in App Review Notes on first submission to preempt questions.

If Apple pushes back anyway (unlikely but possible), fallback is to add Sign in with Apple as a no-op identity token that unlocks a separate cloud sync — but that requires backend and we're not doing that.

### 15.4 Privacy Manifests (iOS)

Required as of May 2024 for apps using SDKs on Apple's list — `GoogleSignIn-iOS` is on it. Requirements:

- `google_sign_in` v7.1.0+ (bundles the Google SDK's Privacy Manifest automatically) — enforce in `pubspec.yaml`
- Ship `app/ios/Runner/PrivacyInfo.xcprivacy` declaring:
  - **NSPrivacyCollectedDataTypes**: empty (we collect nothing)
  - **NSPrivacyTracking**: `false`
  - **NSPrivacyAccessedAPITypes**: `UserDefaults` (`CA92.1`), `FileTimestamp` (`C617.1` if needed for sync)
- Add Xcode build phase to fail if any dependency lacks a manifest.

### 15.5 Privacy declarations (both stores)

Because we collect **nothing** and share **nothing**, our privacy story is a marketing asset. Both stores' declarations should say:

**App Store nutrition label:**
- **Data Not Collected** — for everything.
- If asked about Google Drive: it's the user's own account and files, not data we collect.

**Play Data Safety form:**
- No data collected. No data shared.
- Security practices: data encrypted in transit (HTTPS to Drive), users can request data deletion (they own the files and delete them themselves).

### 15.6 Privacy Policy

Required by both stores even if you collect nothing. One page, hosted on GitHub Pages at `openroutine.app/privacy` (or the .dev variant). Must state:
- What data is collected: none by us; user-chosen storage backends receive user-generated data
- Google Drive scope used (`drive.file`) and why
- Contact for GDPR/CCPA data requests (a GitHub issue link is acceptable for OSS)

### 15.7 Minimum OS versions

- **iOS 15+** — covers 99% of active devices, keeps Flutter build config clean
- **Android API 26 (8.0)+** — covers ~95% of active devices, matches Flutter's default minSdkVersion

### 15.8 Notifications

- Ask permission **only when the user first starts a Timer**, not at launch. Both platforms penalize (or reject) upfront permission requests without context.
- iOS: `UNUserNotificationCenter` via `flutter_local_notifications`. Include usage description in `Info.plist`.
- Android: `POST_NOTIFICATIONS` runtime permission (API 33+). Foreground service for Timer Mode when app is backgrounded so the countdown doesn't get killed by battery optimizations.

### 15.9 Store metadata (draft — refine before submission)

- **Subtitle (iOS, 30 char)**: *"Own your routines. Fully."*
- **Short description (Play, 80 char)**: *"Open-source routines. Your data lives in your own Google Drive."*
- **Long description**: lead with the three principles from §1. Highlight: (a) no account required, (b) your data in your Drive as plain JSON, (c) works with Claude / any agent that can read Drive files.
- **Keywords (iOS, 100 char)**: `routine,habit,timer,morning,evening,productivity,focus,study,checklist,open source`
- **Category**: iOS *Productivity* (primary), *Lifestyle* (secondary). Play: *Productivity*.
- **Age rating**: 4+ / Everyone. No age-inappropriate content, no data collection.

### 15.10 Localization

- Default: English. Second locale: Spanish (Sara's market + a large under-served demographic).
- Flutter `intl` + ARB files under `app/lib/l10n/`.
- Store listings must also be localized (screenshots, description, keywords).
- Third locale (Portuguese) deferred to v1.5.

### 15.11 App Store / Play Store assets (produce during M5-M6)

- **App icon**: 1024×1024 master PNG (no alpha, no rounded corners). Auto-generate all iOS + Android sizes via `flutter_launcher_icons`.
- **Splash screen**: solid brand color + wordmark. Use `flutter_native_splash`.
- **iOS screenshots**: 6.7" (1290×2796) and 6.1" (1179×2556) at minimum, both locales.
- **Android screenshots**: phone (min 2), 7" tablet (optional), 10" tablet (optional), both locales.
- **Feature graphic (Play)**: 1024×500 PNG.
- **Preview video (optional)**: 15–30s screen recording of Timer Mode.

### 15.12 CI/CD

- `.github/workflows/`:
  - `flutter-ci.yml` — analyze, test, build APK + IPA on every PR
  - `release.yml` — tag-triggered: build signed APK, AAB, IPA; upload to Play Internal + TestFlight via Fastlane
- **Fastlane** in `app/ios/fastlane` and `app/android/fastlane` for automated store uploads.
- **Signing**: Play App Signing (Google manages the key). iOS: App Store distribution certificate + provisioning profile stored as GitHub Actions secrets.

### 15.13 First-submission checklist (for M6)

- [ ] Bundle ID + package registered in App Store Connect + Play Console
- [ ] Privacy Policy live at a stable URL
- [ ] `PrivacyInfo.xcprivacy` present and reviewed
- [ ] App Store nutrition label filled: "Data Not Collected"
- [ ] Play Data Safety form filled: no collection, no sharing
- [ ] Screenshots for both required iOS sizes + two Android sizes, both en + es
- [ ] App icon + splash finalized
- [ ] Review Notes drafted explaining §15.3 (SIWA exemption)
- [ ] Demo account not needed (app works fully without any account)
- [ ] TestFlight beta with ≥5 external testers for one week
- [ ] Play Internal Testing with ≥5 testers for one week
- [ ] Localizations for en + es complete and reviewed by a native speaker
- [ ] `USE_EXACT_ALARM` justified in Play Console — see §15.14

### 15.14 Exact alarm permission (Play review)

Timer Mode schedules each step's expiry as an exact alarm so a 3-minute step is actually 3 minutes; an inexact alarm can drift by minutes, which is useless for a timer (§8). The Android manifest declares `USE_EXACT_ALARM`, plus `SCHEDULE_EXACT_ALARM` for API 31–32.

Play policy restricts `USE_EXACT_ALARM` to apps whose **core function** is an alarm clock, timer, or calendar reminder. OpenRoutine qualifies on the timer clause — guided step-by-step routine timing is the app's headline feature, not an incidental one — but this is reviewed rather than assumed, so the Play Console declaration must state that plainly. If it is ever rejected, the fallback is `SCHEDULE_EXACT_ALARM` with a runtime permission prompt, degrading to inexact alarms when denied.

Chosen deliberately over a foreground service, which would have needed a `specialUse` `foregroundServiceType` and its own justification while giving weaker guarantees. See §8.
