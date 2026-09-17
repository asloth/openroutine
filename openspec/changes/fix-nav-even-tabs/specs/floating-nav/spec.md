## Purpose

See `fix-nav-highlight`'s delta for the base of this capability: the shape guarantees for the
floating bottom navigation bar's selected-destination highlight. This delta adds the guarantee that
every destination's slot — not just the selected one's highlight — shares a common width, so the
bar reads as even regardless of which label is shortest or longest.

## ADDED Requirements

### Requirement: Every destination shares the same slot width

The bar SHALL give every destination the same slot width: the width of the widest destination's own
content, in whichever shipped locale is active.

#### Scenario: Labels of different lengths

- **GIVEN** three destinations whose labels render at different widths, such as "Today," "Routines,"
  and "Streaks"
- **WHEN** the bar renders
- **THEN** all three destinations' slots — and so their selected highlights — are the same width
- **AND** that width equals the widest destination's own preferred content width

## MODIFIED Requirements

### Requirement: The selected highlight is a pill, not a circle

When a destination is selected, its highlight SHALL be visibly wider than it is tall, and SHALL
fully enclose the icon and label it surrounds with a margin on both sides — not merely match the
label's own width. This holds regardless of which destination is selected, including the one with
the shortest label.

#### Scenario: A short label is selected

- **WHEN** a destination with a short label, such as "Routines," is selected
- **THEN** the highlight's rendered width is greater than its rendered height
- **AND** the highlight's left and right edges sit outside the label's own left and right edges

#### Scenario: The shortest label is selected

- **WHEN** the destination with the shortest label among the three, such as "Today," is selected
- **THEN** the highlight's rendered width is still greater than its rendered height, matching the
  width shared by the other destinations' slots

#### Scenario: The system text scale grows

- **GIVEN** a system text scale up to the label's 1.6x growth cap
- **WHEN** a destination is selected
- **THEN** the highlight remains wider than it is tall and still encloses the label with a margin
  on both sides
