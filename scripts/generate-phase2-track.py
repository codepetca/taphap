#!/usr/bin/env python3
"""Afterglow: original instrumental, authored here; no samples or dependencies.
Deterministic PCM synthesis. 16 bars at 120, A minor / F / C / G.
Run with Python 3; verify committed hashes rather than assuming libm portability.
"""
import array, hashlib, json, math, pathlib, struct, wave
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT/'TapHapGame/Resources'
RATE = 48000
pcm = array.array('d', [0]) * (34*RATE)
def voice(start, duration, hz, amp, kind):
    count = round(duration*RATE)
    for i in range(count):
        t = i/RATE; p = 2*math.pi*hz*t
        edge = min(1, t/.003, (duration-t)/.012)
        if kind == 'kick':
            v = math.sin(p + 10*(1-math.exp(-35*t)))*math.exp(-22*t)
        elif kind == 'hat':
            v = (math.sin(p*1.73)+math.sin(p*2.91)+math.sin(p*4.13))/3*math.exp(-60*t)
        elif kind == 'snare':
            v = (.5*math.sin(p)+.25*math.sin(p*7.31)+.25*math.sin(p*11.71))*math.exp(-26*t)
        elif kind == 'bass':
            v = (math.sin(p)+.28*math.sin(2*p)+.13*math.sin(3*p))*math.exp(-4*t)
        else:
            v = (math.sin(p)+.3*math.sin(2*p)+.12*math.sin(4*p))*math.exp(-9*t)
        pcm[round(start*RATE)+i] += amp*edge*v
roots = [110, 87.3070578583, 130.8127826503, 97.9988589954]
melody = [[12, 19, 22, 19], [12, 16, 19, 24], [16, 19, 24, 19], [14, 19, 21, 19]]
for bar in range(16):
    root=roots[bar%4]; section=bar//4
    for beat in range(4):
        at=1+bar*2+beat*.5
        voice(at,.34,52,.43,'kick')
        voice(at,.40,root/2,.28,'bass')
        if beat%2: voice(at,.18,185,.19,'snare')
        voice(at,.065,3200,.08,'hat')
        voice(at+.25,.06,3900,.055,'hat')
        # Offbeat chord stabs and an evolving original answer melody.
        for semitone in [0,3 if bar%4==0 else 4,7]:
            voice(at+.25,.21,root*2**(semitone/12+1),.042,'keys')
        if section > 0 or beat in [1,3]:
            voice(at+.25,.22,root*2**(melody[bar%4][beat]/12),.095 if section!=2 else .06,'keys')
# Authored phrase ending: no appended click/count cue.
values=[round(max(-.98,min(.98,v))*32767) for v in pcm]
with wave.open(str(OUT/'Afterglow.wav'),'wb') as w:
    w.setparams((1,2,RATE,0,'NONE','not compressed')); w.writeframes(struct.pack('<'+'h'*len(values),*values))
print(hashlib.sha256((OUT/'Afterglow.wav').read_bytes()).hexdigest())
