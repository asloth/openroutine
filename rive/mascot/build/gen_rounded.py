import math, re, sys
import numpy as np
from PIL import Image
from scipy import ndimage
import potrace

SRC = '/home/sabera/Downloads/rounded.png'
SCENE = '/home/sabera/Projects/openroutine/rive/mascot/build/scene.pre-rounded.rml.bak'
OUT = '/home/sabera/Projects/openroutine/rive/mascot/scene.rml'

S = 0.62          # image px -> artboard px
CX, GROUND = 569, 1200
def L(X, Y):      # image -> character-local coords
    return ((X - CX) * S + 6.2, (Y - GROUND) * S + 298.5)

BODY_DROP = 58    # rest pose: body sits on the ground, feet tucked
LEGS_HIDE = -66   # rest pose: legs slid up behind the body

im = np.array(Image.open(SRC).convert('RGB')).astype(int)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
dark = (r < 40) & (g < 40) & (b < 40)          # background
H, W = dark.shape
# character = everything not background, holes filled (eye, mouth)
char = ndimage.binary_fill_holes(~dark)
char = ndimage.binary_opening(char, iterations=2)
lab, n = ndimage.label(char)
sizes = ndimage.sum(char, lab, range(1, n + 1))
char = lab == (1 + int(np.argmax(sizes)))

yy, xx = np.mgrid[0:H, 0:W]
body = char & (yy < 1072)
u = (xx - 568.5) / 150.0
cap = (np.abs(u) <= 1) & (yy >= 1072) & (yy <= 1072 + 34 * (1 - u ** 2))
body = body | cap

def legmask(x0, x1):
    m = char & (yy >= 1100) & (xx >= x0) & (xx < x1)
    # extend the leg up behind the belly so a stretch never shows a seam
    cols = np.nonzero(char[1115, x0:x1])[0] + x0
    m |= (yy >= 990) & (yy < 1116) & (xx >= cols.min()) & (xx <= cols.max())
    return m

leg_l_img = legmask(300, 569)   # screen-left leg  -> foot_right
leg_r_img = legmask(569, 850)   # screen-right leg -> foot_left

def smooth(m, sigma=2.5):
    return ndimage.gaussian_filter(m.astype(float), sigma) > 0.5

def trace(m, origin):
    ox, oy = origin
    p = potrace.Bitmap(smooth(m)).trace(turdsize=50, alphamax=1.1, opticurve=True, opttolerance=0.35)
    curves = [c for c in p if not (c.start_point.x <= 0.5 or c.start_point.y <= 0.5 or c.start_point.x >= W - 0.5 or c.start_point.y >= H - 0.5)]
    def area(c):
        pts = [c.start_point] + [s.end_point for s in c.segments]
        return abs(sum(pts[i].x * pts[i+1].y - pts[i+1].x * pts[i].y for i in range(len(pts) - 1)))
    c = max(curves, key=area)
    def P(pt):
        x, y = L(pt.x, pt.y)
        return (x - ox, y - oy)
    verts = []  # [pos, in, out]
    cur = [P(c.start_point), None, None]
    for s in c.segments:
        if s.is_corner:
            verts.append(cur)
            verts.append([P(s.c), None, None])
            cur = [P(s.end_point), None, None]
        else:
            cur[2] = P(s.c1)
            verts.append(cur)
            cur = [P(s.end_point), P(s.c2), None]
    # closing: last end == start
    verts[0][1] = cur[1]
    lines = []
    for pos, cin, cout in verts:
        def rd(c):
            if c is None: return 0.0, 0.0
            dx, dy = c[0] - pos[0], c[1] - pos[1]
            return math.atan2(dy, dx), math.hypot(dx, dy)
        ir, idist = rd(cin); orr, od = rd(cout)
        lines.append(f'<CubicDetachedVertex inRotation="{ir:.5f}" inDistance="{idist:.3f}" outRotation="{orr:.5f}" outDistance="{od:.3f}" x="{pos[0]:.3f}" y="{pos[1]:.3f}" name="Component"/>')
    return lines, len(verts)

BODY_FILL = '<Fill name="Fill 1"><SolidColor colorValue="FF1B2052" name="Component"><DataBindContext sourcePathIds="0:14-0:2100" propertyKey="37"/></SolidColor></Fill>'

def shape(name, sid, x, y, verts, ind):
    pad = ' ' * ind
    out = [f'{pad}<Shape x="{x:.3f}" y="{y:.3f}" name="{name}" id="{sid}">',
           f'{pad}    <PointsPath isClosed="true" name="Path">']
    out += [pad + '        ' + v for v in verts]
    out += [f'{pad}    </PointsPath>', f'{pad}    {BODY_FILL}', f'{pad}</Shape>']
    return '\n'.join(out)

src = open(SCENE).read()

def replace_block(text, marker, new):
    i = text.index(marker)
    start = text.rfind('\n', 0, i) + 1
    ind = len(text[start:i]) - len(text[start:i].lstrip())
    # find matching </Shape>
    depth, j = 0, start
    for m in re.finditer(r'<(/?)Shape\b[^>]*?(/?)>', text[start:]):
        if m.group(1): depth -= 1
        elif not m.group(2): depth += 1
        if depth == 0:
            end = start + m.end(); break
    return text[:start] + new(ind) + text[end:]

# fur + body silhouette: path coords == character-local (head y=16.5)
fur, nf = trace(body, (0, 16.5))
src = replace_block(src, 'name="hair_tuft" id="0:809"', lambda ind: shape('hair_tuft', '0:809', 0, 0, fur, ind))
# body: plain core ellipse kept as a reliable hit area for the tap listener
ex, ey = L(566, 800)
src = replace_block(src, 'name="body" id="0:904"', lambda ind: '\n'.join([
    f'{" "*ind}<Shape x="{ex:.3f}" y="{ey - 16.5:.3f}" name="body" id="0:904">',
    f'{" "*ind}    <Ellipse width="400" height="400" name="Path"/>',
    f'{" "*ind}    {BODY_FILL}', f'{" "*ind}</Shape>']))

# feet: shape origin at the hip so the celebrate kicks pivot there
hip_r = L(657, 1110); hip_l = L(482, 1110)
fr, nr = trace(leg_r_img, hip_r)
fl, nl = trace(leg_l_img, hip_l)
src = replace_block(src, 'name="foot_left" id="0:917"', lambda ind: shape('foot_left', '0:917', *hip_r, fr, ind))
src = replace_block(src, 'name="foot_right" id="0:940"', lambda ind: shape('foot_right', '0:940', *hip_l, fl, ind))
print('vertices fur/footL/footR', nf, nr, nl, file=sys.stderr)

# face placement
eye_x, _ = L(564.5, 758.5)
src = src.replace('<Shape x="-13.4" y="24" opacity="0" name="eyelid"', f'<Shape x="{eye_x:.2f}" y="24" opacity="0" name="eyelid"')
src = src.replace('<Node x="-13.430023" y="23.623287" name="eye_group"', f'<Node x="{eye_x:.2f}" y="23.623287" name="eye_group"')
mx, _ = L(566, 1003)
src = src.replace('<Shape x="-13.5" y="120.5" name="mouth"', f'<Shape x="{mx:.2f}" y="133.5" name="mouth"')

# arms: right arm tucked just inside the fur, plus a mirrored left arm for celebrate
arm_i = src.index('<Node x="170" y="30" rotation="0.25" scaleY="0.001" name="arm" id="0:2050">')
arm_s = src.rfind('\n', 0, arm_i) + 1
arm_e = src.index('\n', src.index('<Shape x="', arm_i + 10) if False else arm_i)
# find end of arm node: the line before foot_left shape
foot_i = src.index('name="foot_left" id="0:917"')
foot_s = src.rfind('\n', 0, foot_i) + 1
arm_block = src[arm_s:foot_s]
ARM_X = 165
right = arm_block.replace('x="170" y="30"', f'x="{ARM_X}" y="30"')
left = (arm_block.replace('<Node x="170" y="30" rotation="0.25" scaleY="0.001" name="arm" id="0:2050">',
                          f'<Node x="{2*eye_x - ARM_X:.1f}" y="30" rotation="-0.25" scaleX="-1" scaleY="0.001" name="arm_left" id="0:2210">')
             .replace('name="wrist" id="0:2052"', 'name="wrist_left" id="0:2211"'))
src = src[:arm_s] + right + left + src[foot_s:]

# hierarchy: character > pose (everything but the legs) + legs (feet)
ch = '<Node y="-298.50327" name="character" id="0:748">\n'
src = src.replace(ch, ch + f'            <Node y="{BODY_DROP}" name="pose" id="0:2200">\n')
foot_i = src.index('name="foot_left" id="0:917"')
foot_s = src.rfind('\n', 0, foot_i) + 1
src = src[:foot_s] + f'            </Node>\n            <Node y="{LEGS_HIDE}" name="legs" id="0:2201">\n' + src[foot_s:]
fr_i = src.index('name="foot_right" id="0:940"')
fr_end = src.index('</Shape>', fr_i) + len('</Shape>\n')
src = src[:fr_end] + '            </Node>\n' + src[fr_end:]

# ---- animation keys
EO = (0.16, 0.7, 0.3, 1.0)      # snappy ease-out
IO = (0.42, 0.0, 0.58, 1.0)
def kf(frame, value, ease=IO):
    if ease is None:
        return f'<KeyFrameDouble value="{value}" interpolationType="linear" frame="{frame}"/>'
    return (f'<KeyFrameDouble value="{value}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{ease[0]}" y1="{ease[1]}" x2="{ease[2]}" y2="{ease[3]}"/></KeyFrameDouble>')
def keyed(obj, props):
    out = [f'            <KeyedObject objectId="{obj}">']
    for pk, frames in props.items():
        out.append(f'                <KeyedProperty propertyKey="{pk}">')
        out += ['                    ' + kf(*f) for f in frames]
        out.append('                </KeyedProperty>')
    out.append('            </KeyedObject>')
    return '\n'.join(out) + '\n'

Y, ROT, SY = 14, 15, 17
def add_keys(anim, block):
    i = src_holder[0].index(f'name="{anim}"')
    j = src_holder[0].index('</LinearAnimation>', i)
    src_holder[0] = src_holder[0][:j] + block + '        ' + src_holder[0][j:]
src_holder = [src]

durations = {m.group(2): int(m.group(1)) for m in re.finditer(r'duration="(\d+)" loopValue="\w+" name="(\w+)"', src)}

for anim in ('idle', 'thinking', 'fall_asleep', 'sleep', 'tap'):
    d = durations[anim]
    add_keys(anim,
        keyed('0:2200', {Y: [(0, BODY_DROP), (d, BODY_DROP)]}) +
        keyed('0:2201', {Y: [(0, LEGS_HIDE), (d, LEGS_HIDE)]}) +
        keyed('0:2050', {SY: [(0, 0.001), (d, 0.001)]}) +
        keyed('0:2210', {SY: [(0, 0.001), (d, 0.001)]}))

def pop_feet(out_at, tuck_at, tuck_len=16):
    return (keyed('0:2200', {Y: [(0, BODY_DROP), (out_at, BODY_DROP, EO), (out_at + 8, -4), (out_at + 12, 0),
                                  (tuck_at, 0), (tuck_at + tuck_len, BODY_DROP)]}) +
            keyed('0:2201', {Y: [(0, LEGS_HIDE), (out_at, LEGS_HIDE, EO), (out_at + 8, 4), (out_at + 12, 0),
                                  (tuck_at, 0), (tuck_at + tuck_len, LEGS_HIDE)]}))

# celebrate: feet out before the first take-off at frame 12, tucked after the settle
arm_up = [(0, 0.001), (4, 0.001, EO), (16, 1.06), (22, 1), (94, 1, (0.5, 0.0, 0.75, 0.3)), (106, 0.001, None), (120, 0.001)]
rot_r = [(0, 0.25), (16, 0.3), (36, 0.46), (54, 0.18), (84, 0.42), (96, 0.25), (120, 0.25)]
add_keys('celebrate',
    pop_feet(0, 102) +
    keyed('0:2050', {SY: arm_up, ROT: rot_r}) +
    keyed('0:2210', {SY: arm_up, ROT: [(f[0], -f[1]) + f[2:] for f in rot_r]}))
# wave: feet out as the arm pops, tucked once the arm is away
add_keys('wave',
    pop_feet(0, 110) +
    keyed('0:2210', {SY: [(0, 0.001), (durations['wave'], 0.001)]}))

open(OUT, 'w').write(src_holder[0])
print('written', file=sys.stderr)
