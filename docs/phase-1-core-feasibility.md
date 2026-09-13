# Phase 1 core audio and scoring feasibility

Status: implemented locally; phase exit **not yet passed**. Physical playback
and musician input observations remain mandatory. Phase 2 has not begun.

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

The physical test attempt could not begin: Xcode reported that the developer
disk image could not be mounted. CoreDevice reports paired/connected, developer
mode enabled, but DDI services unavailable. Direct installation failed with CoreDevice error 12040 / MobileDevice
`0xe80000e2`, explicitly `kAMDMobileImageMounterDeviceLocked`: the device is
locked. A separate lock-state query confirmed `passcodeRequired: true`. The
next device action is to unlock the paired iPhone and leave it awake while
the existing signed build is installed and the automated tests run.
A separate unattended simulator launch traversed the full track, saved 681
clock observations locally, and correctly produced `missingInput` with no
score. The static surface and post-trial invalid result were visually inspected.
This exercises the app record path, not physical contact or acoustic output.

No physical audible loop, actual Tap/Strum trial, route repeatability, or
acoustic re-entry has been marked passed.

After device services are available, rerun the automated iOS tests on the phone
and launch the installed lab. A human observer must then:

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

The exact remaining gate is physical loop confirmation plus observed,
repeatable musician Tap/Strum timing on each supported route. The coordinator
must not advance Phase 2 or merge a completed-phase checkpoint before it passes.

## Apple documentation reviewed

Reviewed 2026-09-12 via Apple's published Markdown versions (web renderer
requires JavaScript). Public API references:

- [AVAudioPlayerNode](https://developer.apple.com/documentation/avfaudio/avaudioplayernode): buffer scheduling and player/node time conversion.
- [AVAudioTime](https://developer.apple.com/documentation/avfaudio/avaudiotime): distinct host/sample representations.
- [UITouch.timestamp](https://developer.apple.com/documentation/uikit/uitouch/timestamp): boot-relative touch occurrence time.
- [UIEvent.coalescedTouches](https://developer.apple.com/documentation/uikit/uievent/coalescedtouches(for:)): actual coalesced movement samples.

Local implementation details and measured results above are evidence from this
lab, not claims that Apple guarantees acoustic timing or scoring validity.
