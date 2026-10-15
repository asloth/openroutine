## Purpose

Defines when the timer keeps the display awake. Notifications on a locked phone are inexact, so an awake screen is how you see a step's exact progress.

## ADDED Requirements

### Requirement: The display stays awake while a step runs

The timer screen SHALL keep the display awake while the run is in its running phase. It SHALL let the display sleep when the run is paused, when the run completes, and when the timer screen is left.

#### Scenario: A run starts

- **WHEN** a run starts and its first step is running
- **THEN** the display is kept awake

#### Scenario: The run is paused and resumed

- **WHEN** the run is paused
- **THEN** the display is free to sleep
- **WHEN** the run is resumed
- **THEN** the display is kept awake again

#### Scenario: The timer is left

- **WHEN** the timer screen is closed
- **THEN** the display is free to sleep
