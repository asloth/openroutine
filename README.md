# OpenRoutine

> Your routines. Your data. Your agent.

OpenRoutine is an open-source, local-first routine app for iOS and Android. Your routines live as plain JSON files in **your own Google Drive** — not on a server we run. Any AI agent with access to your Drive (Claude, Codex, or others) can read, reason about, and help you edit them.

**No backend. No server to install. No account required.**

## Why

1. **Local-first, user-owned storage.** The app is a client, nothing more. Your routines live in your Drive folder as plain JSON, and we never hold your data.
2. **Zero-cost to run.** No backend to host, scale, or pay for.
3. **Agent-friendly via open schema.** The data format is documented and stable — see [`schemas/`](schemas/). Any agent that can read a JSON file can help manage your routines.
4. **Open source.** MIT license. No feature gating, no "Pro" tier.
5. **Privacy by design.** Minimal OAuth scope (`drive.file` — the app only sees files it created). Revoke access anytime.

Full product and technical spec: [`docs/SPEC.md`](docs/SPEC.md).

## Status

OpenRoutine is at milestone **M5 — Polish, i18n, and agent documentation**. M1
through M4 already shipped the local-first app, routine timer, import/export,
and optional Google Drive sync. OpenRoutine isn't published to an app store
yet.

## How agents fit in

There's no custom server or API — the published JSON schema plus your own
Google Drive access *is* the integration surface. If you connect Drive in
OpenRoutine and connect the same Drive account to an AI agent, start with one
of these prompts.

**Review adherence without editing:**

> Read `OpenRoutine/routines.json` and `OpenRoutine/completions/` in my Drive.
> Summarize which routine steps I skip most often and which regularly overrun.
> Do not change any files.

**Propose a smaller routine:**

> Read my evening routine and its completion history in the `OpenRoutine`
> folder. Propose a version I can finish in 20 minutes. Show the exact changes
> first, but do not write them until I confirm.

**Add a routine safely:**

> Read `OpenRoutine/README.md`, `OpenRoutine/routines.json`, and the OpenRoutine
> agent guide. Design a study routine for deep work and Spanish practice. After
> I approve it, add schema-valid routine and step records with UUIDv7 IDs, keep
> `step_ids` and `order` consistent, and use current UTC timestamps.

**Apply a confirmed edit:**

> Rename the routine with ID `<routine-id>` to "Short evening reset". Preserve
> every other field and unknown field, bump only that routine's `updated_at` to
> the current UTC time, validate the full document, and write it back.

See [`docs/for-agents.md`](docs/for-agents.md) for schemas, valid enums, merge
rules, tombstones, timestamp requirements, and safe-edit examples.

## Repo layout

```
openroutine/
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── docs/           # spec, architecture, agent guide, publishing playbook
├── schemas/        # JSON Schema — the public data contract
└── app/            # Flutter app (iOS + Android)
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT — see [`LICENSE`](LICENSE).
