#!/usr/bin/env python3
"""Read exact shipped bytes; verify manually enumerated map against PCM attack windows.
Does not import synthesis code or obtain timing from player inputs.
"""
import hashlib,json,pathlib,struct,wave
root=pathlib.Path(__file__).resolve().parents[1]; assets=root/'Phase1Lab/Resources'
m=json.loads((assets/'beat-map.json').read_text())
with wave.open(str(assets/'ClockworkGarden.wav')) as w:
 assert w.getframerate()==m['sampleRate'] and w.getnframes()==m['frameCount'] and w.getnchannels()==1 and w.getsampwidth()==2
 samples=struct.unpack('<'+'h'*w.getnframes(),w.readframes(w.getnframes()))
attacks=[]
for beat,frame in enumerate(m['beats']):
 assert all(x==0 for x in samples[frame-480:frame]),f'pre-onset silence {beat}'
 onset=next(i for i,x in enumerate(samples[frame:frame+480]) if abs(x)>8)
 assert onset<=12,(beat,onset)
 assert max(abs(x) for x in samples[frame:frame+2400])>4000
 attacks.append(onset)
assert m['downbeatIndices']==list(range(0,64,4))
print(json.dumps({'beatsVerified':len(attacks),'attackThresholdPCM':8,'maximumAttackOffsetFrames':max(attacks),'maximumAttackOffsetMS':max(attacks)/48,'peakPCM':max(map(abs,samples)),'audioSHA256':hashlib.sha256((assets/'ClockworkGarden.wav').read_bytes()).hexdigest(),'mapSHA256':hashlib.sha256((assets/'beat-map.json').read_bytes()).hexdigest()},indent=2))
