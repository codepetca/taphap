# Phase 2: one-song playable slice

Status: local implementation, verification and independent review complete.
[Checkpoint PR #3](https://github.com/codepetca/taphap/pull/3) remains draft.
Reviewed implementation: `680d87320dc50b4d9f2360d18bbd530252b7558e`. **Phase 2 has not
passed its product gate.** This task delivers one draft checkpoint for coordinator
acceptance. No Phase 3 or release work is included.

## Scope and integration

Starts at accepted Phase 1 merge `036e81dd5a0de971d6430a24f95560ee933714e5`.
Task `01a09b0a-c71a-7251-af94-79ffe54c11ef`, branch
`codex/phase-2-one-song-slice`. Coordinator owns phase acceptance and advancement.

`phase2-project.yml` generates a separate native iPhone `TapHapGame` target,
bundle `ca.codepet.taphap.game`, display name TapHap. Both prior lab apps, tests,
projects and resources remain unchanged. The game compiles the accepted
`Phase1Lab/Core` timing, crossing, envelope and assessment sources directly;
there is one scoring implementation. Product presentation, lifecycle adapter,
new content, challenge state and local history live under `TapHapGame`.

## Delivered behavior

- Selection: Afterglow song, Tap/down-Strum choice, three prebuilt gap challenges,
  local recent attempts. No tempo/meter settings or training-system expansion.
- Play: preparation explains finger/lift and continuous play; one non-repeating
  warning; a fixed large surface with a static Strum reference line; unmarked,
  continuous whole-song progress; the original music returns and plays out.
  Header changes cannot shift the active reference line. No audio/haptic/visual
  click, beat/bar count, countdown, or autonomous repeating motion. A thicker
  outline responds only while the player's finger is in contact.
- Result: plain-language diagnosis, landing only when verified, optional timing
  detail, retry and next. Partial input assessments remain useful but cannot
  earn personal bests. Invalid runtime/capture suppresses all timing claims.

The new locally authored instrumental and its exact provenance are in
[Afterglow provenance](../TapHapGame/Resources/PROVENANCE.md). PCM synthesis is
reproducible without dependencies. Independently enumerated 64-position map and
PCM attack verification found one-frame maximum onset threshold offset and
zero clipping. The same 34-second track supports 4/6/8-second fade-to-return
sections; the 100 ms sample-domain fades are included in those durations.
Musical quality and preference are not established by a PCM test.

Audio is decoded and hash-verified before scheduling. Each challenge's immutable
envelope multiplies the full-length PCM once; AVAudioPlayerNode traverses every
sample including digital zeros. A main-actor observer reads progress/completion;
it does not schedule sound or generate touch timestamps. Original audio/sample
clock validation and capture bounds are retained. Preparation generations latch
route/interruption/background/reset invalidations; media reset rebuilds the
engine. Idle lock is disabled only for the active attempt and then restored.

Only iPhone built-in speaker play is enabled in this build. Other outputs get
an explanatory start failure. Device identity in compatibility means hardware
model plus OS version within this local app, not a unique device identifier.
No account, network, backend, analytics, imported music, microphone or external
service is used. The app requests no background audio mode or device permission.

## Metric boundaries and local persistence

A personal best is **closest verified landing**, absolute return offset from
that attempt's fitted opening phase. It is not a composite grade, proof of
improvement or a Day 1 baseline. Equal/more distant landings do not announce a
new best. Previous and best comparisons require exact content hash, challenge,
input mode, hardware model, OS, route, sample rate, IO duration, reported output
latency, assistance and scoring version. Partial, invalid, incomplete and
unvalidated-route records never supply a best/comparison.

Unreadable history suppresses first/new/best/previous claims. Ordinary write failures
use loaded-plus-pending attempts for comparisons, so a second unsaved attempt
sees the first. The independently reviewed correction passes 28 package tests and two focused
iOS persistence/comparison tests, including scored attempts under both failures.

Trial summaries live in Application Support/TapHap/history.json, schema 1,
written atomically. Failed writes show Save again, preserve earlier history and
retain pending attempts in memory; corrupt/unknown history is preserved and
blocks new writes rather than being silently overwritten. A missing file is a
new history. Raw contact diagnostics remain local, separate from the user
history, and do not influence scoring. No raw personal traces are committed.

## Accessibility foundations

Native labels, segmented mode choice, scalable text, scrollable long preparation
and results, 44-point controls and a large direct-touch surface. Active surface
geometry is fixed independently of the scrolling header. Decorative branding
and surface reminders use bounded sizes; instructions and results retain full
Dynamic Type. The palette uses dark ink on cream/lime and white on dark teal,
with labels and shapes in addition to color. Reduce Motion removes the tiny
linear interpolation of observed progress; no repeating visual cue exists.

VoiceOver uses UIKit allowsDirectInteraction with silentOnTouch, preserving
actual touch event timing instead of treating accessibility activation as a
rhythmic input. Accessibility mode is part of comparison compatibility; a mode
change during play invalidates the attempt. No automatic gap/beat announcement
is scheduled. Direct-touch behavior still requires real assistive-use validation.
Apple API reference checked 2026-09-13:
[allowsDirectInteraction](https://developer.apple.com/documentation/uikit/uiaccessibilitytraits/allowsdirectinteraction),
[accessible controls](https://developer.apple.com/documentation/swiftui/accessible-controls).

## Local checks and artifacts

Run from the repository root:

```sh
python3 scripts/generate-phase2-track.py
python3 scripts/verify-phase2-assets.py
swift test
xcodegen generate --spec phase2-project.yml
xcodebuild -project TapHapGame.xcodeproj -scheme TapHapGame -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build/Phase2 test CODE_SIGNING_ALLOWED=NO
xcodebuild -project TapHapGame.xcodeproj -scheme TapHapGame -destination 'generic/platform=iOS' -derivedDataPath build/Phase2Device build-for-testing DEVELOPMENT_TEAM="$TAPHAP_EXISTING_TEAM"
```

Local results: initially 27 package tests, 13 iOS core/integration tests and three UI tests
passed. Signed iPhone app/test and frozen historical app/test builds passed.
The repeated final touch test captured four of four simulator down-crossings,
with maximum crossing bracket 16.667 ms; it was deliberately ended and unscored.
A software timestamp fixture traversed the actual 34-second render timeline,
produced a full score, saved/reloaded it and rendered the result screen. It is
not musician evidence. The final zero-input render run collected 1,021 anchors
with 0.017583 ms maximum host/sample mismatch; all audio stages were observed.

Increased-contrast UI tests passed at the normal and largest Dynamic Type size,
including play/end/retry navigation. Direct visual inspection covered selection,
Tap/Strum preparation and play, silence, unscored result and large-text layouts.
The four-gesture local diagnostic check is in [Strum simulator evidence](../.ai/evidence/phase2/strum-simulator.json).
The active Strum reference frame is asserted unchanged at silence entry.
Reduce Motion was enabled in Simulator Settings; selection, preparation,
play and return were exercised and visually inspected. The surface remained
fixed and there was no repeating pulse. Original simulator motion/contrast
settings were restored. The software-score screenshot predates only the final
caption simplification to “Compared with how you played before the silence.”
Preparation accessibility audit passed contrast, element detection, hit regions,
labels, traits and clipped-text checks. This does not certify actual VoiceOver
musician use, which remains an external acceptance observation.

See [verification summary](../.ai/evidence/phase2/verification-summary.json),
[asset verification](../.ai/evidence/phase2/asset-verification.json),
[preservation](../.ai/evidence/phase2/preservation.json),
[physical status](../.ai/evidence/phase2/physical-status.json), and
[review ledger](../.ai/evidence/phase2/review-ledger.md).
Screenshots: [selection](../.ai/evidence/phase2/screenshots/selection.png),
[silence](../.ai/evidence/phase2/screenshots/silence.png),
[large-text play](../.ai/evidence/phase2/screenshots/playing-large-text.png),
[Strum](../.ai/evidence/phase2/screenshots/strum-active.png). Ignored raw logs and result bundles are preserved
outside this disposable worktree before handoff/archival. Screenshot presence
is evidence of a rendered state, not an accessibility or musician usability pass.

## Physical and musician product test: required acceptance

No Phase 2 human observation has been recorded yet. Phase 1's tested iPhone 16
speaker feasibility carries forward only for unchanged core behavior. Two old
Strum records contain unexplained approximately one-second intervals; the latest
65-stroke repeat had 64 intervals 461.86–559.96 ms. Neither omission nor absence
of intermittent capture loss is established. Observe real repeated Strum input
in this product surface; repair a reproducible missed-capture defect before
product acceptance.

Minimal protocol for the delivered build, facilitated by the owner without
contacting outsiders from this task:

1. Use a musician already familiar with gap-click practice. Record anonymous
   tester label, relevant familiarity and build; record only consented notes.
   Use built-in speaker, comfortable fixed volume and no external timing cues.
2. Hand over selection with only “Try this.” Observe first choice, time to
   start, misunderstanding and any help needed. Do not explain the loop first.
3. After return, let the player choose what to do. Record whether they retry
   spontaneously and why; a prompted retry is not voluntary-retry evidence.
4. Ask what the result means, then let them repeat comparable attempts or
   deliberately change their pulse. Record perceived consistency/credibility
   and actual persisted assessment, including partial/invalid outcomes. No
   requirement to earn a perfect/full result or hit an arbitrary trial quota.
5. Exercise Tap and down-Strum; record any gesture believed to be missed, held,
   duplicated or cancelled. Compare local event/bracket diagnostics with the
   observer's actual gesture notes. Missing ground truth remains uncertain.
6. Compare with the musician's familiar click-based gap trainer under similar
   tempo, preparation, gap and speaker conditions. Record trainer/settings,
   order, which they would choose to use again and why. If possible alternate
   order across testers; do not infer product preference from novelty or from
   a test script completing. No purchase or new external integration is needed.
7. With appropriate testers, navigate/read/retry using VoiceOver and large
   text, and directly play the surface. Check no per-touch speech or automatic
   rhythmic cue occurs in silence. Check reduced motion and increased contrast.

Record observations against all four roadmap questions: unaided understanding,
voluntary retry, repeated-result trust and meaningful preference over click
practice. Coordinator decides whether actual evidence supports the Phase 2 exit.
If testers/device observation are unavailable, deliver the reviewed draft and
this precise external acceptance list; do not infer a pass or begin Phase 3.

## Delivery and review

Initial Sol/high review found an unsupported comparison claim when history was
unknown or pending. One correction batch added explicit availability and effective
pending-history comparisons, with scored-attempt regression tests. Terra/high
targeted and Sol/high final cumulative reviews are clean. Four reviewer launches,
one correction batch, approximately 12 minutes elapsed; no budget extension.
No configured GitHub checks or unresolved review threads exist.

All 22 fixed source-manifest files match the reviewed implementation; all 49
accepted Phase 1 files outside the extended package definition and all 18
historical files remain unchanged. No phase merge occurred. Coordinator must
verify actual Phase 2 external acceptance before marking ready or merging.

Private logs, simulator records and build/result bundles are preserved in durable
local storage outside this worktree:
`/Users/stew/.codex/taphap-baselines/01a0989f-1811-7a53-825d-84d761c57044/phase2-evidence/`.
Its private hash manifest remains outside git. The current signed app is under
`build/Phase2Device/Build/Products/Debug-iphoneos/TapHapGame.app` in that archive.
The phone remains unmodified by this task; last probe found it locked. The Mac
also locked after direct visual checks, preventing further UI inspection; Reduce
Motion and contrast were restored via simulator preference/CLI verification.

Next concrete dependency: unlock the paired iPhone for installation and physical
integration/input checks of this reviewed app, then supply the real musician and
assistive-use observations in the protocol above. No external contact, purchase,
release, Phase 3 dispatch or assertion of engagement has been made.
