"""Removes the inward ledge at the top of each foot.

Both feet carried a small shelf pointing toward the middle, about 25px above the
foot, that the old, rounder belly hid. The softer fur ends higher, so on a jump's
landing the two shelves peek out under it, meet in the middle, and read as a bar
with a gap line above it. Each leg's inner edge now runs straight from the top
cap down to the foot.

usage: fix_leg_ledge.py SCENE_IN SCENE_OUT"""
import re
import sys

src, out = sys.argv[1:3]
s = open(src).read()

LEDGES = {
    # foot: (x of each shelf vertex, the inner-edge vertex above the shelf, and
    # which of its handles faced the shelf; the paths wind in opposite directions)
    'foot_left" id="0:917"': (('-39.990', '-54.560', '-52.191', '-29.690'), '-26.394', 'out'),
    'foot_right" id="0:940"': (('33.934', '53.940', '39.370'), '25.774', 'in'),
}

for foot, (shelf, above, side) in LEDGES.items():
    start = s.index(f'name="{foot}>')
    end = s.index('</PointsPath>', start)
    path = s[start:end]
    for x in shelf:
        path, n = re.subn(rf' *<CubicDetachedVertex [^>]* x="{x}" [^>]*/>\n', '', path)
        assert n == 1, (foot, x)
    # Point the vertex above the shelf straight down, so the edge stays smooth.
    path, n = re.subn(rf'({side}Rotation=")[^"]*(" {side}Distance=")[^"]*("[^>]* x="{above}")',
                      r'\g<1>1.57080\g<2>8.000\g<3>', path)
    assert n == 1, (foot, above)
    s = s[:start] + path + s[end:]

open(out, 'w').write(s)
print('written', out, file=sys.stderr)
