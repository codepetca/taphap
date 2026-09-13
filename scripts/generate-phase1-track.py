#!/usr/bin/env python3
"""Original 32-second instrumental study. No samples, recordings or third-party music.
Synthesis score is intentionally separate from the manually specified beat map.
"""
import array, hashlib, json, math, pathlib, struct, sys, wave
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'Phase1Lab/Resources'
RATE = 48000
frames = array.array('d', [0]) * (34 * RATE)
def note(start, duration, frequency, amplitude, kind):
    for n in range(int(duration * RATE)):
        t = n / RATE
        env = min(1, t / .004) * math.exp(-t * (9 if kind == 'pluck' else 15))
        phase = 2 * math.pi * frequency * t
        value = (math.sin(phase) + .25 * math.sin(phase * 2)) if kind == 'pluck' else math.sin(phase + 7 * (1-math.exp(-35*t)))
        frames[int(start * RATE) + n] += amplitude * env * value
# Authored note score: 16 bars, 4 quarter notes per bar, 120 quarter notes/minute.
# One-second pickup silence. A minor / F / C / G, repeated four times.
roots = [110.0, 87.3070578583, 130.8127826503, 97.9988589954]
melody = [0,7,12,7, 3,7,15,12, 0,4,7,12, 7,2,14,7]
for bar in range(16):
    root = roots[bar % 4]
    for pulse in range(4):
        start = 1 + bar * 2 + pulse * .5
        note(start, .45, root, .26, 'pluck')
        note(start, .20, 58 if pulse % 2 == 0 else 170, .27, 'drum')
        note(start + .25, .22, root * 2 ** (melody[(bar*4+pulse)%16]/12 + 1), .15, 'pluck')
# Exact 16-bit PCM, no stochastic source. Python/libm cross-platform bytes must be checked.
values = [max(-32767,min(32767,round(v * 24000))) for v in frames]
with wave.open(str(OUT/'ClockworkGarden.wav'),'wb') as w:
    w.setparams((1,2,RATE,0,'NONE','not compressed'))
    w.writeframes(struct.pack('<'+'h'*len(values), *values))
print(hashlib.sha256((OUT/'ClockworkGarden.wav').read_bytes()).hexdigest())
