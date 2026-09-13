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

Three new actual owner trials and positive overall feedback are now recorded
in the owner-analysis section below. Phase 1's tested iPhone 16
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
7. Follow up the accessibility foundations with actual VoiceOver/direct-touch
   use when available. Keep the current evidence gap explicit. Full accessibility
   review belongs to Phase 4; do not add a broad certification gate to Phase 2.

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
The phone was subsequently unlocked and the reviewed game installed successfully.
See `.ai/evidence/phase2/physical-integration.json` for the initial failures and completed follow-up checks.

## Physical continuation — 2026-09-13

The unchanged reviewed game is installed on iPhone 16 / iOS 26.6.2 and was
relaunched without test arguments to its default challenge selection. Autonomous
physical checks are complete; actual product and assistive-use acceptance remain.

Initial suite: 18 tests, 15 passed and 3 failed. The owner subsequently confirmed
playing during these checks and intentionally removing the Phase 1 app. The
65-event Tap result is owner input, but the overlapping run cannot establish
unattended UI/Strum behavior, voluntary retry, or trustworthy repeated results.
The owner's removal is honored; no restoration was performed. All 11 Phase 1
records remain in a verified durable preinstall backup. The historical lab was
absent before installation; both historical source implementations are unchanged.

Under the instruction to leave the phone unlocked and untouched, the affected
UI flow and Strum checks passed. The audio test was safely invalidated when the
app left the foreground after 173 anchors. A subsequent isolated audio check
passed: 34-second full traversal, 1021 anchors, maximum clock mismatch 0.005583 ms,
playing/warning/silent/returned stages, zero inputs and missingInput/no score.
The separate UI traversal also captured zero events, completed the full loop
and retained no-input feedback (1021 anchors, maximum mismatch 0.005708 ms).
Four automated down-Strum gestures produced exactly four crossings with 8.333 ms
brackets; the deliberately cancelled attempt remained unscored. These are
software-driven checks, not measurements of human contact/acoustic precision.

All 18 physical test cases have now passed across the initial and targeted runs.
This is not a claim of one clean 18-test run: route/background interruptions and
owner-overlapped failures remain in the evidence. Initial maximum Dynamic Type
navigation/preparation audit, persistence checks and full software scoring fixture
passed. No source correction or additional review was needed.

All four pre-rerun game records—including the owner's scored Tap attempt—remain
exactly unchanged in the seven-record final history. Their four diagnostic files
also match byte-for-byte. The three new automated records are explicitly
no-input/cancelled and cannot earn personal bests. Game records, fixture traces,
result bundles and screenshots are archived outside the worktree with a private
hash manifest. See `.ai/evidence/phase2/physical-integration.json`.

The owner can now try Tap and down-Strum and report whether the results make
sense, match their experience, and show any missed gestures. The musician comprehension/retry/trust/comparison protocol remains the product
acceptance evidence. Actual VoiceOver-use is an explicit foundation-verification
limitation; full accessibility review belongs to Phase 4. No arbitrary trial quota or perfect-score requirement applies.
Phase 2 is not accepted; PR stays draft and no Phase 3 begins before the
coordinator verifies the genuine gate.


## Actual owner trials and analysis — 2026-09-13

Owner feedback, relayed by the coordinator: “Did it. Feels good. Will need to
refine stuff but overall is cool. Analyze. Lets keep moving toward mvp”. This
supports positive overall appeal and continuation, without inventing specific
refinement requests or comparative preference.

Read-only retrieval found three new completed/full-score trials. All seven
previous saved trials and diagnostic files are unchanged; all ten records are
archived outside the worktree. No app launch, automation or playback was started
while retrieving these records.

| Mode / challenge | Captured events | Opening pulse | Gap consistency¹ | Drift vs opening | Landing vs opening |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tap / First light (4s) | 66 | 501.24ms | 15.40ms | +6.75ms/beat | 48.53ms late |
| Tap / Stay a little (6s) | 66 | 500.12ms | 11.74ms | −0.42ms/beat | 15.02ms late |
| Strum / First light (4s) | 65 | 502.22ms | 15.17ms | −3.54ms/beat | 25.72ms early |

¹ Residual variation around the fitted gap timing trend, not raw interval SD.
Gap labels describe beat-span lengths; the 100ms fade reduces full zero-gain
silence to 3.9s/5.9s. Landing is relative to each attempt's own opening pulse,
not an independently measured acoustic offset.

An independent standard-library Python calculation using raw occurrence times
and the committed beat maps reproduced every numeric score field and diagnosis
(maximum difference below 1e−12). No runtime invalidations occurred; maximum
host/sample clock mismatch across these records was 0.008459ms. That measures
clock progression consistency, not physical contact or acoustic precision.

The Strum record contains 65 down-crossings, with 64 intervals spanning
460.384–534.070ms (median 499.654ms). Bracket median/p95/max are
8.322/8.324/16.645ms. There are no half/double-period interval flags and no
approximately one-second gap in this trial. This is favorable capture evidence,
not proof that every intended gesture was captured. The older unexplained
Strum intervals remain unresolved; no actual gesture ground truth was supplied.

The first-light Tap landing is closer than the earlier compatible owner result
(48.53 versus 166.71ms absolute). That earlier trial overlapped automation, and
the newer second Tap uses a different challenge. Neither comparison establishes
controlled repeatability, perceived score trust or training improvement. The
first full result for the longer Tap challenge and the first full Strum result
remain separate comparison histories.

No reproducible implementation defect was identified. The short-gap Tap drift
is about 1.35% slower than its opening, and Strum about 0.71% faster. Current
category wording follows the verified rules; a useful refinement question is
whether the wording's strength matches what players felt. These traces alone
do not justify changing scoring thresholds, layout or product direction.

Remaining gate evidence is specific: unaided understanding, spontaneous retry,
trust after repeated identical attempts, and meaningful preference relative to
familiar click-based gap practice. Completing an extra challenge does not prove
voluntary retry. The coordinator has one pending owner question about these
observations and refinement priorities; this task does not duplicate it or
claim the Phase 2 gate has passed. Accessibility foundations remain documented;
actual VoiceOver use is unobserved, with full review reserved for Phase 4.

Reproduction: `analysis/recompute-owner-trials.py` under `.ai/evidence/phase2/`
accepts the private owner-analysis archive and bundled catalog paths. Sanitized
findings: `owner-trial-analysis.json`, `owner-comparisons.json`, and
`owner-observations.json`. Private raw data and per-trial identifiers remain
outside git.
