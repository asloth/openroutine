## Context

See `proposal.md`. Settings already opens external links with `url_launcher` ("View on GitHub"), and `packageInfoProvider` already supplies the version shown in About.

## Goals / Non-Goals

**Goals:**

- Feedback reaches the developer with enough context to act on, and the person sending it sees everything first.

**Non-Goals:**

- In-app forms, screenshots, logs, or crash reports. Any of those would need either a backend or a third-party service.
- Play Store ratings or the in-app review prompt. Those are a separate decision.

## Decisions

### `mailto:` with percent-encoded spaces

`Uri(queryParameters: ...)` encodes spaces as `+`, and several email apps show those literally. The link is built with `Uri.encodeComponent`, which writes `%20`.

### Details go below the space to write

The draft starts with blank lines, so the cursor lands where the person writes, then a labelled details block. The label says the details can be deleted.

### The address is one constant

It lives in `feedback_email.dart`, so changing inboxes is one edit. It's public by nature: it appears in the draft's To field and in the repository.

### The launcher is a provider

`launchUrl` can't run in a widget test. A provider that returns `Future<bool> Function(Uri)` defaults to `launchUrl` in external-app mode, and tests override it to record the link or simulate a phone with no email app.
