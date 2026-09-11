## Purpose

Defines how Settings › Appearance's two color pickers — the background palette picker and the
accent color picker — present themselves so a person can tell them apart and understand what each
swatch is naming. The capability exists because two pickers that share a swatch pattern and sit
back to back under one section header read as one confusing picker unless each carries its own
title and each names its swatches for the question it is actually asking.

## ADDED Requirements

### Requirement: The background palette picker carries its own title and helper

`PalettePicker` SHALL render a title and a one-line helper above its swatches, matching the title
and helper style `AccentPicker` already uses, so the two pickers read as separate, clearly labeled
sections rather than one titled picker and one bare row of swatches.

#### Scenario: Settings › Appearance renders both pickers

- **WHEN** Settings › Appearance is shown
- **THEN** a theme title and helper appear above the background palette swatches
- **AND** the theme title renders above the accent color picker's own title, matching the order the
  two pickers are shown in

### Requirement: The accent picker names its swatches by color, not by theme

Each built-in accent swatch's semantics label, tooltip, and "{name} selected" caption SHALL name
the color the swatch shows, not the background theme the same `Palette` value also produces.

The background palette picker is unaffected: its own swatches keep naming the theme, because a
theme picker naming its swatches by theme is correct.

#### Scenario: An accent swatch is announced

- **WHEN** an accent swatch for a built-in palette is rendered
- **THEN** its semantics label and tooltip are a plain color word
- **AND** that word differs from the theme name the same palette uses in the background palette
  picker

#### Scenario: An accent is selected

- **WHEN** an accent color is selected
- **THEN** the "{name} selected" caption under the accent swatches names the color, not the theme
