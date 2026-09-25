## Context

See `proposal.md`. The fur is one traced outline (`hair_tuft`), and the eye, mouth, arms, and feet are separate shapes. Replacing the outline's vertices changes the look without touching any animation that keys the other parts.

## Decisions

### Trace, fit to the eye, keep the height

The reference is masked by colour, traced with potrace, and scaled by 0.568 so the curl tip and the ground land where they do now (artboard y 175 and 705), centred on the eye. The eye fits inside the new outline with 30px to spare on every side. Keeping the height means `MascotSlot` sizing, the finished-screen size fix, and onboarding layouts need no change.

### Shading is a second copy of the outline, not a gradient on the fur

The fur's fill stays bound to `bodyColor`. A copy of the same path sits on top with a gradient from translucent white to translucent black. Binding a gradient's stops to `bodyColor` would lose the light and shade, and a fixed lighter blue would be wrong on every other palette.

### The ground shadow uses the accent

The spec already says anything outside the silhouette takes `onSurfaceVariant`, which reaches Rive as `accentColor`. A body-coloured shadow would read as a glow on the dark theme.

### The smile is a lid clipped to the eye

`cheek_lid` is a body-coloured ellipse with an 8px ink stroke, clipped to `lid_mask`: a paintless copy of the eye white at 1.035 scale. Clipping to the eye white itself left a cream hairline, because that shape has its own stroke. The lid's height follows the old squash curve in each happy animation, and the squash is softened to a quarter of its depth.

*Alternative considered:* a closed "^" eye. Rejected: Sara likes the eye, and the lid keeps it visible.

## Risks / Trade-offs

**The feet show a seam when they pop out.** → Checked by rendering every move at its start, middle, and end. The rounder bottom still covers the tops of the legs.

**The tap area changes shape.** → Checked with pointer clicks on the body, a side tuft, the curl, and the lower edge (all fire `tap`), and on an empty corner (doesn't fire).
