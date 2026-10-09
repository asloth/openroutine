"""Softer mascot: re-traces the fur from Sara's rounder reference (chunkier
tufts, blunt tips, a squat body), fitted around the unchanged eye, and adds the
happy squint she liked (a lid that rises from below the eye).

Optional `--shading` adds a soft top-left highlight and bottom shade over the
fur, plus a ground shadow, like the reference. `--preview-bg` puts a cream card
behind the artboard for stills only; never ship it.

usage: gen_soft.py SRC_SCENE REF_PNG OUT_SCENE [--shading] [--preview-bg]"""
import math
import re
import sys

import numpy as np
import potrace
from PIL import Image
from scipy import ndimage

src_scene, ref_png, out_scene = sys.argv[1:4]
SHADING = '--shading' in sys.argv
PREVIEW_BG = '--preview-bg' in sys.argv

X, Y, ROT, SX, SY, OPACITY = 13, 14, 15, 16, 17, 18
IO = (0.42, 0.0, 0.58, 1.0)

# Reference px -> hair_tuft local. Scaled so the silhouette spans the current
# height (curl tip 175 to ground 705 on the artboard) and centred on the eye.
K = 0.568
REF_EYE_X, REF_TOP = 622, 159
ART_EYE_X, ART_TOP = 297, 175
RIG_X, HEAD_Y = 293.81409, 482.0   # hair_tuft origin on the artboard at rest


def local(p, py=None):
    px, py = (p.x, p.y) if py is None else (p, py)
    return (ART_EYE_X - RIG_X + (px - REF_EYE_X) * K, ART_TOP + (py - REF_TOP) * K - HEAD_Y)


# ---------------------------------------------------------------- trace
im = np.array(Image.open(ref_png).convert('RGB')).astype(int)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
lum = (r + g + b) / 3
blue = ndimage.binary_opening((b > r + 40) & (lum < 150), iterations=2)
lab, n = ndimage.label(blue)
sizes = ndimage.sum(blue, lab, range(1, n + 1))
mask = ndimage.binary_fill_holes(lab == (1 + int(np.argmax(sizes))))
mask = ndimage.gaussian_filter(mask.astype(float), 3.0) > 0.5
H, W = mask.shape

path = potrace.Bitmap(mask).trace(turdsize=80, alphamax=1.2, opticurve=True, opttolerance=0.4)


def area(c):
    pts = [c.start_point] + [s.end_point for s in c.segments]
    return abs(sum(pts[i].x * pts[i + 1].y - pts[i + 1].x * pts[i].y for i in range(len(pts) - 1)))


def inside(c):
    pts = [c.start_point] + [s.end_point for s in c.segments]
    return all(2 < p.x < W - 2 and 2 < p.y < H - 2 for p in pts)


# potrace also outlines the canvas; the mascot is the largest curve inside it.
curve = max((c for c in path if inside(c)), key=area)
verts, cur = [], [local(curve.start_point), None, None]
for seg in curve.segments:
    if seg.is_corner:
        verts.append(cur)
        verts.append([local(seg.c), None, None])
        cur = [local(seg.end_point), None, None]
    else:
        cur[2] = local(seg.c1)
        verts.append(cur)
        cur = [local(seg.end_point), local(seg.c2), None]
verts[0][1] = cur[1]


def handle(pos, c):
    if c is None:
        return 0.0, 0.0
    dx, dy = c[0] - pos[0], c[1] - pos[1]
    return math.atan2(dy, dx), math.hypot(dx, dy)


vert_xml = []
for pos, cin, cout in verts:
    ir, idist = handle(pos, cin)
    orr, od = handle(pos, cout)
    vert_xml.append(f'<CubicDetachedVertex inRotation="{ir:.5f}" inDistance="{idist:.3f}" '
                    f'outRotation="{orr:.5f}" outDistance="{od:.3f}" x="{pos[0]:.3f}" y="{pos[1]:.3f}" name="Component"/>')
print(f'fur vertices: {len(vert_xml)}', file=sys.stderr)

s = open(src_scene).read()
tuft_open = s.index('name="hair_tuft" id="0:809">')
p_open = s.index('<PointsPath isClosed="true" name="Path">', tuft_open)
p_body = s.index('\n', p_open) + 1
p_close = s.index('                    </PointsPath>', p_body)
s = s[:p_body] + ''.join(' ' * 24 + v + '\n' for v in vert_xml) + s[p_close:]

# The tap listener's core ellipse draws in the body colour too; keep it well
# inside the new, rounder bottom edge.
s = s.replace('<Shape x="4.340" y="34.000" name="body" id="0:904">\n                    <Ellipse width="400" height="400" name="Path"/>',
              '<Shape x="4.340" y="20.000" name="body" id="0:904">\n                    <Ellipse width="370" height="370" name="Path"/>', 1)
assert 'width="370"' in s

ink = '<SolidColor colorValue="FF040626" name="Component"><DataBindContext sourcePathIds="0:14-0:2102" propertyKey="37"/></SolidColor>'
body = '<SolidColor colorValue="FF1B2052" name="Component"><DataBindContext sourcePathIds="0:14-0:2100" propertyKey="37"/></SolidColor>'

# ---------------------------------------------------------------- shading
if SHADING:
    # Same outline, painted with a colour-free gradient: white light from the
    # top left, a little shade toward the bottom. It recolours with any body.
    overlay = ('                <Shape x="0.000" y="0.000" name="fur_shading" id="0:2450">\n'
               '                    <PointsPath isClosed="true" name="Path">\n'
               + ''.join(' ' * 24 + v + '\n' for v in vert_xml) +
               '                    </PointsPath>\n'
               '                    <Fill name="Fill 1">\n'
               '                        <LinearGradient startX="-170" startY="-260" endX="90" endY="230" name="Gradient">\n'
               '                            <GradientStop colorValue="40FFFFFF" position="0" name="Light"/>\n'
               '                            <GradientStop colorValue="00FFFFFF" position="0.45" name="Clear"/>\n'
               '                            <GradientStop colorValue="00000000" position="0.6" name="Clear"/>\n'
               '                            <GradientStop colorValue="33000000" position="1" name="Shade"/>\n'
               '                        </LinearGradient>\n'
               '                    </Fill>\n'
               '                </Shape>\n')
    tuft_line = s.rfind('\n', 0, tuft_open) + 1
    s = s[:tuft_line] + overlay + s[tuft_line:]
    # Outside the silhouette, so it takes the accent (onSurfaceVariant in the
    # app), like the thought dots and the Z's: it has to read on the screen's
    # background, not against the fur.
    accent = ('<SolidColor colorValue="FF1B2052" name="Component">'
              '<DataBindContext sourcePathIds="0:14-0:2104" propertyKey="37"/></SolidColor>')
    shadow = (f'        <Shape x="{ART_EYE_X}" y="705" opacity="0.22" name="ground_shadow" id="0:2451">\n'
              '            <Ellipse width="330" height="26" name="Path"/>\n'
              f'            <Fill name="Fill 1">{accent}</Fill>\n'
              '        </Shape>\n')
else:
    shadow = ''

bg = ('        <Shape x="300" y="360" name="preview_bg">\n'
      '            <Rectangle width="600" height="720" name="Path"/>\n'
      '            <Fill name="Fill 1"><SolidColor colorValue="FFFBF7F1" name="Component"/></Fill>\n'
      '        </Shape>\n') if PREVIEW_BG else ''
style = '        <LayoutComponentStyle name="Layout Style" id="0:22"/>'
assert style in s
s = s.replace(style, shadow + bg + style, 1)

# ---------------------------------------------------------------- happy squint
CHEEK_LID, LID_MASK = '0:2401', '0:2404'
CHEEK_REST_Y, CHEEK_SQUINT_Y = 240.0, 140.0

ew = re.search(r'(                <Shape x="0.055450439" y="0.40164185" name="eye_white" id="0:795">\n'
               r'                    <PointsPath isClosed="true" name="Path" id="0:796">\n.*?</PointsPath>\n)', s, re.S).group(1)
lid_mask = re.sub(r' id="0:(79[6-9]|80[01])"', '', ew)
lid_mask = lid_mask.replace('name="eye_white" id="0:795">', f'scaleX="1.035" scaleY="1.035" name="lid_mask" id="{LID_MASK}">')
s = s.replace(ew, lid_mask + '                </Shape>\n' + ew, 1)

# The mouth moves above the eye in draw order, so the rising lid never hides it.
mouth_start = s.index('            <Shape x="4.34" y="133.5" name="mouth" id="0:804">')
mouth_end = s.index('            </Shape>\n', mouth_start) + len('            </Shape>\n')
mouth = s[mouth_start:mouth_end]
s = s[:mouth_start] + s[mouth_end:]
eye_anchor = '            <Node x="3.41" y="23.623287" name="eye_group" id="0:1048">'
lid = (mouth +
       f'            <Shape x="3.41" y="{CHEEK_REST_Y}" name="cheek_lid" id="{CHEEK_LID}">\n'
       '                <Ellipse width="340" height="170" name="Path"/>\n'
       f'                <Fill name="Fill 1">{body}</Fill>\n'
       f'                <Stroke thickness="8" name="Lid line">{ink}</Stroke>\n'
       f'                <ClippingShape sourceId="{LID_MASK}" name="Clip"/>\n'
       '            </Shape>\n')
s = s.replace(eye_anchor, lid + eye_anchor, 1)


def kf(frame, value, ease=IO):
    x1, y1, x2, y2 = ease
    return (f'<KeyFrameDouble value="{value:.4f}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/></KeyFrameDouble>')


def track(body_xml, obj, prop):
    k = re.search(rf'<KeyedObject objectId="{obj}">(.*?)</KeyedObject>', body_xml, re.S)
    p = k and re.search(rf'<KeyedProperty propertyKey="{prop}">(.*?)</KeyedProperty>', k.group(1), re.S)
    return p and sorted((int(f), float(v)) for v, f in re.findall(r'value="([^"]*)"[^>]*frame="(\d+)"', p.group(1)))


HAPPY = {'celebrate', 'step_done', 'jump', 'bounce'}


def rewrite(m):
    head, body_xml, tail = m.groups()
    name = re.search(r'name="([^"]*)"', head).group(1)
    duration = int(re.search(r'duration="([^"]*)"', head).group(1))
    frames = [(0, CHEEK_REST_Y), (duration, CHEEK_REST_Y)]
    if name in HAPPY:
        eye_sy = track(body_xml, '0:1048', SY)
        low = min(v for _, v in eye_sy)
        frames = [(f, CHEEK_REST_Y + (CHEEK_SQUINT_Y - CHEEK_REST_Y) * max(0.0, min(1.0, (1 - v) / (1 - low))))
                  for f, v in eye_sy]
        # The eye keeps its shape; the lid does the smiling.
        k = re.search(r'<KeyedObject objectId="0:1048">.*?</KeyedObject>', body_xml, re.S).group(0)
        p = re.search(rf'<KeyedProperty propertyKey="{SY}">.*?</KeyedProperty>', k, re.S).group(0)
        soft = re.sub(r'value="([^"]*)"', lambda v: f'value="{1 - (1 - float(v.group(1))) * 0.25:.4f}"', p)
        body_xml = body_xml.replace(k, k.replace(p, soft))
    body_xml += (f'            <KeyedObject objectId="{CHEEK_LID}">\n'
                 f'                <KeyedProperty propertyKey="{Y}">\n'
                 + ''.join('                    ' + kf(*f) + '\n' for f in frames) +
                 '                </KeyedProperty>\n            </KeyedObject>\n')
    return head + body_xml + tail


s = re.sub(r'(<LinearAnimation [^>]*>)(.*?)(\s*</LinearAnimation>)', rewrite, s, flags=re.S)
open(out_scene, 'w').write(s)
print('written', out_scene, file=sys.stderr)
