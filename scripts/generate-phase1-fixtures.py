#!/usr/bin/env python3
"""Record explicit input fixtures from independently specified analytic behaviors."""
import json,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
for mode in ['tap','strum']:
 for name in ['steady','accelerated','decelerated','jittered','shifted','missing','duplicate','unstable','upstroke','nonfinite_clock','route_changed']:
  events=[]
  for beat in range(64):
   offset=.042
   if 16<=beat<=34:
    k=beat-16
    if name=='accelerated': offset-=.00045*k*k
    if name=='decelerated': offset+=.00045*k*k
    if name=='jittered': offset+= [.035,-.035,.05,-.05][beat%4]
    if name=='shifted': offset+=.09
   if name=='unstable' and 4<=beat<16: offset+=.075*(-1 if beat%2 else 1)
   if name=='missing' and beat==22: continue
   t=1+beat*.5+offset
   e=dict(trackSeconds=t,hostSeconds=1000+t,observedHostSeconds=1000+t+.004,mode=mode)
   if mode=='strum': e['direction']='up' if name=='upstroke' and beat==24 else 'down'
   if name=='nonfinite_clock' and beat==24: e['observedHostSeconds']=e['hostSeconds']-1
   events.append(e)
   if name=='duplicate' and beat==22: events.append(dict(e,trackSeconds=t+.025,hostSeconds=1000+t+.025,observedHostSeconds=1000+t+.029))
  expected=name if name in ['steady','accelerated','decelerated','jittered','shifted'] else {'missing':'missingInput','duplicate':'duplicateInput','unstable':'unstableBaseline','upstroke':('invalidDirection' if mode=='strum' else 'steady'),'nonfinite_clock':'malformedInput','route_changed':'routeChanged'}[name]
  payload=dict(name=name,mode=mode,expected=expected,invalidations=['routeChanged'] if name=='route_changed' else [],events=events)
  (root/'Phase1LabTests/Fixtures'/f'{mode}-{name}.json').write_text(json.dumps(payload,indent=2)+'\n')
