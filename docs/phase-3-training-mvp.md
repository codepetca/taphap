# Phase 3 training MVP

Implementation checkpoint [PR #4](https://github.com/codepetca/taphap/pull/4)
on the accepted Phase 2 merge `f4ab0fe`.
This checkpoint implements bounded local training; it is not a release.
Phase 2 musician/click comparison remains owner-deferred, not passed.

## Journey and conditions

Choose Tap or down-Strum and establish a baseline with three short Afterglow
First light trials. Only three complete, unassisted, fully scored attempts in
identical conditions establish that mode's reference. Invalid/partial attempts
remain visible and repeat the unfinished step. The reference is the median of
absolute landing error, consistency variation, and absolute drift separately;
one lucky landing cannot replace the other two observations.

Daily sessions contain a 34-second Afterglow warm-up, a progressive Tidepool
exercise, a second progression, and personalized Tidepool practice: approximately
3 minutes 45 seconds to 4 minutes 2 seconds of music,
plus preparation/result reading. The second progression stays on clear Tidepool
at level 0 and unlocks faster, subtler Lantern at level 1. No timer rushes the player through results.
After three distinct practice days, a checkpoint becomes available on a later
day. Three First light trials repeat the original benchmark condition. Then
three Paper Kite trials establish a separate transfer reference. Later transfer
sessions compare with that same song's reference. Benchmark and transfer errors
are never subtracted from one another or presented as general musicianship.

The UTC day convention is fixed, with a persisted nondecreasing day high-water
mark equal to the newest created session day. Resuming an older plan does not
advance this marker or move its original day. Changing timezone cannot reopen a day; backward clock travel cannot
reissue an earlier day. An offline app cannot verify a deliberately advanced
system clock. Clock travel in tests proves software scheduling only. A session
belongs to its start day and keeps its exact plan across relaunches. Finishing
an older session does not invent a session for every intervening day.

Interrupted trials invalidate normally and do not advance the step. Relaunch
resumes the next uncompleted step; a terminated in-flight trial must be replayed
from its opening, never resumed halfway through its silent interval. Restart
keeps prior trial records and marks the old run abandoned. Unfinished and
abandoned runs cannot become completed-session rewards.

## Scope to implementation

| Roadmap dimension | Concrete implementation |
| --- | --- |
| Gap length | Four bounded authored levels, 8/12/16 pulse gaps and 8 spaced-input intervals |
| Preparation | Opening gap positions reduce from 24 to 20 to 16 pulses; spaced pattern retains eight measured opening inputs |
| Placement | Two verified sections per level, selected deterministically by training day and session slot; fixed at session creation |
| Tempo | Tidepool 100 and Lantern 132 quarter pulses/minute, exposed as song choices rather than setup controls |
| Groove clarity | Lantern has a subtler authored percussion mix than Tidepool; both retain independently verified pulse attacks |
| Input pattern | Quarter pulses followed at the highest level by every-other-pulse Tap/down-Strum; reduced explicit input map, no inferred missing inputs |
| Personalization | Most recent accepted daily performance chooses current versus one easier level for the final challenge |
| Earned chapters | Two strong completed practice days at a level before advancing; bounded at level 3 |
| Baseline/checkpoints | Three compatible benchmark trials, metric-specific median differences |
| Transfer | Reserved Paper Kite song excluded from daily plans and free-practice next navigation |
| History/rewards | Local attempts and training sessions, previous/closest compatible landing, A/B/C grades and 0–3 stars |

Tempo and groove clarity are inseparable authored-song dimensions in this
bounded catalog; there is no time-stretching or arbitrary remix slider. Pattern
means event spacing, not inferred hand identity or alternating strum direction.
The accepted scorer measures downstrokes only; upstroke recognition remains
unsupported. No shared Phase 1 scoring or timing source is changed.

Stars require all thresholds jointly (landing / consistency / absolute drift):
3 stars and “Perfect landing”: ≤25 ms / ≤12 ms / ≤2 ms per input interval;
2 stars: ≤60 / ≤25 / ≤5; 1 star: ≤120 / ≤40 / ≤10; otherwise practice feedback.
These are transparent game tolerances, not a scientific universal skill scale.
Incomplete, invalid, partial, assisted and unvalidated-route attempts earn none.
The outside-timing-help switch explicitly marks practice with external cues.
VoiceOver direct-touch conditions remain separately recorded and do not advance
unassisted training. Actual assistive-use validation remains unobserved.

## Content and persistence

Afterglow audio, original catalog and original comparison content hash remain
unchanged. New oscillator-authored compositions use no borrowed recordings,
samples, lyrics, purchases or external licenses. See
[content provenance](../TapHapGame/Resources/PROVENANCE.md) and the reproducible
[generator](../scripts/generate-phase3-content.py). Exact audio hashes and
explicit beat maps are locked by the new catalog hash. The independent
[verifier](../scripts/verify-phase3-assets.py) inspects quiet lead-ins and attacks
in PCM rather than trusting synthesis loop times.

History schema 2 reads schema 1 preserving trial IDs, dates, comparison keys,
completion flags and assessments. Legacy trials are not retroactively assigned
to a baseline/session. Trial and step advancement share one atomic write.
New trials carry their persisted session ID and step; legacy/free-practice
records have no association and cannot be attached retroactively. Each plan
pins benchmark/training content identities. Changed content blocks the saved
step and requires restarting the session, preserving earlier attempts. The
history loader replays canonical scheduling and plans, verifies the latest created-session day
and every run/step link, including rejected attempts, and rejects impossible completed-abandoned or
out-of-order progress.

Unknown/corrupt history is preserved and disables writes and training; ordinary
failed writes keep pending attempts in memory and offer Save again. Training
cannot advance on an unsaved result. Restart and initial session creation also
must persist before the player begins. No deletion or reset-history UI exists.

The compatibility key retains content, challenge/map identity, mode, device
model, OS, route, sample rate, buffer duration, reported output latency,
assistance and scoring version. Incompatible checkpoints retain their own
summary without an improvement claim. The tested built-in speaker remains the
only enabled audio route. No other-device/route fairness claim is made.

## Verification status

Completed software checks: 37 portable tests, independent PCM/map verification,
initial 21-test native integration run, focused new-map rendered Strum fixture,
and a complete simulator baseline → relaunch/resume → three daily sessions →
later checkpoint → reserved transfer journey. Focused in-flight training tests
exercise route change, interruption, backgrounding, media reset and user stop:
all preserve the unfinished step and save an invalid attempt without rewards.
Atomic save failure/retry and unknown-history native tests pass. The actual
backed-up Phase 2 history also migrates with all ten trial objects unchanged,
zero invented sessions, and the source file untouched.

Native large-text preparation accessibility audit and navigation pass. The
oldest baseline summary is reachable at normal and maximum Dynamic Type; the
full journey asserts the known 60.0 ms synthetic checkpoint change. UTC history
dates and expanded summary layout were visually checked. Screens
are inspected alongside actual navigation and result assertions, not accepted
from screenshots alone. The initial full-journey UI test failed because its
control tap did not reliably scroll into view; the corrected test passes. Raw
failure evidence is retained. The signed app builds and is installed on the tested iPhone. All four focused
physical checks passed across the initial run and controlled retry: new spaced
Strum map on the real render clock, five armed-training invalidation cases,
atomic session/step persistence, and unknown-history protection. The initial
render run was invalidated by backgrounding during reported owner interference;
its failures remain preserved. The two affected tests passed unchanged on retry.
All ten existing real trials and ten diagnostic files remain byte-identical after
installation/testing. The normal game was relaunched without fixture flags.

Technical review is closed clean on implementation `1ae7aa6`: five reviewer
launches, two correction batches, 29 minutes 40 seconds. All 33 reviewed source
hashes remain unchanged. See the [review ledger](../.ai/evidence/phase3/review-ledger.md)
and [verification record](../.ai/evidence/phase3/verification.json).

The simulator-only UI fixture has isolated temporary storage and a visible
software-fixture label; it never writes real game history and scripted input
is compiled out of physical builds. Its clock travel, 80 ms synthetic baseline
and 20 ms synthetic retest demonstrate a known comparison, not real longitudinal
improvement. The genuine remaining Phase 3 exit observation is a new player's
first-use comprehension and interpretation of baseline/daily/checkpoint results.
The broader Phase 2 musician/click comparison remains deferred. Coordinator owns
phase acceptance; passing software tests does not fabricate human acceptance.

All new unique raw results, build products and signed app must be preserved under
`/Users/stew/.codex/taphap-baselines/01a0989f-1811-7a53-825d-84d761c57044/phase3-evidence/`.
The 18 frozen historical files remain protected; no Phase 1 phone app restoration.
