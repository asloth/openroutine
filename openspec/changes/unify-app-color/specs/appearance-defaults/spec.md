## REMOVED Requirements

### Requirement: A fresh install uses the default palette

**Reason**: There is no longer a separate background palette to default. Settings › Appearance
offers a single color choice — the accent — and the `accent-color` capability's "The accent
defaults to purple" requirement now covers what a fresh install is themed with, including the
surfaces and the mascot this requirement used to leave to a different setting.

**Migration**: None. The behavior isn't dropped, it's relocated: a fresh install still themes
itself the moment it starts, using `Palette.inkIris`, via the accent-color capability instead of a
background-palette default. No stored value needs migrating — the `theme_palette` preference key,
where present on a device, is simply never read again.
