## Context

See `proposal.md` — Why. `_MascotSlotState` currently has `late final Future<File?> _file =
_load();` — an instance field, initialized once per `State` object, not once per app run. Each
`MascotSlot` that mounts — including a brand-new one on a freshly pushed screen, like the timer
screen the owner saw the flash on — starts its own decode of `assets/mascot.riv`. `FutureBuilder`
shows `_MascotPlaceholder` whenever `snapshot.data == null`, which is true for the entire loading
window, not just a failure. `RiveWidgetBuilder`'s `builder` callback does the same for any
`RiveState` that isn't `RiveLoaded`, including the initial `RiveLoading`. So on every fresh slot,
the pre-Rive hand-drawn pet paints for as long as the decode takes, then the real pet replaces it —
the flash.

## Goals / Non-Goals

**Goals:**

- Decode `assets/mascot.riv` at most once per app run, shared by every `MascotSlot` instance.
- Never show the hand-drawn placeholder purely because loading hasn't finished yet. Reserve it for
  when there's no pet to show at all: `_riveAvailable` is false (as under `flutter test`), the
  shared file resolved with no data, or the state machine reports `RiveFailed`.
- Keep the slot's layout stable while empty — an empty box at the slot's own size, not a collapsed
  one.
- Make the loading decision unit-testable without ever loading a real `.riv` file, since doing so
  under `flutter test` aborts the process.

**Non-Goals:**

- Changing what the placeholder looks like, or when a *mood* changes what it draws. `_MascotPainter`
  and `_MascotPlaceholder` are unchanged.
- Preloading the file before the first slot mounts, or warming the cache at app startup. The first
  slot built still pays the decode cost — it just pays it once, not once per screen.
- Touching `app/lib/screens/timer/timer_screen.dart`. A separate change is already editing it.

## Decisions

### A static, lazily created `Future<File?>`, not an instance field

`_sharedFile` moves from an instance `late final` to a `static Future<File?>?` on
`_MascotSlotState`, populated on first access via `_sharedFile ??= _load()`. Every slot's `_file`
getter reads the same field, so the second slot built — on the very next screen — gets an
already-resolved (or already in-flight) future instead of starting its own decode. Because the file
is shared, `dispose` no longer disposes it: another slot elsewhere in the tree may still hold it.

*Alternative considered:* a top-level singleton service (`MascotFileCache` or similar) instead of a
static field on the private `State` class. Rejected: the file is purely an implementation detail of
how `MascotSlot` renders itself — nothing outside this widget needs to know it exists — so a new
public service would be a wider surface for the same job a private static field already does.

### Two small pure functions instead of inline `null`-checks

The old code decided what to render with two inline checks — `if (file == null)` in the
`FutureBuilder`, and a `switch (state) { RiveLoaded(...) => ..., _ => placeholder }` in
`RiveWidgetBuilder` — both of which conflated "still loading" with "failed." Splitting each check
into a pure function (`mascotLoadVisual<T>(AsyncSnapshot<T?>)` and `mascotRiveVisual(RiveState)`),
both returning a shared `MascotSlotVisual { empty, placeholder, rive }` enum, makes the "empty vs.
placeholder vs. real pet" decision testable with plain `AsyncSnapshot` and `RiveState` values —
neither of which requires a real Rive runtime. `mascotLoadVisual` is generic over `T` specifically
so its unit tests don't need to construct a real (abstract, native-backed) Rive `File`.

### A `@visibleForTesting` loader-override hook, not a raw future override

`MascotSlot.debugFileLoader` replaces the *function* that produces the shared future
(`_debugFileLoader`), and clears the cached `_sharedFile` when set, rather than replacing the future
directly. A function can be substituted with a `Completer` that never completes (to hold the
"loading" state open in a test) or one that counts its own invocations (to prove two slots share a
single load) — a raw future override could do the first but not the second.

## Risks / Trade-offs

**Static state persists for the life of the process, including across widget tests in the same
file.** → `MascotSlot.debugFileLoader = null` in `tearDown` resets both the override and the cached
future, so tests don't bleed into each other. Production code never resets it, which is the point:
one decode per app run.

**A slot that mounts after the shared file already failed shows the placeholder immediately, with
no retry.** → Unchanged from before this fix; `_load`'s `catch` already turned any failure into a
permanent `null`. Retrying a failed decode is out of scope here.

## Migration Plan

None. Presentation only; nothing persisted changes shape.
