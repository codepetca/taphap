#!/usr/bin/env python3
"""Original TapHap compositions and explicit maps. No recordings/samples/dependencies.
Afterglow remains byte-for-byte frozen. New pieces: Tidepool (100), Lantern (132).
Authored oscillator arrangement with quiet phrase tails before each pulse.
"""
import array, hashlib, json, math, pathlib, struct, wave
R=pathlib.Path(__file__).resolve().parents[1]; O=R/'TapHapGame/Resources'; SR=48000
songs=[]; challenges=[]
for name,bpm,roots,melody,clarity in [
 ('Tidepool',100,[130.8128,103.8262,155.5635,116.5409],[0,7,12,10,7,3,5,7],1.0),
 ('Lantern',132,[146.8324,174.6141,130.8128,195.9977],[7,12,14,12,4,7,11,7],0.42),
 ('PaperKite',108,[123.4708,164.8138,146.8324,110],[12,7,3,7,14,12,10,7],0.8)]:
 period=60/bpm; count=112; duration=1+count*period+1
 pcm=array.array('d',[0])*round(duration*SR)
 def voice(at,dur,hz,amp,kind):
  for i in range(round(dur*SR)):
   t=i/SR; p=2*math.pi*hz*t; edge=min(1,t/.003,(dur-t)/.009)
   if kind=='kick': v=math.sin(p+8*(1-math.exp(-35*t)))*math.exp(-25*t)
   elif kind=='hat': v=(math.sin(p*1.71)+math.sin(p*3.13))*0.5*math.exp(-65*t)
   else: v=(math.sin(p)+.22*math.sin(2*p)+.09*math.sin(3*p))*math.exp(-8*t)
   pcm[round(at*SR)+i]+=v*edge*amp
 for beat in range(count):
  at=1+beat*period; root=roots[(beat//8)%4]
  voice(at,period*.42,49,.35*clarity,'kick')
  voice(at,period*.45,root/2,.23,'tone')
  voice(at,period*.12,2800,.06*clarity,'hat')
  if beat%2: voice(at,period*.23,190,.09*clarity,'hat')
  for interval in [0,3 if (beat//8)%4==0 else 4,7]:
   voice(at+period*.5,period*.37,root*2**(interval/12),.036,'tone')
  if beat%4!=0:
   voice(at+period*.5,period*.36,root*2**(melody[beat%8]/12+1),.085,'tone')
 values=array.array('h',(round(max(-.98,min(.98,v))*32767) for v in pcm))
 import sys
 if sys.byteorder!='little': values.byteswap()
 path=O/(name+'.wav')
 with wave.open(str(path),'wb') as w:
  w.setparams((1,2,SR,0,'NONE','not compressed')); w.writeframes(values.tobytes())
 digest=hashlib.sha256(path.read_bytes()).hexdigest()
 songs.append(dict(title=name,bpm=bpm,pulses=count,pickupSeconds=1,frameCount=len(pcm),audioSHA256=digest,grooveClarity=clarity))
 # 4 bounded levels, with two pre-authored placements (never randomized mid-trial).
 for level in range(4):
  for placement in range(2):
   stride=2 if level==3 else 1
   beats=[round((1+i*period)*SR) for i in range(0,count,stride)]
   gap=(24 if level==0 else 20 if level==1 else 16)+placement*4
   if stride==2: gap=12+placement*2
   length=[8,12,16,8][level]
   cid=f'{name.lower()}-l{level}-p{placement}'
   m=dict(revision=cid+'-v1',sampleRate=SR,frameCount=len(pcm),beats=beats,downbeatIndices=list(range(0,len(beats),4//stride)),baselineStartBeat=4,gapStartBeat=gap,returnBeat=gap+length,fadeFrames=4800)
   entry=dict(id=cid,title=f'{name} · '+['Find your footing','Hold a little longer','Carry the quiet','Leave room'][level],subtitle=['A clear pulse and time to settle.','A longer silence.','Less preparation before the gap.','Play every other pulse, leaving one between inputs.'][level],map=m,song=name,audioSHA256=digest,pattern='spaced' if stride==2 else 'pulse',level=level)
   if name!='PaperKite': challenges.append(entry)
   elif level==0 and placement==0: transfer=entry
# Fixed separate-song transfer condition. Never varies with adaptation.
transfer.update(id='transfer-paperkite',title='Paper Kite · Transfer',subtitle='A different song. Keep its pulse through the silence.')
challenges.append(transfer)
raw=(json.dumps(dict(revision='training-v1',songs=songs,challenges=challenges),indent=2)+'\n').encode()
(O/'training-catalog.json').write_bytes(raw)
p=R/'TapHapGame/App/ContentRevision.swift'
old=p.read_text().split('\n')[0]
p.write_text(old+'\nenum TrainingContentRevision { static let catalogSHA256 = "'+hashlib.sha256(raw).hexdigest()+'" }\n')
print(json.dumps(songs,indent=2))
