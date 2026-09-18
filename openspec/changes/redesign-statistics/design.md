# Design notes

## One colour, the accent

An earlier pass drew the estimate bars as a diverging pair — green for under,
warm for over — taken from `colorScheme.secondary` and `tertiary`. Those sit
at fixed hue offsets from the accent, so on a blue accent they came out plum
and navy, saying nothing. Pinning them to the palette's fixed moss and honey
fixed the meaning but broke the app: Statistics went green while Today stayed
blue.

Everything here is a single series. The bar's direction and its signed number
already separate over from under, so the second hue was saying a third time
what the shape says once, and it could only do so from outside the accent.
One colour, the accent, everywhere.

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

## Findings, not figures

The headline on each card is chosen from the data, so it has to hold up at
every value, not just the flattering one. Finishing has three: most, more than
half, and — below half — "You start more than you finish." Descriptive, the
mirror of the good case, and not a reproach. That was a deliberate choice over
a warmer deflection that would have dodged the number.

## Ten dots, not one per run

The rate now reads as a proportion out of ten rather than a segment per run,
which is what lets the sentence under it say "8 out of every 10".

Rounding is clamped at both ends. 39 of 40 rounds to ten, which would read as
a clean sweep; 1 of 40 rounds to zero, which would read as finishing nothing.
Neither is true, and the two errors are not symmetric in how they land, so the
clamp only lets ten mean every run and zero mean none.

## Where the small hours go

`dayPartOf` puts 18:00 through 04:59 in the evening. A run at 01:00 is the
tail of a night, not the start of a morning, and bucketing it as morning would
put the wrong word in the headline.

## Styling a value inside a sentence

The estimate detail bolds the step name inside "Deep work block is the biggest
one." Concatenating fragments would force English word order on every
translation, so `_around` renders the whole message with a sentinel in place
of the value and cuts at it. The translator keeps the word order; the value
keeps its style.
