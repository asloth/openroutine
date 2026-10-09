"""Adds the in-run reactions to rive/mascot/scene.rml: `step_done` (a mini
cheer when a step is marked done) and `skip_nod` (an okay nod on skip), each
behind a view-model trigger fired from idle."""
import sys

SRC = '/home/sabera/Projects/openroutine/rive/mascot/build/scene.pre-reactions.rml.bak'
OUT = '/home/sabera/Projects/openroutine/rive/mascot/scene.rml'

X, Y, ROT, SX, SY, OPACITY = 13, 14, 15, 16, 17, 18
IO = (0.42, 0.0, 0.58, 1.0)
EO = (0.16, 0.7, 0.3, 1.0)

# Every property another state keys, at rest. A oneShot that leaves any of
# these unkeyed would inherit whatever the previous state left behind.
REST = {
    '0:2001': {Y: 706, SX: 1, SY: 1, ROT: 0},       # rig
    '0:748': {ROT: 0},                              # character
    '0:992': {SY: 1, ROT: 0},                       # head
    '0:1048': {SX: 1, SY: 1, OPACITY: 1},           # eye_group
    '0:2040': {OPACITY: 0},                         # eyelid
    '0:786': {X: 3.37595, Y: -8.19086},             # pupil
    '0:757': {X: 37.262, Y: -47.8123, SX: 1, SY: 1},  # shine_1
    '0:749': {X: -47.2585, Y: 0.235657, SX: 1, SY: 1, ROT: 0},  # shine_2
    '0:806': {24: -24.5, 25: -7, 86: 0.730907, 87: 19.4743},  # mouth L
    '0:807': {24: 24.5, 25: -7, 84: 2.407, 85: 20.8866},      # mouth R
    '0:2070': {OPACITY: 0},                         # thought dots
    '0:2080': {OPACITY: 0},                         # zzz
    '0:2200': {Y: 58},                              # pose (body resting low)
    '0:2201': {Y: -66},                             # legs tucked
    '0:2050': {SY: 0.001, ROT: 0.25},               # arm
    '0:2052': {ROT: 0},                             # wrist
    '0:2210': {SY: 0.001, ROT: -0.25},              # arm_left
}


def kf(frame, value, ease=IO):
    if ease is None:
        return f'<KeyFrameDouble value="{value}" interpolationType="linear" frame="{frame}"/>'
    x1, y1, x2, y2 = ease
    return (f'<KeyFrameDouble value="{value}" interpolationType="cubic" frame="{frame}">'
            f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/></KeyFrameDouble>')


def animation(name, anim_id, duration, custom):
    """custom: {object_id: {property: [(frame, value[, ease]), ...]}}"""
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


happy_mouth_l = {24: [(0, -24.5), (10, -30), (36, -30), (54, -24.5), (66, -24.5)],
                 25: [(0, -7), (10, -11), (36, -11), (54, -7), (66, -7)],
                 86: [(0, 0.730907), (10, 1), (36, 1), (54, 0.730907), (66, 0.730907)],
                 87: [(0, 19.4743), (10, 25), (36, 25), (54, 19.4743), (66, 19.4743)]}
happy_mouth_r = {24: [(0, 24.5), (10, 30), (36, 30), (54, 24.5), (66, 24.5)],
                 25: [(0, -7), (10, -11), (36, -11), (54, -7), (66, -7)],
                 84: [(0, 2.407), (10, 2.14159), (36, 2.14159), (54, 2.407), (66, 2.407)],
                 85: [(0, 20.8866), (10, 25), (36, 25), (54, 20.8866), (66, 20.8866)]}

# A mini cheer: a small hop with one arm up and happy squinted eyes. Much
# smaller than `celebrate`, and the feet stay tucked: this is "nice", not "done".
step_done = animation('step_done', '0:2300', 66, {
    '0:2001': {
        SY: [(0, 1), (6, 0.9), (14, 1.06), (26, 0.95), (34, 1.02), (44, 1), (66, 1)],
        SX: [(0, 1), (6, 1.07), (14, 0.96), (26, 1.04), (34, 0.99), (44, 1), (66, 1)],
        Y: [(0, 706), (6, 706, EO), (16, 686), (26, 706, None), (66, 706)],
    },
    '0:1048': {SY: [(0, 1), (12, 0.55), (32, 0.55), (44, 1), (66, 1)]},
    '0:2050': {
        SY: [(0, 0.001), (5, 0.001, EO), (16, 1.05), (22, 1), (38, 1, (0.5, 0.0, 0.75, 0.3)), (50, 0.001, None), (66, 0.001)],
        ROT: [(0, 0.25), (16, 0.4), (26, 0.3), (36, 0.42), (50, 0.25), (66, 0.25)],
    },
    '0:2052': {ROT: [(0, 0), (16, 0), (24, -0.25), (32, 0.25), (40, 0), (66, 0)]},
    '0:806': happy_mouth_l,
    '0:807': happy_mouth_r,
})

# An okay nod: the eyes drop and come back up twice with a small body squash
# and a tiny tilt. No judgement about the skipped step.
skip_nod = animation('skip_nod', '0:2301', 48, {
    '0:2001': {
        SY: [(0, 1), (8, 0.95), (16, 1.02), (24, 0.96), (32, 1.01), (40, 1), (48, 1)],
        SX: [(0, 1), (8, 1.03), (16, 0.99), (24, 1.02), (32, 1), (48, 1)],
    },
    '0:748': {ROT: [(0, 0), (10, 0.03), (22, -0.02), (34, 0), (48, 0)]},
    '0:786': {Y: [(0, -8.19086), (8, 1.80914), (16, -8.19086), (24, -1.19086), (34, -8.19086), (48, -8.19086)]},
    '0:757': {Y: [(0, -47.8123), (8, -37.8123), (16, -47.8123), (24, -40.8123), (34, -47.8123), (48, -47.8123)]},
    '0:749': {Y: [(0, 0.235657), (8, 10.2357), (16, 0.235657), (24, 7.2357), (34, 0.235657), (48, 0.235657)]},
})

s = open(SRC).read()

# Animations go after the last existing one.
anchor = '        <StateMachine name="State Machine 1" id="0:24">'
assert anchor in s
s = s.replace(anchor, step_done + skip_nod + anchor, 1)

# Idle listens for the two new triggers.
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


s = s[:j] + trigger_transition('0:2305', '0:2310') + trigger_transition('0:2306', '0:2311') + s[j:]

states = '''                <AnimationState x="400" y="600" animationId="0:2300" reset="true" id="0:2305">
                    <StateTransition stateToId="0:29" duration="200" enableExitTime="true" exitTimeIsPercetange="true" exitTime="100">
                    </StateTransition>
                </AnimationState>
                <AnimationState x="400" y="750" animationId="0:2301" reset="true" id="0:2306">
                    <StateTransition stateToId="0:29" duration="200" enableExitTime="true" exitTimeIsPercetange="true" exitTime="100">
                    </StateTransition>
                </AnimationState>
'''
end_layer = '            </StateMachineLayer>'
assert s.count(end_layer) == 1
s = s.replace(end_layer, states + end_layer)

prop_anchor = '        <ViewModelPropertyTrigger name="tap" id="0:2024"/>\n'
assert prop_anchor in s
s = s.replace(prop_anchor, prop_anchor +
              '        <ViewModelPropertyTrigger name="stepDone" id="0:2310"/>\n'
              '        <ViewModelPropertyTrigger name="skip" id="0:2311"/>\n')
inst_anchor = '            <ViewModelInstanceTrigger viewModelPropertyId="0:2024"/>\n'
assert inst_anchor in s
s = s.replace(inst_anchor, inst_anchor +
              '            <ViewModelInstanceTrigger viewModelPropertyId="0:2310"/>\n'
              '            <ViewModelInstanceTrigger viewModelPropertyId="0:2311"/>\n')

open(OUT, 'w').write(s)
print('written', file=sys.stderr)
