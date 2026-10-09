"""Rebuilds Ochi's `jump` (0:2321) so it reads as a body, not a sprite.

The old jump moved every part on the same frames and held a stiff V in the
air. This one adds anticipation, gravity (slow at the top, fast into the
ground), drag on the flame of fur, the arms, the wrists and the feet, a lean
in the air, eye acting, a blink on impact, a shadow that shrinks with height,
and a landing wobble that dies away.

The flame's points had no ids, so they couldn't be keyed. This gives the five
flame points ids in both `hair_tuft` and its `fur_shading` copy (which share
geometry) and moves them together.

Reads build/scene.pre-humanize.rml.bak, writes scene.rml. Run from the
project directory: python3 build/gen_humanize.py
"""
import re
import sys

SRC = 'build/scene.pre-humanize.rml.bak'
OUT = 'scene.rml'
JUMP_ID = '0:2321'
D = 96  # frames at 60 fps

X, Y, ROT, SX, SY, OPACITY = 13, 14, 15, 16, 17, 18
VX, VY = 24, 25

IO = (0.42, 0.0, 0.58, 1.0)
EO = (0.16, 0.7, 0.3, 1.0)
UP = (0.15, 0.75, 0.35, 1.0)    # launch: fast off the ground, easing to the top
DOWN = (0.55, 0.0, 0.85, 0.4)   # fall: gravity, speeding up into the ground
SNAP = (0.2, 0.9, 0.3, 1.0)     # quick move that lands softly
HOLD = 'hold'

s = open(SRC).read()

# --- Give the flame points ids --------------------------------------------
FLAME = {25: 0.45, 26: 1.0, 27: 1.0, 28: 1.0, 29: 0.45}  # vertex index: weight
flame_ids = {}  # id -> (x, y, weight)


def tag_flame(s, shape, first_id):
    start = s.index(f'name="{shape}"')
    end = s.index('</PointsPath>', start)
    body = s[start:end]
    verts = list(re.finditer(r'<CubicDetachedVertex ([^>]*?)/>', body))
    out, last = [], 0
    for n, (index, weight) in enumerate(sorted(FLAME.items())):
        m = verts[index]
        attrs = m.group(1)
        vid = f'0:{first_id + n}'
        x = float(re.search(r' x="([-\d.]+)"', ' ' + attrs).group(1))
        y = float(re.search(r' y="([-\d.]+)"', ' ' + attrs).group(1))
        flame_ids[vid] = (x, y, weight)
        out.append(body[last:m.end(1)])
        if 'id="' not in attrs:
            out.append(f' id="{vid}"')
        last = m.end(1)
    out.append(body[last:])
    return s[:start] + ''.join(out) + s[end:]


s = tag_flame(s, 'hair_tuft', 2600)
s = tag_flame(s, 'fur_shading', 2605)

# --- Rest pose: everything the old jump pinned, plus what this one adds ----
a = s.index(f'id="{JUMP_ID}"')
a = s.rfind('<LinearAnimation', 0, a)
b = s.index('</LinearAnimation>', a) + len('</LinearAnimation>\n')
old = s[a:b]
REST = {}
for ob in re.finditer(r'<KeyedObject objectId="([^"]+)">(.*?)</KeyedObject>', old, re.S):
    for kp in re.finditer(r'<KeyedProperty propertyKey="(\d+)">(.*?)</KeyedProperty>', ob.group(2), re.S):
        first = re.search(r'value="([^"]+)"', kp.group(2)).group(1)
        REST.setdefault(ob.group(1), {})[int(kp.group(1))] = float(first)
REST.setdefault('0:2211', {})[ROT] = 0.0                       # wrist_left
REST['0:2451'] = {SX: 1.0, SY: 1.0, OPACITY: 0.22}              # ground_shadow
for vid, (x, y, _) in flame_ids.items():
    REST[vid] = {VX: x, VY: y}


def kf(frame, value, ease=IO):
    v = round(value, 5)
    if ease is None:
        return f'<KeyFrameDouble value="{v}" interpolationType="linear" frame="{frame}"/>'
    if ease == HOLD:
        return f'<KeyFrameDouble value="{v}" interpolationType="hold" frame="{frame}"/>'
    x1, y1, x2, y2 = ease
    return (f'<KeyFrameDouble value="{v}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/></KeyFrameDouble>')


def lag(frames, by, scale=1.0, base=0.0, mirror=False):
    """The same curve `by` frames later, scaled around `base` and optionally
    mirrored: the trailing side of the body. Frame 0 and the last frame stay
    put, and so does the rest value."""
    out = []
    for f in frames:
        frame, value = f[0], f[1]
        rest = f[2:]
        if 0 < frame < D:
            frame = min(frame + by, D - 1)
        value = base + (value - base) * scale
        out.append((frame, -value if mirror else value, *rest))
    return out


def offset(frames, base):
    return [(f[0], base + f[1], *f[2:]) for f in frames]


C = {}

# Rig: up fast, ease over the top, fall faster, stop dead on contact.
C['0:2001'] = {
    Y: [(0, 706), (24, 706, UP), (42, 622, DOWN), (58, 706, None), (D, 706)],
    # Stretch peaks at takeoff, while he's still low, so the flame never
    # leaves the artboard; he's relaxed again by the top.
    SY: [(0, 1), (10, 1), (22, 0.82), (24, 0.84, SNAP), (27, 1.13), (33, 1.02), (44, 0.98),
         (54, 1.05, None), (58, 0.83), (60, 0.85, SNAP), (65, 1.06), (70, 0.97), (75, 1.015),
         (81, 1), (D, 1)],
    SX: [(0, 1), (10, 1), (22, 1.12), (24, 1.1, SNAP), (27, 0.9), (33, 0.99), (44, 1.02),
         (54, 0.96, None), (58, 1.13), (60, 1.12, SNAP), (65, 0.96), (70, 1.02), (75, 0.99),
         (81, 1), (D, 1)],
}

# A lean that never mirrors itself: forward into the crouch, back on the
# launch, a drift at the top, a catch on landing.
C['0:748'] = {ROT: [(0, 0), (20, 0.03), (28, -0.03), (42, 0.06), (54, 0.03), (60, -0.035),
                    (68, 0.018), (76, -0.006), (84, 0), (D, 0)]}

# Feet out at the start, tucked at the end (same as the rest of the moves).
C['0:2200'] = {Y: [(0, 58), (0, 58, EO), (8, -4), (12, 0), (82, 0), (D, 58)]}
C['0:2201'] = {Y: [(0, -66), (0, -66, EO), (8, 4), (12, 0), (82, 0), (D, -66)]}

# Feet dangle in the air and reach for the ground before contact.
foot = [(0, 0), (24, 0), (31, 0.3), (44, 0.14), (54, -0.06), (58, 0), (64, 0.05), (70, 0), (D, 0)]
C['0:917'] = {ROT: foot}
C['0:940'] = {ROT: lag(foot, 2, 0.85, mirror=True)}

# Arms: out low in the wind-up, whip up a beat after the body, float up as
# it falls, flop on impact, settle, tuck. The left arm trails the right.
arm_sy = [(0, 0.001), (10, 0.001, EO), (18, 1), (80, 1, (0.5, 0, 0.75, 0.3)), (90, 0.001, None), (D, 0.001)]
arm_rot = [(0, 0.25), (12, 0.25), (22, 0.95), (26, 0.9, SNAP), (32, 0.1), (38, 0.3), (46, 0.42),
           (54, 0.2, None), (60, 0.8, SNAP), (66, 0.45), (72, 0.64), (78, 0.55), (90, 0.25), (D, 0.25)]
C['0:2050'] = {SY: arm_sy, ROT: arm_rot}
C['0:2210'] = {SY: lag(arm_sy, 2), ROT: lag(arm_rot, 3, 0.9, base=0.25, mirror=True)}

# Wrists flop against the arm's swing and wobble out.
wrist = [(0, 0), (22, -0.3), (28, 0.45), (34, -0.2), (40, 0.1), (46, 0), (54, -0.25), (60, 0),
         (63, 0.5), (69, -0.25), (75, 0.12), (81, 0), (D, 0)]
C['0:2052'] = {ROT: wrist}
C['0:2211'] = {ROT: lag(wrist, 3, 0.9, mirror=True)}

# Eye: squeeze in the wind-up, pop open on the launch, a happy squint at the
# top, wide open for the fall, blink on impact.
C['0:1048'] = {SY: [(0, 1), (12, 1), (21, 0.88), (24, 0.88, SNAP), (28, 1.03), (34, 1),
                    (56, 1, None), (59, 0.001), (62, 0.001, IO), (67, 1), (D, 1)]}
# The lid line comes on a frame before the eye is fully shut, as in idle's
# blink, so there's never a frame with no eye at all.
C['0:2040'] = {OPACITY: [(0, 0, HOLD), (58, 1, HOLD), (62, 0, HOLD), (D, 0, HOLD)]}
C['0:2401'] = {Y: [(0, 240), (14, 240), (21, 205), (26, 240), (34, 240), (40, 172), (48, 172),
                   (53, 240), (D, 240)]}

# Pupil and both shines look up on the way up and down at the ground before
# landing.
look = [(0, 0), (22, 2), (28, -16), (40, -12), (48, 12), (58, 10), (70, 0), (D, 0)]
for oid in ('0:786', '0:757', '0:749'):
    C[oid] = {Y: offset(look, REST[oid][Y])}

# The flame of fur trails the body: pushed down on the launch, flung up over
# the top, floating as he falls, whipping down on impact, then wobbling out.
flame = [(0, 0, 0), (14, 0, -6), (24, 0, -4), (31, -6, 22), (42, 4, -14), (54, 6, -18),
         (61, -4, 20), (67, 3, -10), (73, -2, 5), (79, 1, -2), (86, 0, 0), (D, 0, 0)]
for vid, (x, y, w) in flame_ids.items():
    C[vid] = {VX: [(f, x + dx * w) for f, dx, _ in flame], VY: [(f, y + dy * w) for f, _, dy in flame]}

# The shadow shrinks and fades with height and spreads on impact.
C['0:2451'] = {
    SX: [(0, 1), (22, 1.08), (24, 1.08, UP), (42, 0.62, DOWN), (58, 1.14, None), (66, 1), (D, 1)],
    SY: [(0, 1), (22, 1.08), (24, 1.08, UP), (42, 0.62, DOWN), (58, 1.14, None), (66, 1), (D, 1)],
    OPACITY: [(0, 0.22), (22, 0.24), (24, 0.24, UP), (42, 0.1, DOWN), (58, 0.27, None), (66, 0.22), (D, 0.22)],
}

# Mouth: the same happy smile as before, held through the air.
for vid, props in (('0:806', {VX: -30, VY: -11, 86: 1, 87: 25}),
                   ('0:807', {VX: 30, VY: -11, 84: 2.14159, 85: 25})):
    C[vid] = {p: [(0, REST[vid][p]), (18, REST[vid][p]), (28, v), (70, v), (80, REST[vid][p]), (D, REST[vid][p])]
              for p, v in props.items()}

# --- Write ------------------------------------------------------------------
lines = [f'        <LinearAnimation fps="60" duration="{D}" loopValue="oneShot" name="jump" id="{JUMP_ID}">']
for oid, rest in REST.items():
    lines.append(f'            <KeyedObject objectId="{oid}">')
    for prop, base in rest.items():
        frames = C.get(oid, {}).get(prop) or [(0, base), (D, base)]
        lines.append(f'                <KeyedProperty propertyKey="{prop}">')
        lines += ['                    ' + kf(*f) for f in frames]
        lines.append('                </KeyedProperty>')
    lines.append('            </KeyedObject>')
lines.append('        </LinearAnimation>')

unused = {(o, p) for o, ps in C.items() for p in ps} - {(o, p) for o, ps in REST.items() for p in ps}
assert not unused, f'keyed but missing from REST: {unused}'

s = s[:a] + '\n'.join(lines) + '\n' + s[b:]
open(OUT, 'w').write(s)
print(f'jump: {D} frames, {len(REST)} objects', file=sys.stderr)
