## Decisions

**audioplayers in low-latency mode.** The sounds are under 2.5 seconds, so low-latency mode fits. Each sound mixes with other audio instead of taking audio focus, so your music keeps playing. It also respects silent mode.

**The provider does the gating.** `appSoundsProvider` returns `SilentAppSounds` when the setting is off, so the timer plays sounds without reading the setting itself, and tests swap in a fake.

**The last step celebrates instead of popping.** `completeStep` pops only when the run is still active afterward. Entering the completed phase plays the finish sound once, in `_apply`, beside where the log is persisted.

**One nudge channel, one sound.** Halfway and near-end share a channel, so both play bip bip boo. Splitting them would need another channel and another setting for little gain.

**The finish sound is one file.** wheee and boing are mixed offline with ffmpeg (boing starts 1.0 s in), so they can't drift apart at playback.
