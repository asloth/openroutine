# Architecture

Full detail lives in [`SPEC.md`](SPEC.md) §3 (architecture overview), §5 (storage layout & sync), and §6 (auth). This doc will expand into a standalone deep-dive — with diagrams of the storage-adapter interface, the sync worker, and the Timer Mode state machine (§8) — as those pieces are built starting in M2–M4.

For now: there is no custom server. The Flutter app talks either to a local SQLite cache (`drift`) or directly to the user's own Google Drive. The full picture is in the spec.
