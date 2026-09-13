#!/usr/bin/env python3
"""Convert a private lab record to an anonymous deterministic timing-only replay.
Usage: python3 scripts/normalize-phase1-recording.py PRIVATE_INPUT OUTPUT
Never put private input paths, wall time, original host epochs, IDs or route names in output.
"""
import json,pathlib,sys
source=json.loads(pathlib.Path(sys.argv[1]).read_text())
events=[]
for event in source['events']:
 t=round(event['trackSeconds'],6)
 out={'trackSeconds':t,'hostSeconds':round(1000+t,6),'observedHostSeconds':round(1000+t+event['observedHostSeconds']-event['hostSeconds'],6),'mode':event['mode']}
 if event.get('direction'):out['direction']=event['direction']
 events.append(out)
result={'provenance':'Physical feasibility capture normalized to track-relative microsecond precision and an artificial host epoch; no identity, date, route name or original host epoch.','events':events}
pathlib.Path(sys.argv[2]).write_text(json.dumps(result,indent=2)+'\n')
