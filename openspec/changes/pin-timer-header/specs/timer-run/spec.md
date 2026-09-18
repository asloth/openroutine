## Purpose

See `redesign-timer-run`'s delta for the base of this capability. This delta adds the guarantee
that the running screen's header — the back button, the routine name and step count, and the
pause button — stays fixed while the rest of the run scrolls, rather than clipping under the status
bar.

## MODIFIED Requirements

### Requirement: The running screen shows the step and its time

The running screen SHALL show the routine's name, the current step's position in the run, the
mascot, the step's name, and a clock that counts up. For a step with a set time, a bar SHALL fill
toward the estimate, and the clock and bar SHALL change colour at and after the estimate without
showing overtime text. The routine name, step position, back control, and pause control SHALL stay
fixed at the top of the screen regardless of how far the rest of the run is scrolled.

#### Scenario: A timed step starts

- **WHEN** the first of three steps starts
- **THEN** the screen shows "1 of 3", the step's name, and 0:00

#### Scenario: A step passes its estimate

- **GIVEN** a two-minute step
- **WHEN** 2:01 has elapsed
- **THEN** the clock reads 2:01 in the estimate colour and the bar is full

#### Scenario: The rest of the run scrolls

- **GIVEN** a run long enough that "Rest of the run" overflows the screen
- **WHEN** the user scrolls that content
- **THEN** the back button, the routine name and step count, and the pause button hold their
  position rather than moving under the status bar
