#!/usr/bin/env python3
"""Independently inspect PCM/map attacks and content locks, not synthesis timing."""
import hashlib,json,pathlib,struct,wave
root=pathlib.Path(__file__).resolve().parents[1]; assets=root/'TapHapGame/Resources'
raw=(assets/'catalog.json').read_bytes(); catalog=json.loads(raw)
with wave.open(str(assets/'Afterglow.wav')) as w:
 assert w.getnchannels()==1 and w.getsampwidth()==2 and w.getframerate()==48000
 samples=struct.unpack('<'+'h'*w.getnframes(),w.readframes(w.getnframes()))
assert hashlib.sha256((assets/'Afterglow.wav').read_bytes()).hexdigest()==catalog['audioSHA256']
assert hashlib.sha256(raw).hexdigest() in (root/'TapHapGame/App/ContentRevision.swift').read_text()
# Independently enumerated musical expectation: pickup at 1 s, 64 quarter attacks.
expected=list(range(48000,1560001,24000)); offsets=[]
for frame in expected:
 assert max(map(abs,samples[frame-240:frame]))==0
 onset=next(i for i,x in enumerate(samples[frame:frame+480]) if abs(x)>8)
 assert onset<=12
 offsets.append(onset)
for c in catalog['challenges']:
 m=c['map']; assert m['beats']==expected and m['frameCount']==len(samples)
 assert m['downbeatIndices']==list(range(0,64,4))
 assert m['baselineStartBeat']==4 and m['gapStartBeat']==16
 assert m['returnBeat'] in [24,28,32]
print(json.dumps(dict(song=catalog['title'],beatsVerified=len(offsets),maximumAttackOffsetFrames=max(offsets),maximumAttackOffsetMS=max(offsets)/48,peakPCM=max(map(abs,samples)),clippedSamples=sum(abs(x)>=32767 for x in samples),audioSHA256=catalog['audioSHA256'],catalogSHA256=hashlib.sha256(raw).hexdigest(),challenges=[dict(id=c['id'],gapSeconds=(c['map']['beats'][c['map']['returnBeat']]-c['map']['beats'][16])/48000) for c in catalog['challenges']]),indent=2))
