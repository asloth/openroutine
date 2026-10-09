"""Makes the mascot cuter without redrawing it: blush cheeks, a happy squint
that pushes up from below the eye, a curl on top that follows through on every
move, and a `pet` reaction (contented closed eye, wiggle, blush, a heart).

Reads build/scene.pre-cute.rml.bak, writes scene.rml."""
import math
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE / 'scene.pre-cute.rml.bak'
OUT = HERE.parent / 'scene.rml'

X, Y, ROT, SX, SY, OPACITY = 13, 14, 15, 16, 17, 18
VX, VY, VIN, VOUT = 24, 25, 84, 86
IO = (0.42, 0.0, 0.58, 1.0)
EO = (0.16, 0.7, 0.3, 1.0)

EYE_X, EYE_Y = 3.41, 23.6

# ---- ids for everything new
HAPPY_LID, CHEEK_LID, BLUSH = '0:2400', '0:2401', '0:2402'
HEART = '0:2403'
BLUSH_COLOR = '0:2105'
PET_ANIM, PET_TRIGGER, PET_STATE = '0:2440', '0:2441', '0:2442'
CURL_ID_BASE = 2410

BLUSH_REST, BLUSH_HAPPY = 0.6, 1.0
CHEEK_REST_Y, CHEEK_SQUINT_Y = 240.0, 140.0

# ---- the curl: bend the top of the fur outline about its base
PIVOT = (15.0, -205.0)
CURL_SPAN = 100.0


def weight(y):
    w = (PIVOT[1] - y) / CURL_SPAN
    return max(0.0, min(1.0, w)) ** 1.4


def kf(frame, value, ease=IO):
    if ease is None:
        return f'<KeyFrameDouble value="{value:.4f}" interpolationType="linear" frame="{frame}"/>'
    x1, y1, x2, y2 = ease
    return (f'<KeyFrameDouble value="{value:.4f}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/></KeyFrameDouble>')


def keyed(obj, props):
    """props: {propertyKey: [(frame, value[, ease]), ...]}"""
    out = [f'            <KeyedObject objectId="{obj}">']
    for prop, frames in props.items():
        out.append(f'                <KeyedProperty propertyKey="{prop}">')
        out += ['                    ' + kf(*f) for f in frames]
        out.append('                </KeyedProperty>')
    out.append('            </KeyedObject>')
    return '\n'.join(out) + '\n'


s = SRC.read_text()

# ---------------------------------------------------------------- structure
# Give the curl's vertices ids so they can be keyed.
tuft_open = s.index('name="hair_tuft" id="0:809">')
tuft_end = s.index('</PointsPath>', tuft_open)
tuft = s[tuft_open:tuft_end]
curl = []  # (id, x, y, inRot, outRot, weight)
counter = [0]


def tag(m):
    v = m.group(0)
    x = float(re.search(r' x="([^"]*)"', v).group(1))
    y = float(re.search(r' y="([^"]*)"', v).group(1))
    w = weight(y)
    if w <= 0:
        return v
    vid = f'0:{CURL_ID_BASE + counter[0]}'
    counter[0] += 1
    curl.append((vid, x, y,
                 float(re.search(r'inRotation="([^"]*)"', v).group(1)),
                 float(re.search(r'outRotation="([^"]*)"', v).group(1)), w))
    return v.replace(' name="Component"/>', f' name="Component" id="{vid}"/>')


tuft = re.sub(r'<CubicDetachedVertex [^>]*/>', tag, tuft)
s = s[:tuft_open] + tuft + s[tuft_end:]
assert counter[0] < 30, counter[0]
print(f'curl vertices: {len(curl)}', file=sys.stderr)

# Pull the mouth above the eye so a rising cheek never hides it.
mouth_start = s.index('            <Shape x="4.34" y="133.5" name="mouth" id="0:804">')
mouth_end = s.index('            </Shape>\n', mouth_start) + len('            </Shape>\n')
mouth = s[mouth_start:mouth_end]
s = s[:mouth_start] + s[mouth_end:]

ink = '<SolidColor colorValue="FF040626" name="Component"><DataBindContext sourcePathIds="0:14-0:2102" propertyKey="37"/></SolidColor>'
body = '<SolidColor colorValue="FF1B2052" name="Component"><DataBindContext sourcePathIds="0:14-0:2100" propertyKey="37"/></SolidColor>'
accent = '<SolidColor colorValue="FF1B2052" name="Component"><DataBindContext sourcePathIds="0:14-0:2104" propertyKey="37"/></SolidColor>'


def blush_cheek(x):
    return f'''                <Shape x="{x}" y="0" scaleY="0.62" name="cheek">
                    <Ellipse width="96" height="96" name="Path"/>
                    <Fill name="Fill 1">
                        <RadialGradient startX="0" startY="0" endX="48" endY="0" name="Gradient">
                            <GradientStop colorValue="FFFF9AB8" position="0" name="Inner"><DataBindContext sourcePathIds="0:14-{BLUSH_COLOR}" propertyKey="38"/></GradientStop>
                            <GradientStop colorValue="99FF9AB8" position="0.55" name="Mid"/>
                            <GradientStop colorValue="00FF9AB8" position="1" name="Outer"/>
                        </RadialGradient>
                    </Fill>
                </Shape>
'''


new_face = f'''            <Shape x="{EYE_X}" y="{EYE_Y}" opacity="0" name="happy_lid" id="{HAPPY_LID}">
                <PointsPath isClosed="false" name="Path">
                    <CubicDetachedVertex outRotation="-1.0" outDistance="84" x="-108" y="34" name="Component"/>
                    <CubicDetachedVertex inRotation="-2.1416" inDistance="84" x="108" y="34" name="Component"/>
                </PointsPath>
                <Stroke thickness="20" cap="round" name="Stroke 1">
                    {ink}
                </Stroke>
            </Shape>
'''
new_under = mouth + f'''            <Node x="{EYE_X}" y="118" opacity="{BLUSH_REST}" name="blush" id="{BLUSH}">
{blush_cheek(-168)}{blush_cheek(170)}            </Node>
            <Shape x="{EYE_X}" y="{CHEEK_REST_Y}" name="cheek_lid" id="{CHEEK_LID}">
                <Ellipse width="340" height="170" name="Path"/>
                <Fill name="Fill 1">{body}</Fill>
                <Stroke thickness="8" name="Lid line">{ink}</Stroke>
                <ClippingShape sourceId="0:795" name="Clip"/>
            </Shape>
'''
heart = f'''            <Node x="178" y="-200" opacity="0" name="heart" id="{HEART}">
                <Shape x="-10" y="-6" name="lobe"><Ellipse width="26" height="26" name="Path"/><Fill name="Fill 1">{accent}</Fill></Shape>
                <Shape x="10" y="-6" name="lobe"><Ellipse width="26" height="26" name="Path"/><Fill name="Fill 1">{accent}</Fill></Shape>
                <Shape y="4" rotation="0.7854" name="point"><Rectangle width="26" height="26" cornerRadiusTL="0" name="Path"/><Fill name="Fill 1">{accent}</Fill></Shape>
            </Node>
'''

eyelid_anchor = '            <Shape x="3.41" y="24" opacity="0" name="eyelid" id="0:2040">'
assert eyelid_anchor in s
s = s.replace(eyelid_anchor, heart + new_face + eyelid_anchor, 1)
eye_anchor = '            <Node x="3.41" y="23.623287" name="eye_group" id="0:1048">'
assert eye_anchor in s
s = s.replace(eye_anchor, new_under + eye_anchor, 1)

# The lid clips to a paintless copy of the eye, a little larger, so it covers
# the eye white's own stroke instead of leaving a cream hairline around it.
ew = re.search(r'(                <Shape x="0.055450439" y="0.40164185" name="eye_white" id="0:795">\n'
               r'                    <PointsPath isClosed="true" name="Path" id="0:796">\n.*?</PointsPath>\n)', s, re.S).group(1)
mask = re.sub(r' id="0:(79[6-9]|80[01])"', '', ew)
mask = mask.replace('name="eye_white" id="0:795">', 'scaleX="1.035" scaleY="1.035" name="lid_mask" id="0:2404">')
mask += '                </Shape>\n'
s = s.replace(ew, mask + ew, 1)
s = s.replace('<ClippingShape sourceId="0:795" name="Clip"/>', '<ClippingShape sourceId="0:2404" name="Clip"/>')

# View model: a blush colour beside the others.
s = s.replace('        <ViewModelPropertyColor name="accentColor" id="0:2104"/>\n',
              '        <ViewModelPropertyColor name="accentColor" id="0:2104"/>\n'
              f'        <ViewModelPropertyColor name="blushColor" id="{BLUSH_COLOR}"/>\n'
              f'        <ViewModelPropertyTrigger name="pet" id="{PET_TRIGGER}"/>\n', 1)
s = s.replace('            <ViewModelInstanceColor propertyValue="FF1B2052" viewModelPropertyId="0:2104"/>\n',
              '            <ViewModelInstanceColor propertyValue="FF1B2052" viewModelPropertyId="0:2104"/>\n'
              f'            <ViewModelInstanceColor propertyValue="FFFF9AB8" viewModelPropertyId="{BLUSH_COLOR}"/>\n'
              f'            <ViewModelInstanceTrigger viewModelPropertyId="{PET_TRIGGER}"/>\n', 1)
assert BLUSH_COLOR in s.split('<ViewModel ')[1]

# ---------------------------------------------------------------- motion helpers


def track(body_xml, obj, prop):
    k = re.search(rf'<KeyedObject objectId="{obj}">(.*?)</KeyedObject>', body_xml, re.S)
    if not k:
        return None
    p = re.search(rf'<KeyedProperty propertyKey="{prop}">(.*?)</KeyedProperty>', k.group(1), re.S)
    if not p:
        return None
    return sorted((int(f), float(v)) for v, f in
                  re.findall(r'value="([^"]*)"[^>]*frame="(\d+)"', p.group(1)))


def sample(keys, frame, default):
    if not keys:
        return default
    if frame <= keys[0][0]:
        return keys[0][1]
    for (f0, v0), (f1, v1) in zip(keys, keys[1:]):
        if f0 <= frame <= f1:
            return v0 if f1 == f0 else v0 + (v1 - v0) * (frame - f0) / (f1 - f0)
    return keys[-1][1]


def spring_curl(body_xml, duration):
    """The curl's bend per frame: a damped spring pushed by the head's
    vertical acceleration and the body's angular acceleration."""
    rig_y, pose_y, rot, rig_sy = (track(body_xml, '0:2001', Y), track(body_xml, '0:2200', Y),
                                  track(body_xml, '0:748', ROT), track(body_xml, '0:2001', SY))
    head = [sample(rig_y, f, 706) + sample(pose_y, f, 58) - 300 * sample(rig_sy, f, 1)
            for f in range(duration + 3)]
    ang = [sample(rot, f, 0) for f in range(duration + 3)]
    omega, zeta = 2 * math.pi * 2.6 / 60, 0.22
    k, c = omega * omega, 2 * zeta * omega
    theta, vel, out = 0.0, 0.0, []
    for f in range(duration + 1):
        ay = head[f + 2] - 2 * head[f + 1] + head[f]
        ar = ang[f + 2] - 2 * ang[f + 1] + ang[f]
        acc = -k * theta - c * vel + 0.045 * ay - 6.0 * ar
        vel += acc
        theta += vel
        theta = max(-0.38, min(0.38, theta))
        out.append(theta)
    # Settle into rest over the last frames so the loop back to idle is clean.
    fade = min(18, duration // 3)
    for i in range(fade):
        out[duration - i] *= i / fade
    return out


def curl_keys(thetas, duration, step=2):
    frames = list(range(0, duration, step)) + [duration]
    objs = ''
    for vid, x, y, a_in, a_out, w in curl:
        xs, ys, ins, outs = [], [], [], []
        for f in frames:
            t = thetas[f] * w
            dx, dy = x - PIVOT[0], y - PIVOT[1]
            cos, sin = math.cos(t), math.sin(t)
            xs.append((f, PIVOT[0] + dx * cos - dy * sin, None))
            ys.append((f, PIVOT[1] + dx * sin + dy * cos, None))
            ins.append((f, a_in + t, None))
            outs.append((f, a_out + t, None))
        objs += keyed(vid, {VX: xs, VY: ys, VIN: ins, VOUT: outs})
    return objs


def rest_keys(duration, extra=None):
    """Pins every new property to rest, except those `extra` animates."""
    extra = extra or {}
    rest = {
        HAPPY_LID: {OPACITY: 0},
        CHEEK_LID: {Y: CHEEK_REST_Y},
        BLUSH: {OPACITY: BLUSH_REST},
        HEART: {OPACITY: 0, Y: -200, SX: 1.8, SY: 1.8},
    }
    xml = ''
    for obj, props in rest.items():
        xml += keyed(obj, {p: extra.get(obj, {}).get(p) or [(0, v), (duration, v)]
                           for p, v in props.items()})
    return xml


# ---------------------------------------------------------------- existing animations
HAPPY = {'celebrate', 'step_done', 'jump', 'bounce'}
SPRING = {'celebrate', 'wave', 'fall_asleep', 'tap', 'step_done', 'skip_nod', 'run', 'jump', 'bounce'}


def rewrite(m):
    head, body_xml, tail = m.group(1), m.group(2), m.group(3)
    name = re.search(r'name="([^"]*)"', head).group(1)
    duration = int(re.search(r'duration="([^"]*)"', head).group(1))
    extra = {}
    if name in HAPPY:
        eye_sy = track(body_xml, '0:1048', SY)
        low = min(v for _, v in eye_sy)
        happy = [(f, max(0.0, min(1.0, (1 - v) / (1 - low)))) for f, v in eye_sy]
        extra = {
            CHEEK_LID: {Y: [(f, CHEEK_REST_Y + (CHEEK_SQUINT_Y - CHEEK_REST_Y) * h) for f, h in happy]},
            BLUSH: {OPACITY: [(f, BLUSH_REST + (BLUSH_HAPPY - BLUSH_REST) * h) for f, h in happy]},
        }

        # The eye keeps its shape; the cheek does the squinting now.
        def soften(km):
            v = float(km.group(1))
            return km.group(0).replace(f'value="{km.group(1)}"', f'value="{1 - (1 - v) * 0.25:.4f}"')
        k = re.search(r'(<KeyedObject objectId="0:1048">.*?</KeyedObject>)', body_xml, re.S)
        block = k.group(1)
        p = re.search(rf'(<KeyedProperty propertyKey="{SY}">.*?</KeyedProperty>)', block, re.S)
        block2 = block.replace(p.group(1), re.sub(r'value="([^"]*)"', soften, p.group(1)))
        body_xml = body_xml.replace(block, block2)
    body_xml += rest_keys(duration, extra)
    thetas = spring_curl(body_xml, duration) if name in SPRING else [0.0] * (duration + 1)
    body_xml += curl_keys(thetas, duration, step=2 if name in SPRING else duration)
    return head + body_xml + tail


s = re.sub(r'(<LinearAnimation [^>]*>)(.*?)(\s*</LinearAnimation>)', rewrite, s, flags=re.S)

# ---------------------------------------------------------------- pet
PET = 150
wig = [(0, 0), (14, 0)]
for i, f in enumerate(range(22, 104, 16)):
    wig.append((f, 0.07 if i % 2 == 0 else -0.07))
wig += [(116, 0), (PET, 0)]
pet_extra = {
    HAPPY_LID: {OPACITY: [(0, 0), (8, 0, None), (14, 1), (124, 1, None), (132, 0), (PET, 0)]},
    BLUSH: {OPACITY: [(0, BLUSH_REST), (16, BLUSH_HAPPY), (120, BLUSH_HAPPY), (140, BLUSH_REST), (PET, BLUSH_REST)]},
    HEART: {OPACITY: [(0, 0), (40, 0, None), (50, 1), (96, 1), (118, 0), (PET, 0)],
            Y: [(0, -190), (40, -190, EO), (118, -290), (PET, -200)],
            SX: [(0, 0.6), (40, 0.6, EO), (56, 2.1), (66, 1.8), (PET, 1.8)],
            SY: [(0, 0.6), (40, 0.6, EO), (56, 2.1), (66, 1.8), (PET, 1.8)]},
}
pet_body = keyed('0:748', {ROT: wig})
pet_body += keyed('0:2001', {
    Y: [(0, 706), (PET, 706)],
    SY: [(0, 1), (12, 0.94), (26, 1.02), (112, 1.0), (124, 0.97), (138, 1), (PET, 1)],
    SX: [(0, 1), (12, 1.05), (26, 0.99), (112, 1.0), (124, 1.02), (138, 1), (PET, 1)],
})
pet_body += keyed('0:1048', {OPACITY: [(0, 1), (8, 1, None), (12, 0), (126, 0, None), (130, 1), (PET, 1)],
                             SX: [(0, 1), (PET, 1)], SY: [(0, 1), (PET, 1)]})
pet_body += keyed('0:2040', {OPACITY: [(0, 0), (PET, 0)]})
pet_body += keyed('0:806', {VX: [(0, -24.5), (12, -24.5), (22, -30), (118, -30), (130, -24.5), (PET, -24.5)],
                            VY: [(0, -7), (12, -7), (22, -11), (118, -11), (130, -7), (PET, -7)]})
pet_body += keyed('0:807', {VX: [(0, 24.5), (12, 24.5), (22, 30), (118, 30), (130, 24.5), (PET, 24.5)],
                            VY: [(0, -7), (12, -7), (22, -11), (118, -11), (130, -7), (PET, -7)]})
pet_body += rest_keys(PET, pet_extra)
pet_body += curl_keys(spring_curl(pet_body, PET), PET)
pet_anim = (f'        <LinearAnimation fps="60" duration="{PET}" loopValue="oneShot" name="pet" id="{PET_ANIM}">\n'
            + pet_body + '        </LinearAnimation>\n')

sm = '        <StateMachine name="State Machine 1" id="0:24">'
s = s.replace(sm, pet_anim + sm, 1)

idle_open = '<AnimationState x="160" animationId="0:1038" id="0:29">'
i = s.index(idle_open)
j = s.index('                </AnimationState>', i)
s = s[:j] + f'''                    <StateTransition stateToId="{PET_STATE}" duration="120">
                        <TransitionViewModelCondition>
                            <TransitionPropertyViewModelComparator>
                                <BindablePropertyTrigger>
                                    <DataBindContext sourcePathIds="0:14-{PET_TRIGGER}" propertyKey="686"/>
                                </BindablePropertyTrigger>
                            </TransitionPropertyViewModelComparator>
                            <TransitionValueTriggerComparator/>
                        </TransitionViewModelCondition>
                    </StateTransition>
''' + s[j:]
end_layer = '            </StateMachineLayer>'
s = s.replace(end_layer, f'''                <AnimationState x="400" y="1350" animationId="{PET_ANIM}" reset="true" id="{PET_STATE}">
                    <StateTransition stateToId="0:29" duration="200" enableExitTime="true" exitTimeIsPercetange="true" exitTime="100">
                    </StateTransition>
                </AnimationState>
''' + end_layer, 1)

OUT.write_text(s)
print('written', OUT, file=sys.stderr)
