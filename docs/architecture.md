# Architecture

Full detail lives in [`SPEC.md`](SPEC.md): §3 covers the architecture overview, §5 covers storage layout and sync, and §6 covers auth. This doc will grow into a standalone deep dive — with diagrams of the storage-adapter interface, the sync worker, and the Timer Mode state machine (§8) — as those pieces get built starting in M2–M4.

For now, here's the short version: there's no custom server. The Flutter app talks either to a local SQLite cache (`drift`) or directly to the user's own Google Drive. You'll find the full picture in the spec.
