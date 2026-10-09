"""Adds the onboarding-story moves to rive/mascot/scene.rml: `run` (feet out,
a jogging stride with pumping arms), `jump` (crouch, leap with both arms up,
land), and `bounce` (a relaxed happy bob, feet tucked). Each sits behind a
view-model trigger fired from idle. Reads build/scene.pre-story.rml.bak."""
import importlib.util, sys

spec = importlib.util.spec_from_file_location('r', '/home/sabera/Projects/openroutine/rive/mascot/build/gen_reactions.py')
SRC = '/home/sabera/Projects/openroutine/rive/mascot/build/scene.pre-story.rml.bak'
OUT = '/home/sabera/Projects/openroutine/rive/mascot/scene.rml'

X, Y, ROT, SX, SY, OPACITY = 13, 14, 15, 16, 17, 18
IO = (0.42, 0.0, 0.58, 1.0)
EO = (0.16, 0.7, 0.3, 1.0)
EI = (0.5, 0.0, 0.75, 0.3)

REST = {
    '0:2001': {Y: 706, SX: 1, SY: 1, ROT: 0},
    '0:748': {ROT: 0},
    '0:992': {SY: 1, ROT: 0},
    '0:1048': {SX: 1, SY: 1, OPACITY: 1},
    '0:2040': {OPACITY: 0},
    '0:786': {X: 3.37595, Y: -8.19086},
    '0:757': {X: 37.262, Y: -47.8123, SX: 1, SY: 1},
    '0:749': {X: -47.2585, Y: 0.235657, SX: 1, SY: 1, ROT: 0},
    '0:806': {24: -24.5, 25: -7, 86: 0.730907, 87: 19.4743},
    '0:807': {24: 24.5, 25: -7, 84: 2.407, 85: 20.8866},
    '0:2070': {OPACITY: 0},
    '0:2080': {OPACITY: 0},
    '0:2200': {Y: 58},
    '0:2201': {Y: -66},
    '0:2050': {SY: 0.001, ROT: 0.25},
    '0:2052': {ROT: 0},
    '0:2210': {SY: 0.001, ROT: -0.25},
    '0:917': {Y: 242.7, ROT: 0},   # foot_left
    '0:940': {Y: 242.7, ROT: 0},   # foot_right
}


def kf(frame, value, ease=IO):
    if ease is None:
        return f'<KeyFrameDouble value="{value}" interpolationType="linear" frame="{frame}"/>'
    x1, y1, x2, y2 = ease
    return (f'<KeyFrameDouble value="{value}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/></KeyFrameDouble>')


def animation(name, anim_id, duration, custom):
    out = [f'        <LinearAnimation fps="60" duration="{duration}" loopValue="oneShot" name="{name}" id="{anim_id}">']
    for obj, rest in REST.items():
        out.append(f'            <KeyedObject objectId="{obj}">')
        for prop, base in rest.items():
            frames = custom.get(obj, {}).get(prop) or [(0, base), (duration, base)]
            out.append(f'                <KeyedProperty propertyKey="{prop}">')
            out += ['                    ' + kf(*f) for f in frames]
            out.append('                </KeyedProperty>')
        out.append('            </KeyedObject>')
    out.append('        </LinearAnimation>')
    return '\n'.join(out) + '\n'


def feet_out(start, end, total):
    """pose drops the body onto the feet at `start`, tucks them away at `end`."""
    return {
        '0:2200': {Y: [(0, 58), (start, 58, EO), (start + 8, -4), (start + 12, 0), (end, 0), (end + 14, 58), (total, 58)]},
        '0:2201': {Y: [(0, -66), (start, -66, EO), (start + 8, 4), (start + 12, 0), (end, 0), (end + 14, -66), (total, -66)]},
    }


def happy_mouth(a, b, c, d, total):
    return {
        '0:806': {24: [(0, -24.5), (a, -24.5), (b, -30), (c, -30), (d, -24.5), (total, -24.5)],
                  25: [(0, -7), (a, -7), (b, -11), (c, -11), (d, -7), (total, -7)],
                  86: [(0, 0.730907), (a, 0.730907), (b, 1), (c, 1), (d, 0.730907), (total, 0.730907)],
                  87: [(0, 19.4743), (a, 19.4743), (b, 25), (c, 25), (d, 19.4743), (total, 19.4743)]},
        '0:807': {24: [(0, 24.5), (a, 24.5), (b, 30), (c, 30), (d, 24.5), (total, 24.5)],
                  25: [(0, -7), (a, -7), (b, -11), (c, -11), (d, -7), (total, -7)],
                  84: [(0, 2.407), (a, 2.407), (b, 2.14159), (c, 2.14159), (d, 2.407), (total, 2.407)],
                  85: [(0, 20.8866), (a, 20.8866), (b, 25), (c, 25), (d, 20.8866), (total, 20.8866)]},
    }


# ---- run: 96 frames. Feet out by 12, six strides of 10 frames from 14 to 74,
# feet tucked by 94. The pet leans into the direction of travel (to the right).
RUN = 96
rig_y, rig_sy, fl_y, fr_y, fl_r, fr_r, arm_r, arml_r = [(0, 706)], [(0, 1)], [(0, 242.7)], [(0, 242.7)], [(0, 0)], [(0, 0)], [(0, 0.25)], [(0, -0.25)]
for i, f in enumerate(range(14, 74, 10)):
    left = i % 2 == 0
    rig_y += [(f, 706), (f + 5, 684)]
    rig_sy += [(f, 0.96), (f + 5, 1.03)]
    up, down = (fl_y, fr_y) if left else (fr_y, fl_y)
    up += [(f, 242.7), (f + 5, 206)]
    down += [(f, 242.7), (f + 5, 242.7)]
    fl_r += [(f + 5, 0.25 if left else -0.12)]
    fr_r += [(f + 5, -0.12 if left else 0.25)]
    arm_r += [(f + 5, 0.55 if left else 0.05)]
    arml_r += [(f + 5, -0.05 if left else -0.55)]
rig_y += [(74, 706), (RUN, 706)]
rig_sy += [(74, 1), (RUN, 1)]
fl_y += [(74, 242.7), (RUN, 242.7)]
fr_y += [(74, 242.7), (RUN, 242.7)]
fl_r += [(78, 0), (RUN, 0)]
fr_r += [(78, 0), (RUN, 0)]
arm_r += [(80, 0.25), (RUN, 0.25)]
arml_r += [(80, -0.25), (RUN, -0.25)]

run = animation('run', '0:2320', RUN, {
    **feet_out(0, 80, RUN),
    '0:2001': {Y: rig_y, SY: rig_sy},
    '0:748': {ROT: [(0, 0), (12, 0.14), (74, 0.14), (86, 0), (RUN, 0)]},
    '0:917': {Y: fl_y, ROT: fl_r},
    '0:940': {Y: fr_y, ROT: fr_r},
    '0:2050': {SY: [(0, 0.001), (6, 0.001, EO), (16, 0.75), (74, 0.75, EI), (84, 0.001, None), (RUN, 0.001)], ROT: arm_r},
    '0:2210': {SY: [(0, 0.001), (6, 0.001, EO), (16, 0.75), (74, 0.75, EI), (84, 0.001, None), (RUN, 0.001)], ROT: arml_r},
    # Eyes look ahead, to the right.
    '0:786': {X: [(0, 3.37595), (12, 16), (74, 16), (86, 3.37595), (RUN, 3.37595)]},
    '0:757': {X: [(0, 37.262), (12, 50), (74, 50), (86, 37.262), (RUN, 37.262)]},
    '0:749': {X: [(0, -47.2585), (12, -34.6), (74, -34.6), (86, -47.2585), (RUN, -47.2585)]},
})

# ---- jump: 84 frames. Feet out, crouch, leap with both arms up, land, settle.
JUMP = 84
jump = animation('jump', '0:2321', JUMP, {
    **feet_out(0, 64, JUMP),
    '0:2001': {
        Y: [(0, 706), (14, 706), (20, 706, EO), (34, 600, EI), (48, 706, None), (84, 706)],
        SY: [(0, 1), (12, 1), (18, 0.84), (24, 1.12), (34, 1.02), (46, 1.05), (50, 0.86), (58, 1.03), (64, 1), (84, 1)],
        SX: [(0, 1), (12, 1), (18, 1.12), (24, 0.92), (34, 0.99), (46, 0.97), (50, 1.12), (58, 0.98), (64, 1), (84, 1)],
    },
    '0:917': {ROT: [(0, 0), (20, 0), (30, 0.28), (44, 0.1), (50, 0), (84, 0)]},
    '0:940': {ROT: [(0, 0), (20, 0), (30, -0.28), (44, -0.1), (50, 0), (84, 0)]},
    '0:2050': {SY: [(0, 0.001), (16, 0.001, EO), (28, 1.06), (32, 1), (56, 1, EI), (66, 0.001, None), (84, 0.001)],
               ROT: [(0, 0.25), (28, 0.5), (40, 0.4), (56, 0.3), (66, 0.25), (84, 0.25)]},
    '0:2210': {SY: [(0, 0.001), (16, 0.001, EO), (28, 1.06), (32, 1), (56, 1, EI), (66, 0.001, None), (84, 0.001)],
               ROT: [(0, -0.25), (28, -0.5), (40, -0.4), (56, -0.3), (66, -0.25), (84, -0.25)]},
    '0:1048': {SY: [(0, 1), (16, 1), (24, 0.55), (52, 0.55), (62, 1), (84, 1)]},
    **happy_mouth(16, 26, 52, 64, JUMP),
})

# ---- bounce: 120 frames. Three soft hops in place, a gentle sway, content
# squinted eyes. Feet stay tucked: this is the unhurried one.
BOUNCE = 120
b_y, b_sy, b_sx = [(0, 706)], [(0, 1)], [(0, 1)]
for f in (6, 36, 66):
    b_y += [(f, 706, EO), (f + 12, 688, EI), (f + 24, 706, None)]
    b_sy += [(f, 0.93), (f + 10, 1.04), (f + 24, 0.95)]
    b_sx += [(f, 1.05), (f + 10, 0.98), (f + 24, 1.03)]
b_y += [(BOUNCE, 706)]
b_sy += [(100, 1), (BOUNCE, 1)]
b_sx += [(100, 1), (BOUNCE, 1)]
bounce = animation('bounce', '0:2322', BOUNCE, {
    '0:2001': {Y: b_y, SY: b_sy, SX: b_sx},
    '0:748': {ROT: [(0, 0), (20, 0.04), (50, -0.04), (80, 0.03), (104, 0), (BOUNCE, 0)]},
    '0:1048': {SY: [(0, 1), (10, 0.6), (96, 0.6), (108, 1), (BOUNCE, 1)]},
    **happy_mouth(4, 14, 96, 108, BOUNCE),
})

s = open(SRC).read()
anchor = '        <StateMachine name="State Machine 1" id="0:24">'
assert anchor in s
s = s.replace(anchor, run + jump + bounce + anchor, 1)

idle_open = '<AnimationState x="160" animationId="0:1038" id="0:29">'
i = s.index(idle_open)
j = s.index('                </AnimationState>', i)


def trigger_transition(to, prop):
    return f'''                    <StateTransition stateToId="{to}" duration="120">
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


s = s[:j] + ''.join(trigger_transition(t, p) for t, p in
                    (('0:2325', '0:2330'), ('0:2326', '0:2331'), ('0:2327', '0:2332'))) + s[j:]

states = ''.join(f'''                <AnimationState x="400" y="{y}" animationId="{a}" reset="true" id="{sid}">
                    <StateTransition stateToId="0:29" duration="200" enableExitTime="true" exitTimeIsPercetange="true" exitTime="100">
                    </StateTransition>
                </AnimationState>
''' for y, a, sid in ((900, '0:2320', '0:2325'), (1050, '0:2321', '0:2326'), (1200, '0:2322', '0:2327')))
end_layer = '            </StateMachineLayer>'
assert s.count(end_layer) == 1
s = s.replace(end_layer, states + end_layer)

prop_anchor = '        <ViewModelPropertyTrigger name="skip" id="0:2311"/>\n'
assert prop_anchor in s
s = s.replace(prop_anchor, prop_anchor +
              '        <ViewModelPropertyTrigger name="run" id="0:2330"/>\n'
              '        <ViewModelPropertyTrigger name="jump" id="0:2331"/>\n'
              '        <ViewModelPropertyTrigger name="bounce" id="0:2332"/>\n')
inst_anchor = '            <ViewModelInstanceTrigger viewModelPropertyId="0:2311"/>\n'
assert inst_anchor in s
s = s.replace(inst_anchor, inst_anchor +
              '            <ViewModelInstanceTrigger viewModelPropertyId="0:2330"/>\n'
              '            <ViewModelInstanceTrigger viewModelPropertyId="0:2331"/>\n'
              '            <ViewModelInstanceTrigger viewModelPropertyId="0:2332"/>\n')
open(OUT, 'w').write(s)
print('written', file=sys.stderr)
