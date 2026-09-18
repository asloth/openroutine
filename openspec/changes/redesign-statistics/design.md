# Design notes

## Sharing home's ink

`HomeInk` and `HomeDot` live under `screens/routines_list/home/`. Statistics
imports them rather than restating the same roles against `colorScheme`.

The alternative was moving `HomeInk` somewhere shared. That would touch every
home file for no behaviour change, and the repo already crosses this boundary:
`routines_library_screen.dart` imports `HomeRoutineRow` from the same folder.
Worth revisiting when a third screen needs it.

## One segment per run

The old bar capped at 20 segments, so 40 runs drew 20 and the bar meant only
a ratio. It now draws one segment per run up to 60, which makes it countable.

Past 60 the segments would be thinner than the gaps between them, so it falls
back to a scaled bar. `SegmentedProgress` gained a third gap tier — 2px past
24 segments — because 4px of gap is wider than the run it separates once the
segments get that thin. Statistics is that widget's only caller.

## Diverging, not two bars

A step that ran long and a step that came in under are the same measurement
in opposite directions, so they share one axis: the bar grows right from a
centre line when over, left when under. Two separate left-aligned bars would
have made "8 minutes over" and "8 minutes under" look identical.

Every bar scales against the widest difference on screen, not against its own
row, so the lengths compare to each other.

## The minus sign

Differences render with U+2212, not a hyphen. At 13px a hyphen next to a digit
reads as a dash in the text rather than a sign on the number.

## Skipped steps as cards

Most-skipped is the one section where each row is a thing you might act on —
a step you keep skipping is a step to shorten or drop. Cards give each one its
own edge; the other sections stay flat on the paper.
