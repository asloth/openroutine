## Purpose

Defines the shape guarantees for the floating bottom navigation bar's selected-destination
highlight: that it reads as a pill wide enough to hold its icon and label, and that it keeps the
whole bar on screen at the label's supported text-scale range in both shipped locales. The
capability exists because a highlight sized to its content with no margin looks fine for some
labels and rounds into a shape its own label pokes out of for others — the defect is invisible
until measured against the actual rendered content.

## ADDED Requirements

### Requirement: The selected highlight is a pill, not a circle

When a destination is selected, its highlight SHALL be visibly wider than it is tall, and SHALL
fully enclose the icon and label it surrounds with a margin on both sides — not merely match the
label's own width.

#### Scenario: A short label is selected

- **WHEN** a destination with a short label, such as "Routines," is selected
- **THEN** the highlight's rendered width is greater than its rendered height
- **AND** the highlight's left and right edges sit outside the label's own left and right edges

#### Scenario: The system text scale grows

- **GIVEN** a system text scale up to the label's 1.6x growth cap
- **WHEN** a destination is selected
- **THEN** the highlight remains wider than it is tall and still encloses the label with a margin
  on both sides

### Requirement: The bar stays on screen at the label's scale cap in every shipped locale

The bar SHALL fit within a 360dp-wide screen at the label's 1.6x scale cap, using either shipped
locale's labels — including the longer Spanish "Estadísticas."

#### Scenario: Spanish labels at the scale cap on a narrow phone

- **GIVEN** a 360dp-wide screen and the Spanish destination labels
- **WHEN** the system text scale is at or above the label's 1.6x cap
- **THEN** the bar renders with no layout exception
- **AND** the bar's rendered bounds stay within the screen's width
