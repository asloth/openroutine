"""Gives Ochi a coffee break for long steps.

Adds a mug (with a paw on the handle and two steam wisps) to the front of
`pose`, a `hasCoffee` boolean and a `sip` trigger on the `Mascot` view model,
and three states: `coffee_in` brings the mug up, `coffee_hold` holds it while
the steam drifts, and `coffee_sip` lifts it to the mouth for a happy sip.

Every existing animation gets the mug pinned hidden, so a reaction fired while
Ochi holds the cup tucks it away, and idle never inherits a visible mug.

Usage: gen_coffee.py SRC OUT
"""
import re
import sys

SRC, OUT = sys.argv[1], sys.argv[2]
s = open(SRC).read()

X, Y, ROT, SX, SY, OPACITY = 13, 14, 15, 16, 17, 18
IO = (0.42, 0.0, 0.58, 1.0)
EO = (0.16, 0.7, 0.3, 1.0)
BACK = (0.34, 1.4, 0.64, 1.0)  # a little overshoot

BODY, FACE, INK = '0:2100', '0:2101', '0:2102'

# Mug and steam ids.
MUG, CUP, RIM, SURFACE, HANDLE, PAW = '0:2700', '0:2701', '0:2702', '0:2703', '0:2704', '0:2705'
STEAM, WISP_A, WISP_B = '0:2710', '0:2711', '0:2712'
HAS_COFFEE, SIP = '0:2730', '0:2731'
A_IN, A_HOLD, A_SIP = '0:2720', '0:2721', '0:2722'
S_IN, S_HOLD, S_SIP = '0:2725', '0:2726', '0:2727'

MUG_X, MUG_Y = 112, 150
K = 1.55  # the mug's held scale
WISP_Y = -58

# Every property any animation keys, at rest: the idle's first frame wins,
# then the reactions'. A state that leaves one of these unkeyed would inherit
# whatever the previous state left behind.
REST = {}
anims = {m.group(1): m.group(2) for m in re.finditer(
    r'<LinearAnimation [^>]*name="([^"]+)" id="[^"]+">(.*?)</LinearAnimation>', s, re.S)}
for name in ['idle', 'step_done', 'skip_nod', 'jump', 'celebrate', 'wave', 'run', 'bounce', 'tap']:
    for ob in re.finditer(r'<KeyedObject objectId="([^"]+)">(.*?)</KeyedObject>', anims[name], re.S):
        for kp in re.finditer(r'<KeyedProperty propertyKey="(\d+)">(.*?)</KeyedProperty>', ob.group(2), re.S):
            first = float(re.search(r'value="([^"]+)"', kp.group(2)).group(1))
            REST.setdefault(ob.group(1), {}).setdefault(int(kp.group(1)), first)

# The mug at rest is hidden. These are the values every old animation pins.
MUG_REST = {
    MUG: {X: MUG_X, Y: MUG_Y + 30, ROT: 0, SX: 0.6 * K, SY: 0.6 * K, OPACITY: 0},
    WISP_A: {Y: WISP_Y, OPACITY: 0},
    WISP_B: {Y: WISP_Y, OPACITY: 0},
}
ALL = {**REST, **MUG_REST}


def kf(frame, value, ease=IO):
    v = round(value, 5)
    if ease is None:
        return f'<KeyFrameDouble value="{v}" interpolationType="linear" frame="{frame}"/>'
    x1, y1, x2, y2 = ease
    return (f'<KeyFrameDouble value="{v}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/></KeyFrameDouble>')


def keyed(table, duration, custom, indent='            '):
    out = []
    for obj, rest in table.items():
        out.append(f'{indent}<KeyedObject objectId="{obj}">')
        for prop, base in rest.items():
            frames = custom.get(obj, {}).get(prop) or [(0, base), (duration, base)]
            out.append(f'{indent}    <KeyedProperty propertyKey="{prop}">')
            out += [f'{indent}        ' + kf(*f) for f in frames]
            out.append(f'{indent}    </KeyedProperty>')
        out.append(f'{indent}</KeyedObject>')
    return out


def animation(name, anim_id, duration, custom, loop='oneShot'):
    out = [f'        <LinearAnimation fps="60" duration="{duration}" loopValue="{loop}" name="{name}" id="{anim_id}">']
    out += keyed(ALL, duration, custom)
    out.append('        </LinearAnimation>')
    return '\n'.join(out) + '\n'


# ---------------------------------------------------------------- the art

def fill(prop):
    return (f'<Fill name="Fill 1"><SolidColor colorValue="FFFDF5E7" name="Component">'
            f'<DataBindContext sourcePathIds="0:14-{prop}" propertyKey="37"/></SolidColor></Fill>')


def stroke(prop, thickness):
    return (f'<Stroke thickness="{thickness}" cap="round" join="round" name="Stroke 1">'
            f'<SolidColor colorValue="FF040626" name="Component">'
            f'<DataBindContext sourcePathIds="0:14-{prop}" propertyKey="37"/></SolidColor></Stroke>')


def wisp(wid, x, phase):
    # A soft S rising out of the cup.
    d = 1 if phase else -1
    return f'''                <Shape x="{x}" y="{WISP_Y}" opacity="0" name="wisp" id="{wid}">
                    <PointsPath isClosed="false" name="Path">
                        <CubicDetachedVertex outRotation="{-1.57 + 0.6 * d}" outDistance="12" x="0" y="18" name="Component"/>
                        <CubicMirroredVertex rotation="-1.5708" distance="10" x="{8 * d}" y="0" name="Component"/>
                        <CubicDetachedVertex inRotation="{1.57 + 0.6 * d}" inDistance="12" x="0" y="-18" name="Component"/>
                    </PointsPath>
                    {stroke(FACE, 8)}
                </Shape>
'''


MUG_XML = f'''            <Node x="{MUG_X}" y="{MUG_Y + 30}" scaleX="{0.6 * K}" scaleY="{0.6 * K}" opacity="0" name="coffee" id="{MUG}">
                <Shape x="40" y="12" rotation="-0.4" name="paw" id="{PAW}">
                    <Ellipse width="30" height="40" name="Path"/>
                    {fill(BODY)}
                </Shape>
                <Shape y="-33" name="coffee_surface" id="{SURFACE}">
                    <Ellipse width="48" height="9" name="Path"/>
                    {fill(INK)}
                </Shape>
                <Shape y="-33" name="rim" id="{RIM}">
                    <Ellipse width="62" height="15" name="Path"/>
                    {fill(FACE)}
                    {stroke(INK, 5)}
                </Shape>
                <Shape name="cup" id="{CUP}">
                    <Rectangle width="62" height="68" linkCornerRadius="false" cornerRadiusTL="4" cornerRadiusTR="4" cornerRadiusBL="22" cornerRadiusBR="22" name="Path"/>
                    {fill(FACE)}
                    {stroke(INK, 5)}
                </Shape>
                <Shape x="34" y="-2" name="handle" id="{HANDLE}">
                    <Ellipse width="30" height="36" name="Path"/>
                    {stroke(INK, 7)}
                </Shape>
            </Node>
'''
STEAM_XML = (f'            <Node x="{MUG_X + 10}" y="{MUG_Y - 6}" rotation="0.35" scaleX="1.5" scaleY="1.5" name="steam" id="{STEAM}">\n'
             + wisp(WISP_A, -10, 0) + wisp(WISP_B, 12, 1) +
             '            </Node>\n')

pose_open = '            <Node y="58" name="pose" id="0:2200">\n'
assert s.count(pose_open) == 1
# First child draws in front: the mug sits over the belly, the steam over it.
s = s.replace(pose_open, pose_open + STEAM_XML + MUG_XML)

# ---------------------------------------------------------------- pin the mug in every old animation

parts = []
pos = 0
for m in re.finditer(r'<LinearAnimation [^>]*duration="(\d+)"[^>]*>.*?(        </LinearAnimation>)', s, re.S):
    dur = int(m.group(1))
    end = m.start(2)
    parts.append(s[pos:end])
    parts.append('\n'.join(keyed(MUG_REST, dur, {})) + '\n')
    pos = end
parts.append(s[pos:])
s = ''.join(parts)

# ---------------------------------------------------------------- new animations

# Brings the mug up from the belly with a small overshoot. The steam starts
# once it's settled.
D_IN = 36
coffee_in = animation('coffee_in', A_IN, D_IN, {
    MUG: {
        OPACITY: [(0, 0), (8, 1, None), (D_IN, 1)],
        SX: [(0, 0.6 * K), (20, K, BACK), (D_IN, K)],
        SY: [(0, 0.6 * K), (20, K, BACK), (D_IN, K)],
        Y: [(0, MUG_Y + 30), (20, MUG_Y, BACK), (D_IN, MUG_Y)],
    },
    '0:2001': {SY: [(0, 1), (10, 0.97), (24, 1.01), (D_IN, 1)]},
    '0:786': {Y: [(0, REST['0:786'][Y]), (18, REST['0:786'][Y] + 8), (D_IN, REST['0:786'][Y] + 4)]},
})


def wisp_keys(phase, total, period=120):
    # One cycle, shifted by `phase` and wrapped into [0, total].
    cyc = [(0.0, WISP_Y + 10, 0.0), (0.3, WISP_Y - 4, 0.75), (0.95, WISP_Y - 34, 0.0), (1.0, WISP_Y + 10, 0.0)]
    pts = []
    for k in range(-1, total // period + 2):
        for u, y, o in cyc:
            f = k * period + phase + u * period
            pts.append((f, y, o))
    pts.sort()

    def interp(f, idx):
        for a, b in zip(pts, pts[1:]):
            if a[0] <= f <= b[0]:
                if b[0] == a[0]:
                    return b[idx]
                return a[idx] + (b[idx] - a[idx]) * (f - a[0]) / (b[0] - a[0])
    inner = [p for p in pts if 0 < p[0] < total]
    ys = [(0, interp(0, 1), None)] + [(round(p[0]), p[1], None) for p in inner] + [(total, interp(total, 1), None)]
    ops = [(0, interp(0, 2), None)] + [(round(p[0]), p[2], None) for p in inner] + [(total, interp(total, 2), None)]
    return ys, ops


D_HOLD = 240
wa_y, wa_o = wisp_keys(0, D_HOLD)
wb_y, wb_o = wisp_keys(60, D_HOLD)
base_eye = REST['0:786'][Y]
coffee_hold = animation('coffee_hold', A_HOLD, D_HOLD, {
    MUG: {OPACITY: [(0, 1), (D_HOLD, 1)], SX: [(0, K), (D_HOLD, K)], SY: [(0, K), (D_HOLD, K)],
          Y: [(0, MUG_Y), (60, MUG_Y - 3), (120, MUG_Y), (180, MUG_Y - 3), (D_HOLD, MUG_Y)]},
    WISP_A: {Y: wa_y, OPACITY: wa_o},
    WISP_B: {Y: wb_y, OPACITY: wb_o},
    '0:2001': {SY: [(0, 1), (60, 1.012), (120, 1), (180, 1.012), (D_HOLD, 1)],
               SX: [(0, 1), (60, 0.995), (120, 1), (180, 0.995), (D_HOLD, 1)]},
    # Mostly eyeing the cup, with a look up now and then.
    '0:786': {Y: [(0, base_eye + 4), (130, base_eye + 4), (150, base_eye - 2), (200, base_eye - 2), (D_HOLD - 10, base_eye + 4), (D_HOLD, base_eye + 4)]},
})

# A sip: the mug comes up to the mouth and tips, the eye closes in the happy
# squint, a contented little sink, and back down.
D_SIP = 100
SIP_X, SIP_Y, SIP_ROT = 70, 196, -0.5
POSE = REST['0:2200'][Y]
SIT_UP = POSE - 26  # sits up to sip, so the tipped mug stays in frame
lid = REST['0:2401'][Y]
eye_sy = REST['0:1048'][SY]
coffee_sip = animation('coffee_sip', A_SIP, D_SIP, {
    MUG: {
        OPACITY: [(0, 1), (D_SIP, 1)], SX: [(0, K), (D_SIP, K)], SY: [(0, K), (D_SIP, K)],
        X: [(0, MUG_X), (22, SIP_X), (70, SIP_X - 4), (90, MUG_X, EO), (D_SIP, MUG_X)],
        Y: [(0, MUG_Y), (22, SIP_Y), (70, SIP_Y + 2), (90, MUG_Y, EO), (D_SIP, MUG_Y)],
        ROT: [(0, 0), (22, SIP_ROT), (34, SIP_ROT - 0.12), (62, SIP_ROT - 0.12), (74, SIP_ROT), (90, 0, EO), (D_SIP, 0)],
    },
    WISP_A: {OPACITY: [(0, 0.4), (8, 0), (D_SIP - 10, 0), (D_SIP, 0.3)]},
    WISP_B: {OPACITY: [(0, 0.2), (8, 0), (D_SIP - 10, 0), (D_SIP, 0.1)]},
    '0:2401': {Y: [(0, lid), (20, lid), (32, 140), (66, 140), (82, lid), (D_SIP, lid)]},
    '0:1048': {SY: [(0, eye_sy), (20, eye_sy), (32, 0.8875), (66, 0.8875), (82, eye_sy), (D_SIP, eye_sy)]},
    '0:786': {Y: [(0, base_eye + 4), (20, base_eye + 6), (66, base_eye + 6), (82, base_eye), (D_SIP, base_eye + 4)]},
    '0:748': {ROT: [(0, 0), (24, -0.04), (64, -0.05), (86, 0), (D_SIP, 0)]},
    '0:2200': {Y: [(0, POSE), (22, SIT_UP), (70, SIT_UP), (90, POSE, EO), (D_SIP, POSE)]},
    '0:2001': {SY: [(0, 1), (24, 1.015), (64, 1.015), (76, 0.96), (88, 1.01), (D_SIP, 1)],
               SX: [(0, 1), (24, 0.99), (64, 0.99), (76, 1.03), (88, 0.995), (D_SIP, 1)]},
})

anchor = '        <StateMachine name="State Machine 1" id="0:24">'
assert anchor in s
s = s.replace(anchor, coffee_in + coffee_hold + coffee_sip + anchor, 1)

# ---------------------------------------------------------------- state machine


def when_bool(to, prop, value, duration):
    return f'''                    <StateTransition stateToId="{to}" duration="{duration}">
                        <TransitionViewModelCondition>
                            <TransitionPropertyViewModelComparator>
                                <BindablePropertyBoolean>
                                    <DataBindContext sourcePathIds="0:14-{prop}" propertyKey="634"/>
                                </BindablePropertyBoolean>
                            </TransitionPropertyViewModelComparator>
                            <TransitionValueBooleanComparator value="{value}"/>
                        </TransitionViewModelCondition>
                    </StateTransition>
'''


def on_trigger(to, prop, duration):
    return f'''                    <StateTransition stateToId="{to}" duration="{duration}">
                        <TransitionViewModelCondition>
                            <TransitionPropertyViewModelComparator>
                                <BindablePropertyTrigger>
                                    <DataBindContext sourcePathIds="0:14-{prop}" propertyKey="686"/>
                                </BindablePropertyTrigger>
                            </TransitionPropertyViewModelComparator>
                            <TransitionValueTriggerComparator/>
                        </TransitionViewModelCondition>
                    </StateTransition>
'''


def after(to, duration=200):
    return (f'                    <StateTransition stateToId="{to}" duration="{duration}" enableExitTime="true" '
            f'exitTimeIsPercetange="true" exitTime="100">\n                    </StateTransition>\n')


# Idle picks the cup up last, so a reaction fired in the same frame wins and
# the mug comes back once it's over.
idle_open = '<AnimationState x="160" animationId="0:1038" id="0:29">'
i = s.index(idle_open)
j = s.index('                </AnimationState>', i)
s = s[:j] + when_bool(S_IN, HAS_COFFEE, 'true', 150) + s[j:]

# From the hold, the things that already react from idle: sleeping and the
# in-run reactions. Each tucks the mug away (it's pinned hidden there).
reactions = [('0:2305', '0:2310'), ('0:2306', '0:2311'), ('0:2031', '0:2021'), ('0:2030', '0:2020'), ('0:2035', '0:2024')]
hold_out = (when_bool('0:29', HAS_COFFEE, 'false', 350)
            + when_bool('0:2033', '0:2023', 'true', 300)
            + on_trigger(S_SIP, SIP, 150)
            + ''.join(on_trigger(to, prop, 150) for to, prop in reactions))

states = (f'                <AnimationState x="-200" y="600" animationId="{A_IN}" reset="true" id="{S_IN}">\n'
          + when_bool('0:29', HAS_COFFEE, 'false', 300)
          + after(S_HOLD, 150)
          + '                </AnimationState>\n'
          + f'                <AnimationState x="-200" y="750" animationId="{A_HOLD}" id="{S_HOLD}">\n'
          + hold_out
          + '                </AnimationState>\n'
          + f'                <AnimationState x="-200" y="900" animationId="{A_SIP}" reset="true" id="{S_SIP}">\n'
          + when_bool('0:29', HAS_COFFEE, 'false', 300)
          + after(S_HOLD, 200)
          + '                </AnimationState>\n')
end_layer = '            </StateMachineLayer>'
assert s.count(end_layer) == 1
s = s.replace(end_layer, states + end_layer)

prop_anchor = '        <ViewModelPropertyTrigger name="bounce" id="0:2332"/>\n'
assert prop_anchor in s
s = s.replace(prop_anchor, prop_anchor +
              f'        <ViewModelPropertyBoolean name="hasCoffee" id="{HAS_COFFEE}"/>\n'
              f'        <ViewModelPropertyTrigger name="sip" id="{SIP}"/>\n')
inst_anchor = '            <ViewModelInstanceTrigger viewModelPropertyId="0:2332"/>\n'
assert inst_anchor in s
s = s.replace(inst_anchor, inst_anchor +
              f'            <ViewModelInstanceBoolean propertyValue="false" viewModelPropertyId="{HAS_COFFEE}"/>\n'
              f'            <ViewModelInstanceTrigger viewModelPropertyId="{SIP}"/>\n')

open(OUT, 'w').write(s)
print('written', OUT, file=sys.stderr)
