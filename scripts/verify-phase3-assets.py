#!/usr/bin/env python3
"""Independent PCM attack inspection, exact asset locks and map validation."""
import hashlib,json,pathlib,struct,wave
R=pathlib.Path(__file__).resolve().parents[1]; O=R/'TapHapGame/Resources'
raw=(O/'training-catalog.json').read_bytes(); c=json.loads(raw)
assert hashlib.sha256(raw).hexdigest() in (R/'TapHapGame/App/ContentRevision.swift').read_text()
assert raw==(R/'TapHapGameTests/Fixtures/training-catalog.json').read_bytes()
report=[]
for song in c['songs']:
 p=O/(song['title']+'.wav'); digest=hashlib.sha256(p.read_bytes()).hexdigest()
 assert digest==song['audioSHA256']
 with wave.open(str(p)) as w:
  assert (w.getnchannels(),w.getsampwidth(),w.getframerate())==(1,2,48000)
  frames=w.getnframes(); samples=struct.unpack('<'+'h'*frames,w.readframes(frames))
 # Independent authored pulse specification; confirm quiet lead-ins and fresh attacks in PCM.
 bpm={'Tidepool':100,'Lantern':132,'PaperKite':108}[song['title']]
 beats=[round(48000+i*48000*60/bpm) for i in range(112)]
 offsets=[]
 for frame in beats:
  assert max(map(abs,samples[frame-240:frame]))==0
  onset=next(i for i,v in enumerate(samples[frame:frame+480]) if abs(v)>8)
  assert onset<=16; offsets.append(onset)
 maps=[ch for ch in c['challenges'] if ch['song']==song['title']]
 for ch in maps:
  m=ch['map']; stride=2 if ch['pattern']=='spaced' else 1
  assert m['beats']==beats[::stride] and m['frameCount']==frames
  assert m['downbeatIndices']==list(range(0,len(m['beats']),4//stride))
  assert m['gapStartBeat']-m['baselineStartBeat']>=8 and m['returnBeat']+2<len(m['beats'])
  assert ch['audioSHA256']==digest
 assert max(map(abs,samples))<32767
 report.append(dict(song=song['title'],audioSHA256=digest,verifiedAttacks=len(beats),maximumAttackOffsetFrames=max(offsets),maps=len(maps),durationSeconds=frames/48000,peakPCM=max(map(abs,samples))))
assert [x['id'] for x in c['challenges'] if x['song']=='PaperKite']==['transfer-paperkite']
print(json.dumps(dict(catalogSHA256=hashlib.sha256(raw).hexdigest(),songs=report,claim='PCM/map verification, not human listening or musician preference evidence'),indent=2))
