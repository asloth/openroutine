# OpenRoutine

> Your routines. Your data. Your agent.

OpenRoutine is an open-source, local-first routine app for iOS and Android. Your routines live as plain JSON files in **your own Google Drive** — not on a server we run. Any AI agent with access to your Drive (Claude, Codex, or others) can read, reason about, and help you edit them.

**No backend. No server to install. No account required.**

## Why

1. **Local-first, user-owned storage.** The app is a client. Routines live in your Drive folder as plain JSON. We never hold your data.
2. **Zero-cost to run.** No backend to host, scale, or pay for.
3. **Agent-friendly via open schema.** The data format is documented and stable — see [`schemas/`](schemas/). Any agent that can read a JSON file can help manage your routines.
4. **Open source.** MIT license. No feature gating, no "Pro" tier.
5. **Privacy by design.** Minimal OAuth scope (`drive.file` — the app only sees files it created). Revoke access anytime.

Full product and technical spec: [`docs/SPEC.md`](docs/SPEC.md).

## Status

🚧 Early development (Milestone M1 — skeleton). Not yet published to any app store.

## How agents fit in

There's no custom server or API. The published JSON schema plus your own Google Drive access *is* the integration surface. If you connect Drive in OpenRoutine and connect the same Drive account to an AI agent, you can ask it things like:

> *"Read `OpenRoutine/routines.json` in my Drive. Which steps have I skipped most in the last 30 days based on `completions/`? Propose a shorter evening routine and write the changes back."*

> *"Design me a study routine for deep work + Spanish practice. Add it to `OpenRoutine/routines.json`."*

See [`docs/for-agents.md`](docs/for-agents.md) for the full guide written for agents.

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
