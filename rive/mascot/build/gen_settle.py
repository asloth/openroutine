"""Lets Ochi come to rest without freezing mid-blink.

The app stops advancing the artboard a few seconds after each wake, to keep
the screen calm. Stopping on an arbitrary frame could leave the eye half shut,
so the app first turns on a new `isSettled` boolean, and each looping state
that can be on screen at that moment (`idle`, `thinking`, and `coffee_hold`)
blends into a still copy of its own first frame: the eye open, the cup held.

Each still state keeps every way out of its parent, so a reaction fired at a
settled pet still plays, and turning `isSettled` off goes back to the loop.

Usage: gen_settle.py SRC OUT
"""
import re
import sys

SRC, OUT = sys.argv[1], sys.argv[2]
s = open(SRC).read()

IS_SETTLED = '0:2740'
# parent state id -> (still animation id, still state id)
STILLS = {
    '0:29': ('0:2741', '0:2745'),    # idle
    '0:2032': ('0:2742', '0:2746'),  # thinking
    '0:2726': ('0:2743', '0:2747'),  # coffee_hold
}
D_STILL = 60
BLEND_IN, BLEND_OUT = 300, 250

anims = {}
for m in re.finditer(r'<LinearAnimation [^>]*name="([^"]+)" id="([^"]+)">(.*?)</LinearAnimation>', s, re.S):
    keyed = {}
    for ob in re.finditer(r'<KeyedObject objectId="([^"]+)">(.*?)</KeyedObject>', m.group(3), re.S):
        for kp in re.finditer(r'<KeyedProperty propertyKey="(\d+)">(.*?)</KeyedProperty>', ob.group(2), re.S):
            first = re.search(r'value="([^"]+)"', kp.group(2)).group(1)
            keyed[(ob.group(1), int(kp.group(1)))] = first
    anims[m.group(2)] = (m.group(1), keyed)

# Every property any animation keys, at rest. A still pose has to pin them
# all, or it inherits whatever the state before it left behind.
idle_id = next(i for i, (name, _) in anims.items() if name == 'idle')
REST = dict(anims[idle_id][1])
for _, keyed in anims.values():
    for key, value in keyed.items():
        REST.setdefault(key, value)


def still_animation(parent_anim, anim_id):
    name, keyed = anims[parent_anim]
    values = {**REST, **keyed}
    out = [f'        <LinearAnimation fps="60" duration="{D_STILL}" loopValue="loop" name="{name}_still" id="{anim_id}">']
    for obj in dict.fromkeys(o for o, _ in values):
        out.append(f'            <KeyedObject objectId="{obj}">')
        for (o, prop), v in values.items():
            if o != obj:
                continue
            out.append(f'                <KeyedProperty propertyKey="{prop}">')
            out.append(f'                    <KeyFrameDouble value="{v}" interpolationType="hold" frame="0"/>')
            out.append(f'                    <KeyFrameDouble value="{v}" interpolationType="hold" frame="{D_STILL}"/>')
            out.append('                </KeyedProperty>')
        out.append('            </KeyedObject>')
    out.append('        </LinearAnimation>')
    return '\n'.join(out) + '\n'


def when_settled(to, value, duration):
    return f'''                    <StateTransition stateToId="{to}" duration="{duration}">
                        <TransitionViewModelCondition>
                            <TransitionPropertyViewModelComparator>
                                <BindablePropertyBoolean>
                                    <DataBindContext sourcePathIds="0:14-{IS_SETTLED}" propertyKey="634"/>
                                </BindablePropertyBoolean>
                            </TransitionPropertyViewModelComparator>
                            <TransitionValueBooleanComparator value="{value}"/>
                        </TransitionViewModelCondition>
                    </StateTransition>
'''


new_anims = ''
new_states = ''
for parent, (anim_id, state_id) in STILLS.items():
    m = re.search(rf'(                <AnimationState ([^>]*)animationId="([^"]+)"([^>]*) id="{parent}">\n)(.*?)(                </AnimationState>\n)', s, re.S)
    assert m, parent
    open_tag, parent_anim, ways_out = m.group(1), m.group(3), m.group(5)
    assert 'exitTime' not in ways_out, f'{parent} leaves on exit time; a still copy would never leave'
    new_anims += still_animation(parent_anim, anim_id)
    # The parent settles last, so a reaction fired in the same frame wins.
    s = s[:m.start(6)] + when_settled(state_id, 'true', BLEND_IN) + s[m.start(6):]
    x = int(re.search(r'x="(-?\d+)"', open_tag).group(1)) if 'x="' in open_tag else 0
    y = int(re.search(r'y="(-?\d+)"', open_tag).group(1)) if 'y="' in open_tag else 0
    new_states += (f'                <AnimationState x="{x + 400}" y="{y + 60}" animationId="{anim_id}" id="{state_id}">\n'
                   + when_settled(parent, 'false', BLEND_OUT)
                   + ways_out
                   + '                </AnimationState>\n')

anchor = '        <StateMachine name="State Machine 1" id="0:24">'
assert s.count(anchor) == 1
s = s.replace(anchor, new_anims + anchor)

end_layer = '            </StateMachineLayer>'
assert s.count(end_layer) == 1
s = s.replace(end_layer, new_states + end_layer)

prop_anchor = '        <ViewModelPropertyTrigger name="sip" id="0:2731"/>\n'
assert prop_anchor in s
s = s.replace(prop_anchor, prop_anchor + f'        <ViewModelPropertyBoolean name="isSettled" id="{IS_SETTLED}"/>\n')
inst_anchor = '            <ViewModelInstanceTrigger viewModelPropertyId="0:2731"/>\n'
assert inst_anchor in s
s = s.replace(inst_anchor, inst_anchor +
              f'            <ViewModelInstanceBoolean propertyValue="false" viewModelPropertyId="{IS_SETTLED}"/>\n')

open(OUT, 'w').write(s)
print('written', OUT, file=sys.stderr)
