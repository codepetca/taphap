# Phase 1 core audio and scoring feasibility

Status: **Phase 1 feasibility accepted** by the coordinator for the tested
physical iPhone 16 built-in speaker setup. All five roadmap exit bullets are
supported; see the final acceptance section below and
[acceptance record](../.ai/evidence/phase1/phase-exit-acceptance.json).
Checkpoint PR #2 is ready for its authorized merge. Phase 2 has not begun in
this task. The chronological sections retain earlier blockers and decisions
as historical evidence; the final acceptance decision supersedes them.

## Authority and preserved baseline

Owner instruction delegated by coordinator `01a0989f-1811-7a53-825d-84d761c57044`
authorizes local Phases 1–3 in order, superseding the documentation-only lock.
This task implements Phase 1 only. Later owner authorization permits in-scope
commits, pushes, PRs and merges **for this scope; merge only after each phase exit gate is satisfied**.
No release activity or excluded integrations are authorized. Draft checkpoint publication is authorized while physical acceptance is pending;
merge and Phase 2 advancement remain gated. Check the review ledger for the
current checkpoint state.

Worktree: `/Users/stew/.codex/worktrees/844e/taphap`.
Inherited HEAD: `2e0310bc245525e82ace4110c103681e6facfe55`.
Before changes a Python SHA-256 comparison against the coordinator's
[inherited baseline](../.ai/evidence/inherited-baseline.json) returned
`verified: 29, discrepancies: []`. The baseline includes owner-modified
product documents and an untracked historical lab, not a clean main checkout.
The coordinator's authority note and coordination record were copied locally.

Historical `TapHapLab/`, `TapHapLabTests/`, `TapHapLab.xcodeproj/`, `project.yml`,
and historical feasibility documentation remain unchanged. `Package.swift`
adds a separate `Phase1Core` library/test target while retaining the old targets.
`phase1-project.yml` generates a separate `TapHapPhase1.xcodeproj` and iPhone
app identifier `ca.codepet.taphap.phase1`; it does not regenerate the old project.

## Reproducible music and map

See [asset provenance](../Phase1Lab/Resources/PROVENANCE.md) and
[asset verification](../.ai/evidence/phase1/asset-verification.json).
The original local instrumental fixture uses no imported music or samples.
Its independently enumerated map contains 64 quarter-note positions at 48 kHz.
Verification against decoded PCM found all 64 attacks within 3 samples of the
mapped onset. The app rejects mismatched WAV or map hashes before playback.
This is a test composition, not the polished Phase 2 song.

## Audio schedule and clocks

The entire 34-second mono PCM buffer is decoded and multiplied by an immutable
raised-cosine gain envelope at exact integer sample positions before it is
queued once on `AVAudioPlayerNode`. The renderer traverses every frame. No
pause, seek, buffer replacement, UI-timer gain update, looping or playback-rate
change occurs during the trial. Pre-rendering the gain envelope is deliberate
for this one fixed challenge; it is not an adaptive runtime scheduling API.

| Boundary | Sample | Track seconds |
| --- | ---: | ---: |
| First beat | 48,000 | 1.0 |
| Baseline beats 4–15 | 144,000–408,000 | 3.0–8.5 |
| Fade out begins, beat 16 | 432,000 | 9.0 |
| Exact digital silence begins | 436,800 | 9.1 |
| Return fade begins, beat 32 | 816,000 | 17.0 |
| Full return gain | 820,800 | 17.1 |
| File end | 1,632,000 | 34.0 |

Touch host timestamps are converted with contemporaneous
`lastRenderTime` / `playerTime(forNodeTime:)` pairs to the player sample domain.
`AVAudioTime` host ticks are converted to boot-relative seconds; UIKit's
`UITouch.timestamp` supplies occurrence time. Observed host time measures input
and anchor age. Wall-clock `Date` appears only in local record provenance.
The UI's 50 ms observer updates an unmarked whole-track progress bar and reads
completion; it does not schedule a gap or define a score timestamp.

There is **no guessed route-latency subtraction**. The recorded session output
latency is informational, and the audible input fit estimates the combined
route/input/player phase preference. It does not isolate acoustic latency.
The player render clock is not a measurement of sound leaving the speaker.
A stable route is required; comparisons across routes are not validated.

Input conversion rejects anchors/input older than 250 ms, future/nonfinite
values, and clock progression mismatches greater than 2 ms. Route changes,
interruptions, engine reconfiguration/media reset, loss of app activity,
cancelled contact and multiple simultaneous contacts invalidate the trial.
No background playback mode is requested. Startup latches environmental
invalidations before arming; cancelled startup generations cannot become active.
A media-services reset also rebuilds the engine and player before retry.

## Tap, Strum and scoring

Tap uses the actual `UITouch.timestamp` at touch-down. Strum consumes actual
coalesced touch samples, interpolates the crossing of one fixed horizontal
reference line, records up/down direction and the time bracket, and emits once
per contact. A lift rearms the next stroke. Predicted touches and gesture-end
timing are excluded. A crossing spanning more than 50 ms is ambiguous. This
phase scores downstrums; an upstroke is recorded but invalidates that exercise.
Physical repeatability remains unproven by interpolation tests.

The surface and instructions are static during the trial. The progress bar has
no beat/bar markers, pulses, countdown, haptics or rhythmic animation. Diagnostic
counts and scores appear after the trial only. This is an engineering lab,
not Phase 2 navigation, onboarding, art or a claim of accessibility completion.

Scoring first fits the twelve mapped audible inputs (beats 4–15). A baseline
with residual jitter over 40 ms or slope over 5 ms/beat is invalid. The median
opening offset seeds one-to-one nearest-beat assignment; missing, duplicate,
out-of-order, wrong-direction and ambiguous events are invalid, not discarded
as favorable outliers. Required scored indices are 4–34. Fade-out beat 16 is
excluded from gap fitting; beats 17–32 measure the hold and landing.

Reported metrics are audible baseline phase/period/jitter, gap consistency
(linear-fit residual RMS), tempo drift (gap slope minus baseline slope),
acceleration (difference of half-gap slopes), phase shift (gap fit intercept),
and re-entry (return-beat residual relative to audible mean phase). Positive
landing is late, negative is early. Consistency includes nonlinear tempo
variation; it is not a pure hardware precision estimate. No composite grade or
longest reliable-gap claim is made from this single challenge.

Diagnostics prioritize jitter above 18 ms, then signed drift beyond 2 ms/beat,
then a shift above 35 ms, otherwise steady. These are explicit engineering
thresholds awaiting musician validation, not universal proficiency standards.
Quarter-note assignment is bounded to less than 45% of the local beat interval
around fitted phase; large drift/missed beats are invalid or phase-ambiguous,
not a claim to recover arbitrary rhythmic intent. Stable whole-beat latency
aliases cannot be resolved from this exercise alone.

## Verification commands and results

Run from this worktree. Xcode 26.6 (17F113), Swift supplied by Xcode; iOS simulator
26.5, iPhone 17 Pro. Sanitized results under `.ai/evidence/phase1/`; raw logs and device details
remain in ignored `.ai/evidence/phase1/local/` and `build/`. Bulky build products and
`.xcresult` bundles stay under ignored `build/`.

```sh
python3 scripts/generate-phase1-track.py
python3 scripts/verify-phase1-assets.py
python3 scripts/generate-phase1-fixtures.py
swift test
xcodegen generate --spec phase1-project.yml
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination 'platform=iOS Simulator,id=A313A055-3B36-49D8-8A93-1D7C139EAA29' -derivedDataPath build/Phase1Simulator -resultBundlePath build/Phase1SimulatorTests-3.xcresult test
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination 'generic/platform=iOS' -derivedDataPath build/Phase1Device build-for-testing
xcodebuild -project TapHapLab.xcodeproj -scheme TapHapLab -destination 'generic/platform=iOS Simulator' -derivedDataPath build/Historical build-for-testing
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination 'platform=iOS Simulator,id=A313A055-3B36-49D8-8A93-1D7C139EAA29' -derivedDataPath build/Phase1Simulator -only-testing:TapHapPhase1Tests/LifecycleTests -resultBundlePath build/Phase1LifecycleFinal.xcresult test
```

- Asset verification: 64/64 mapped attacks; hashes above.
- `swift test`: 13 tests passed, including all 7 inherited tests and 6 new core
  tests. Twenty-two recorded Tap/Strum fixture files exercise five diagnoses
  and invalid inputs; successful scores are repeated ten times identically.
- iOS simulator: 11 tests passed. Offline rendering traversed 1,632,000 frames,
  with gap energy 0 and positive return energy. Unchanged PCM before the fade
  and after full return is asserted against the source at the same indices.
- Simulator real-time render-clock traversal: 651 anchors, all five boundaries
  crossed, maximum host/sample progression residual 0.018583 ms. This is a
  render consistency result, not physical audio latency or touch precision.
- Final startup-guard revision: 2 targeted lifecycle tests passed, including
  all five notification types during preparation and media reset followed by render.
- Signed iOS app and test bundle: `TEST BUILD SUCCEEDED` using existing local
  signing. No account or signing configuration changes were made.
- Preserved historical app/test build: `TEST BUILD SUCCEEDED`.

Recorded fixture examples (same timing results for Tap and down-Strum):

| Input | Diagnosis | Consistency ms | Drift ms/beat | Re-entry ms |
| --- | --- | ---: | ---: | ---: |
| Steady, opening offset +42 ms | steady | ~0 | ~0 | ~0 |
| Quadratic speed-up | accelerated | 8.502 | -7.650 | -115.2 |
| Quadratic slow-down | decelerated | 8.502 | +7.650 | +115.2 |
| Alternating jitter | jittered | 43.053 | +0.647 | +35 |
| Stable phase step +90 ms | shifted | ~0 | ~0 | +90 |

## Physical device attempts and remaining protocol

Paired iPhone 16, iOS 26.6.2 (23G90), developer mode enabled.
Device identifiers are retained only in ignored local evidence. Set
`TAPHAP_DEVICE_ID` to the paired CoreDevice identifier from `xcrun devicectl
list devices` and `TAPHAP_DEVICE_UDID` to its Xcode destination from
`xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -showdestinations`.

```sh
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination "platform=iOS,id=$TAPHAP_DEVICE_UDID" -derivedDataPath build/Phase1Device -resultBundlePath build/Phase1DeviceTests.xcresult test
xcrun devicectl device install app --device "$TAPHAP_DEVICE_ID" build/Phase1Device/Build/Products/Debug-iphoneos/TapHapPhase1.app --timeout 45 --json-output build/device-install.json
```

The initial physical test attempt could not begin: Xcode reported that the developer
disk image could not be mounted. CoreDevice reports paired/connected, developer
mode enabled, but DDI services unavailable. Direct installation failed with CoreDevice error 12040 / MobileDevice
`0xe80000e2`, explicitly `kAMDMobileImageMounterDeviceLocked`: the device is
locked. A separate lock-state query confirmed `passcodeRequired: true`. The
owner subsequently unlocked the phone, which resolved installation and test
execution. No signing, account, system configuration or source change was needed.
A separate unattended simulator launch traversed the full track, saved 681
clock observations locally, and correctly produced `missingInput` with no
score. The static surface and post-trial invalid result were visually inspected.
This exercises the app record path, not physical contact or acoustic output.

The owner later confirmed the audible loop and completed two Tap trials and
one Strum trial. This establishes observed playback and real input capture,
not a passing score or independently measured acoustic re-entry latency.

On resumption, the existing signed build installed successfully and all 11
physical-iPhone tests passed in 38.737 seconds. The speaker route ran at 48 kHz
with 5 ms I/O buffers. The full render-clock run collected 643 anchors, crossed
all five boundaries and measured a maximum host/sample progression mismatch of
0.003917 ms. Reported output latency was 15.354 ms; it was recorded, not
subtracted or claimed as measured acoustic latency. See
[physical-device test evidence](../.ai/evidence/phase1/physical-device-tests.json).

```sh
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination "platform=iOS,id=$TAPHAP_DEVICE_UDID" -derivedDataPath build/Phase1Device -resultBundlePath build/Phase1PhysicalUnlocked.xcresult test-without-building
xcrun devicectl device process launch --device "$TAPHAP_DEVICE_ID" --terminate-existing ca.codepet.taphap.phase1
```

The lab was launched successfully without automatic playback and left ready
for owner input. The test harness creates zero-input invalidation records;
a pre-owner local snapshot distinguishes those from actual human trials.
No repeat of these passed tests is needed absent a relevant change.
The original proposed human protocol below is retained for context; five
trials per mode was an engineering proposal, not a ratified quota. The actual
three trials already reveal a concrete scoring limitation. Additional retries
solely to meet that count are not justified; address the recorded limitation
first, then use a targeted check. Proposed protocol:

1. Use the built-in speaker at a comfortable audible level. Record route and
   device, input mode, session, and listening observations. Do not change volume
   or route mid-trial. Test a wired route separately if it is intended for MVP;
   Bluetooth is not validated by a speaker result.
2. Perform five Tap trials, then five down-Strum trials. Start at the first
   musical pulse and continue quarter notes through the silence and return.
   Keep tapping/strumming until the trial finishes. Do not follow an external
   click or ask another person to cue the gap.
3. Confirm each audible-to-silent-to-audible loop: music advances through the
   gap, no pause/restart is heard, return is musical and the surface provides
   no continuing beat cue. Record a failure verbatim rather than overriding it.
4. Export `Documents/Phase1Trials/*.json` using Xcode/device file sharing.
   Preserve invalid trials. Check clock residuals, mode/direction, event and
   bracket distributions, baseline variability, and score spread. Investigate
   missed or duplicate contacts. Proposed engineering acceptance: at least
   4/5 valid trials per mode, no clock invalidations, median within-trial
   Strum crossing bracket <=16.7 ms and 95th percentile <=33.4 ms, and no
   unexplained >20 ms difference in repeated stable audible phase estimates.
   Human variability can fail these targets; a failure requires inspection,
   not removal of the trial. These targets do not establish absolute touch
   latency without independent contact measurement.
5. Have a musician deliberately hurry, slow, jitter and shift during extra
   trials, report whether diagnoses and early/late landings are credible, and
   note perceptual ambiguity caused by the 100 ms return fade. For claims of
   absolute acoustic/contact precision, use independent synchronized
   measurement (e.g. externally recorded high-speed contact/audio reference),
   under a separate agreed measurement setup; simulator injection is insufficient.

## Actual owner observations and current gate

The owner confirmed: **“yes, music did as expected - silent then returned.”**
This supports the complete acoustic-loop observation for this owner/device/route.
It does not measure acoustic latency or prove behavior on other routes.

The three real trials are distinct from five zero-input records produced by
lifecycle tests. See [sanitized human evidence](../.ai/evidence/phase1/owner-observations.json).
Raw host timestamps, trial filenames and full traces remain local and ignored.

| Measure | Tap 1 | Tap 2 | Strum 1 |
| --- | ---: | ---: | ---: |
| Captured events | 64 | 63 | 61 |
| Audible fitted period, ms | 498.636 | 501.278 | 496.175 |
| Audible residual RMS, ms | 12.581 | 13.602 | 12.543 |
| Audible mean phase, ms | -3.038 | -5.928 | +34.821 |
| Silent input interval median, ms | 557.480 | 557.516 | 542.964 |
| Largest silent input interval, ms | 582.353 | 599.093 | 1070.581 |
| Maximum clock progression mismatch, ms | 0.003583 | 0.008833 | 0.006458 |
| Official result | ambiguousInput | ambiguousInput | ambiguousInput |

All event times are monotonic; no route/lifecycle or stale-clock invalidation
occurred. The two Tap audible phase estimates differ by 2.889 ms, and both
show a similar slowing pattern in silence. That is promising repeat evidence
for capture under these conditions, not a hardware-precision measurement.

All 61 Strum crossings were downward. Their timestamp brackets were median
8.321 ms, 95th percentile 8.324 ms, maximum 16.642 ms. This supports within-trial
crossing resolution. The 1070.581 ms silent interval could be an omitted stroke
or a crossing not captured; no touch-path record proves which. One Strum trial
does not establish between-trial repeatability. Dispatch delay is recorded
separately and not substituted for touch occurrence time.

No official score was emitted in any trial. The nearest-beat assignment guard
rejects a phase-adjusted offset of 225 ms or more. Both Tap traces contain
useful slowdown evidence despite crossing that bound; Strum additionally has
an unresolved missing-stroke possibility. The rejection prevents invented
beat identities, but the current all-or-nothing result discards useful timing
feedback. These observations expose a model/reporting limitation that the
small-drift deterministic fixtures did not establish as usable for human play.

Smallest recommended next implementation: retain safe audible baseline and
observed-interval trend/consistency diagnostics when beat-relative landing is
ambiguous, and explain the unavailable measure separately. Do not simply widen
the nearest-beat threshold or assume away omitted/duplicate strokes. Replay
normalized versions of these recordings plus explicit phase-wrap and
missed/duplicate fixtures locally before asking for another targeted physical
result check. This recommendation was reported before modifying source. The local
correction below is now implemented and tested; the installed phone app has
not been changed.

The acoustic-loop criterion is now observed. Full Phase 1 remains open because
real trials have not demonstrated useful trustworthy scoring, and Strum
repeatability is not established. The coordinator must not merge or advance
Phase 2 until the remaining gate is addressed.

## Apple documentation reviewed

Reviewed 2026-09-12 via Apple's published Markdown versions (web renderer
requires JavaScript). Public API references:

- [AVAudioPlayerNode](https://developer.apple.com/documentation/avfaudio/avaudioplayernode): buffer scheduling and player/node time conversion.
- [AVAudioTime](https://developer.apple.com/documentation/avfaudio/avaudiotime): distinct host/sample representations.
- [UITouch.timestamp](https://developer.apple.com/documentation/uikit/uitouch/timestamp): boot-relative touch occurrence time.
- [UIEvent.coalescedTouches](https://developer.apple.com/documentation/uikit/uievent/coalescedtouches(for:)): actual coalesced movement samples.

Local implementation details and measured results above are evidence from this
lab, not claims that Apple guarantees acoustic timing or scoring validity.

## Correction after physical feedback — reviewed; targeted device results below

`Assessor` now separates full scores, partial diagnostics, and invalid capture.
`Scorer` keeps the exact same 45%-of-beat assignment limit; shared validation
and assignment helpers preserve all prior deterministic full-score results.
The correction never invents missed beats, unwraps a phase slip, or assigns a
landing from ambiguous observations.

When a one-to-one audible baseline is valid but later assignment fails, the
lab retains that baseline and the median/spread of actual successive inputs
inside full digital silence. At least six intervals are required. Intervals
under half or over one-and-a-half of the audible period flag possible extra
or missed input; these are descriptive warnings, not corrected beat counts.
A contaminated clock, route/lifecycle interruption, malformed event, wrong
direction, or untrustworthy audible baseline prevents partial timing claims.
An ambiguous Strum crossing detected during capture remains fully invalid;
it is distinct from ambiguity discovered later by beat assignment.

The three normalized physical replays now yield partial results:

- Tap 1: opening 499 ms; silent median spacing 557 ms; inputs farther apart;
  landing unavailable, no full score.
- Tap 2: opening 501 ms; silent median spacing 558 ms; inputs farther apart;
  landing unavailable, no full score.
- Strum 1: opening 496 ms; uneven spacing with a possible missed/extra input;
  landing unavailable, no full score.

The persisted diagnostic schema is version 2. Runtime `invalidations` remain
separate from `assessment.scoreIssue`; `score` is absent for partial and invalid
results. Old version-1 records are preserved as historical evidence.
Normalized replay fixtures contain track-relative values and an artificial
host epoch, with no original identity, wall time, route name, or record ID.

Verification: 21 Swift package tests passed (all 7 inherited tests included),
16 affected iOS simulator tests passed, and the new signed device build passed.
Unchanged audio-render tests retain the earlier physical evidence. Commands:

```sh
swift test
xcodegen generate --spec phase1-project.yml
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination 'platform=iOS Simulator,id=A313A055-3B36-49D8-8A93-1D7C139EAA29' -derivedDataPath build/Phase1AssessmentSimulator -skip-testing:TapHapPhase1Tests/AudioTests -resultBundlePath build/Phase1AssessmentTests.xcresult test
xcodebuild -project TapHapPhase1.xcodeproj -scheme TapHapPhase1 -destination 'generic/platform=iOS' -derivedDataPath build/Phase1AssessmentDevice build-for-testing
```

See [assessment verification](../.ai/evidence/phase1/assessment-verification.json)
and [current patch hashes](../.ai/evidence/phase1/assessment-source-sha256.json).
This correction has passed the owner-approved extended review: focused Sol/high
and cumulative Terra/high found no new implementation blockers on commit
`4be17f7824d08c276fe36fd493d9ad78491de26e`. Both finished within the
20-minute individual and 30-minute additional total caps; exact activity
timestamps are in the review ledger. No additional reviewer or review reset
occurred. The corrected physical result path and Strum repeatability still
need a targeted check. No quota of repeat trials is imposed, and no phase-exit
pass or merge follows from technical review alone.


Installation attempt after completed reviews: the phone still listed as
paired/available, but both its lock-state query and installation failed with
CoreDevice error 4000 and Network.NWError 54, “Connection reset by peer.”
This does not prove that the phone is locked. The corrected build was not
installed and the existing app/records were not replaced. Wake/unlock and
restore the connection (USB if necessary), then install the existing signed
build in `build/Phase1AssessmentDevice/Build/Products/Debug-iphoneos/`.
One Tap and one further down-Strum trial are the next targeted checks of the
changed result path and Strum repeatability; the acoustic loop is already
owner-confirmed. No additional source or review work is required for this
unchanged revision before that device check.


Subsequent owner-on attempt on 2026-09-13 at 09:28 America/Toronto succeeded:
lock-state query returned unlocked, the existing reviewed signed assessment
build installed, and the lab launched without autorun. All eight prior trial
records (five lifecycle-test records and three owner trials) were verified
byte-for-byte unchanged after the update. No pairing, account, signing, or
network-settings changes were needed. See
[installation evidence](../.ai/evidence/phase1/assessment-installation.json).
The connection blocker is resolved; one Tap and one further down-Strum trial
are pending to exercise the corrected physical result path and repeatability.


## Targeted owner trials on the reviewed correction — 2026-09-13

After the owner reported completing one Tap and one Strum trial, read-only
retrieval found exactly two new schema-2 records. All eight prior records
remained byte-for-byte unchanged. Both new records contain partial assessments
with no runtime invalidation and no full score or landing. All 50 reviewed
source hashes remain unchanged. See
[targeted observations](../.ai/evidence/phase1/targeted-owner-observations.json).

| Measurement | Tap 3 | Strum 2 |
| --- | ---: | ---: |
| Captured inputs | 63 | 64 downstrokes |
| Opening fitted period | 495.15 ms | 503.31 ms |
| Opening residual RMS | 11.36 ms | 13.18 ms |
| Silent median input spacing | 549.03 ms | 533.95 ms |
| Largest silent interval | 582.28 ms | 1030.34 ms |
| Silent interval standard deviation | 22.68 ms | 137.48 ms |
| Maximum host/sample clock residual | 0.004875 ms | 0.005417 ms |
| Full-score assignment issue | missingInput | ambiguousInput |

The saved Tap assessment supports descriptive slower spacing during silence.
Its full-score missing-input classification is a failed beat assignment, not
proof that the owner physically omitted a tap. The Strum assessment correctly
flags uneven spacing and possible missing/extra input instead of attributing
all variation to tempo slowdown. Independent recalculation of silent interval
count, median, population standard deviation and maximum matched both saved
assessments within 0.000001 ms. This verifies the corrected physical assessment
and persistence path; it does not establish subjective display acceptance.

Strum crossing brackets were median 8.32 ms, nearest-rank p95 16.64 ms and
maximum 33.28 ms (the first stroke). Both Strum trials had similar opening
residual RMS (12.54 and 13.18 ms), but each included one roughly one-second
silent interval. Event records alone cannot distinguish a skipped/held gesture
from missed capture. The owner has been asked whether they recall skipping or
holding a stroke. No additional trial quota, source change, phase-exit pass,
merge, or Phase 2 advancement follows from these observations.


## Roadmap exit-gate assessment after targeted trials

This maps the five actual Phase 1 exit bullets, not an added trial quota or
player-performance threshold. A correctly withheld uncertain landing with
trustworthy partial diagnostics is valid scoring behavior. The owner does not
need to earn a full score for the phase to pass.

| Roadmap exit bullet | Evidence and assessment |
| --- | --- |
| Audio fades and returns on the mapped timeline without pause, seek, or drift. | Supported for the built-in speaker lab: sample-indexed envelope, offline traversal of all 1,632,000 frames with zero silent energy and unchanged post-return PCM, and physical render progression across every boundary. Maximum automated physical host/sample residual was 0.003917 ms. These measurements establish the digital timeline; they are not independent acoustic latency measurements. |
| Identical simulated inputs receive stable results. | Supported: 22 recorded fixtures across both modes; successful scores repeated ten times for exact equality. Corrected assessment tests preserve full scores and deterministic partial/invalid outcomes. |
| Deliberate acceleration, deceleration, jitter, and phase shifts produce the expected diagnosis. | Supported in both modes by the recorded fixtures: acceleration/deceleration produce opposite expected drift and re-entry signs, jitter is diagnosed, and the shifted fixture yields 90 ms phase/re-entry with zero drift. Missing/duplicate and contamination fixtures remain distinct from trustworthy results. |
| Tap and Strum timestamps are repeatable enough for musician-credible scoring. | Partially supported, unresolved overall. Three Tap opening fits have residual RMS 11.36–13.60 ms and periods 495.15–501.28 ms. Two Strum fits have residual RMS 12.54/13.18 ms and phases 34.82/26.18 ms, with actual coalesced crossing timestamps and measured interpolation brackets. However, both Strum traces contain a roughly one-second interval, and no full gesture trace or independent contact observation distinguishes omitted gesture from missed capture. Similar baseline statistics alone do not settle capture completeness. Owner recollection is pending; no full-score requirement is imposed. |
| A physical-device run confirms the complete audible-to-silent-to-audible loop. | Supported: owner explicitly confirmed that music became silent then returned, alongside physical render evidence. This conclusion covers the tested iPhone built-in speaker route. Other audio routes have not been validated. |

Recommendation at that checkpoint: **hold Phase 1 acceptance and merge pending resolution
of the Strum capture uncertainty**. Four exit bullets are supported within the
recorded device/route scope; the timestamp-repeatability bullet remains open.
The proposed physical protocol is a means of collecting evidence, not an
additional exit gate. A reply confirming a remembered skipped gesture would
explain that interval but must be considered alongside the earlier Strum trace;
a reply that strokes continued steadily would leave possible missed capture
as a concrete issue to investigate. No new source work or repeated physical
trial has been initiated while this observation is pending.


## Owner-requested Strum retry — 2026-09-13

The owner chose another Strum trial and reported completion. Read-only
retrieval found one new schema-2 record and verified all ten prior records
byte-for-byte unchanged. The reviewed app was not reinstalled or relaunched.
See [Strum retry observations](../.ai/evidence/phase1/strum-retry-observations.json).

The new trial captured 65 monotonic downstrokes. Opening fitted period was
502.34 ms, phase 39.51 ms and residual RMS 11.80 ms. Inside silence the median
spacing was 530.65 ms, standard deviation 13.23 ms and largest interval
559.96 ms, with no long or short interval flags. All recorded successive
intervals across the entire trial were also continuous, with no approximately
one-second gap. Crossing brackets were median 8.32 ms, nearest-rank p95
8.323 ms and maximum 16.64 ms. All 746 clock anchors remained consistent
(maximum residual 0.006 ms); runtime invalidations were empty.

The saved partial assessment correctly describes inputs spreading farther
apart in silence. Beat assignment remains ambiguous, so landing and full
score remain unavailable; that is not a failed performance requirement.
Independent silent-interval recalculation matched the saved values within
0.000001 ms, and all 50 reviewed source hashes remained unchanged.

The three Strum opening residual RMS values are now 12.54, 13.18 and 11.80 ms;
opening phases are 34.82, 26.18 and 39.51 ms. This clean continuous trial adds
positive evidence for repeatable Strum timestamps. It does not retrospectively
identify the cause of either earlier long interval, or rule out intermittent
missed capture. The other four roadmap exit-bullet assessments above remain
unchanged. The coordinator has been asked to reassess the remaining timestamp
repeatability bullet against this new evidence, retaining the historical
uncertainty explicitly. No additional trial quota or full-score requirement
has been added, and no source change, merge or Phase 2 work followed.


## Final coordinator acceptance and checkpoint completion

The coordinator accepted all five Phase 1 exit requirements after inspecting
the clean Strum retry and the exact roadmap matrix. The digital mapped audio
loop, deterministic results, deliberate-error diagnoses, repeated physical
timestamps and owner-confirmed audible loop are supported within the tested
iPhone 16 built-in speaker scope. The accepted mapping is recorded in
[phase-exit acceptance](../.ai/evidence/phase1/phase-exit-acceptance.json).

The timestamp requirement is supported by three comparable Tap and Strum
opening baselines plus the latest 65 continuous downstrokes (all 64 intervals
461.86–559.96 ms), tight crossing brackets, stable clocks and independently
verified physical partial assessments. An uncertain landing is correctly
withheld; a player earning a full score is not an exit requirement.

The earlier two approximately one-second Strum intervals remain unexplained.
Acceptance does not identify them as owner omissions or rule out intermittent
missed capture. Retain them as a Phase 2 input-reliability observation; if
missed capture is reproducible, repair the engine before product-test
acceptance. No absolute contact timing, universal route fairness, or release
readiness is claimed. No further trial quota is imposed.

Final checkpoint changes reconcile current authority/status guidance and copy
the latest coordinator-owned context. The archived inherited manifest and
frozen historical lab remain byte-for-byte preserved. The separate reviewed
implementation remains exactly `4be17f7824d08c276fe36fd493d9ad78491de26e` by all
50 source-manifest hashes; no new implementation or reviewer was introduced.
Existing successful tests and completed bounded reviews remain applicable.
See [baseline preservation](../.ai/evidence/phase1/baseline-preservation.json)
for the final explicitly authorized documentation changes to inherited paths.
