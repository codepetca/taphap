#!/usr/bin/env python3
"""Independent standard-library recomputation of private physical diagnostics.
Usage: python3 recompute-owner-trials.py PRIVATE_CAPTURE_DIR CATALOG_JSON
Writes sanitized aggregate findings to stdout; never emits IDs or raw event traces.
"""
import json, math, statistics, sys
from pathlib import Path

capture=Path(sys.argv[1]); catalog=json.loads(Path(sys.argv[2]).read_text())
ids=json.loads((capture/'new-trial-ids.json').read_text())
maps={c['id']:c['map'] for c in catalog['challenges']}
def mean(v): return sum(v)/len(v)
def fit(y):
    x=list(range(len(y))); mx=mean(x); my=mean(y)
    slope=sum((a-mx)*(b-my) for a,b in zip(x,y))/sum((a-mx)**2 for a in x)
    intercept=my-slope*mx
    residual=[b-intercept-slope*a for a,b in zip(x,y)]
    return intercept,slope,statistics.pstdev(residual)
def distribution(v):
    if not v: return None
    s=sorted(v)
    return {'count':len(s),'min':s[0],'median':statistics.median(s),'p95NearestRank':s[math.ceil(.95*len(s))-1],'max':s[-1],'populationSD':statistics.pstdev(s)}
rows=[]
for number,tid in enumerate(ids,1):
    raw=json.loads((capture/'game-records/Diagnostics'/(tid+'.json')).read_text())
    trial=raw['trial']; m=maps[trial['key']['challenge']]; ev=raw['events']; times=[e['trackSeconds'] for e in ev]
    assert trial['completed'] and trial['assessment']['kind']=='scored' and not trial['assessment'].get('invalidation')
    assert len(raw['crossingBracketsMS'])==(len(ev) if trial['key']['mode']=='strum' else 0)
    assert all(0<b<=50 for b in raw['crossingBracketsMS'])
    beats=[f/m['sampleRate'] for f in m['beats']]; begin=m['baselineStartBeat']; gap=m['gapStartBeat']; ret=m['returnBeat']
    assert all(math.isfinite(e[k]) for e in ev for k in ['trackSeconds','hostSeconds','observedHostSeconds'])
    assert all(a['trackSeconds']<b['trackSeconds'] and a['hostSeconds']<b['hostSeconds'] for a,b in zip(ev,ev[1:]))
    assert all(0<=e['observedHostSeconds']-e['hostSeconds']<=.25 for e in ev)
    assert all(e['mode']==trial['key']['mode'] and e.get('direction')==('down' if trial['key']['mode']=='strum' else None) for e in ev)
    nearest=lambda t:min(range(len(beats)),key=lambda i:abs(beats[i]-t))
    opening=[t for t in times if beats[begin]-.24<=t<beats[gap]-.24]; offsets=sorted(t-beats[nearest(t)] for t in opening)
    phase=offsets[len(offsets)//2]; assigned={}; min_margin=math.inf
    for t in times:
        index=nearest(t-phase)
        if not begin<=index<=ret+2:continue
        left=beats[index]-beats[index-1] if index else .5
        right=beats[index+1]-beats[index] if index+1<len(beats) else left
        margin=min(left,right)*.45-abs(t-phase-beats[index]);assert margin>0 and index not in assigned
        min_margin=min(min_margin,margin);assigned[index]=t-beats[index]
    assert all(i in assigned for i in range(begin,ret+3))
    baseline=[assigned[i] for i in range(begin,gap)]; base=fit(baseline)
    assert abs(base[1])<=.005 and base[2]<=.04
    held=[assigned[i]-mean(baseline) for i in range(gap+1,ret+1)]; hold=fit(held);half=len(held)//2
    acceleration=(fit(held[-half:])[1]-fit(held[:half])[1])/(len(held)-half);drift=hold[1]-base[1]
    diagnosis='jittered' if hold[2]>.018 else 'accelerated' if drift<-.002 else 'decelerated' if drift>.002 else 'shifted' if abs(mean(held))>.035 else 'steady'
    score={'diagnosis':diagnosis,'baselinePhaseMS':mean(baseline)*1000,'baselinePeriodMS':(mean([beats[i+1]-beats[i] for i in range(begin,gap-1)])+base[1])*1000,'baselineJitterMS':base[2]*1000,'consistencyMS':hold[2]*1000,'tempoDriftMSPerBeat':drift*1000,'accelerationMSPerBeatSquared':acceleration*1000,'phaseShiftMS':hold[0]*1000,'reentryMS':held[-1]*1000,'inputCount':len(assigned)}
    saved=trial['assessment']['score'];errors={k:abs(v-saved[k]) for k,v in score.items() if isinstance(v,(int,float))}
    assert diagnosis==saved['diagnosis'] and max(errors.values())<1e-6
    silence=[t for t in times if beats[gap]+m['fadeFrames']/m['sampleRate']<=t<beats[ret]]
    intervals=[(b-a)*1000 for a,b in zip(times,times[1:])]
    gap_intervals=[(b-a)*1000 for a,b in zip(silence,silence[1:])]
    rows.append({'trialLabel':f'owner-{number}','mode':trial['key']['mode'],'challenge':trial['key']['challenge'],'gapBeatSpanSeconds':beats[ret]-beats[gap],'fullZeroGainSeconds':beats[ret]-beats[gap]-m['fadeFrames']/m['sampleRate'],'completed':trial['completed'],'assessmentKind':trial['assessment']['kind'],'runtimeInvalidation':trial['assessment'].get('invalidation'),'eventCount':len(ev),'directionsVerified':True,'score':score,'independentScoreMaximumAbsoluteDifference':max(errors.values()),'minimumBeatAssignmentMarginMS':min_margin*1000,'wholeRunIntervalsMS':distribution(intervals),'silentIntervalsMS':distribution(gap_intervals),'wholeRunShortIntervals':sum(x<score['baselinePeriodMS']*.5 for x in intervals),'wholeRunLongIntervals':sum(x>score['baselinePeriodMS']*1.5 for x in intervals),'crossingBracketsMS':distribution(raw['crossingBracketsMS']),'occurrenceToObservationMS':distribution([(e['observedHostSeconds']-e['hostSeconds'])*1000 for e in ev]),'anchorCount':raw['anchorCount'],'maximumClockMismatchMS':raw['maximumClockResidualMS'],'conditions':{k:trial['key'][k] for k in ['mode','challenge','route','sampleRate','bufferDuration','outputLatency','assistance','system','scoringVersion']}})
print(json.dumps({'method':'Independent Python standard-library arithmetic on raw occurrence timestamps and committed beat map; does not invoke application scorer. Stored diagnoses and every numeric score field checked within 1e-6. Distribution SD uses population denominator; p95 uses nearest rank.','trials':rows},indent=2))
