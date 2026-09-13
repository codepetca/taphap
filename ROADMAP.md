# TapHap Product Roadmap

This is the canonical implementation sequence for the product defined in
[the product direction](docs/product-brief.md). It replaces the earlier plans
for a synchronized metronome, Apple Music experiment, passive song listener,
and metronome-first trainer.

## Destination

TapHap is a song-based rhythm game and real internal-clock trainer:

1. Music plays while the player taps or strums on the screen.
2. The music fades out while its hidden timeline continues.
3. The player maintains the rhythm without external cues.
4. The music returns at its correct position.
5. TapHap scores consistency, drift, re-entry, and improvement over time.

The product serves musicians first while using the universally understandable
challenge: **When the music comes back, will you still be on beat?**

## Current state: direction documented, implementation locked

- The new product direction and staged roadmap are documented.
- No implementation phase in this roadmap is authorized merely by this
  documentation change. The owner must explicitly approve the next phase.
- The repository contains an earlier Phase 1A/1B iPhone feasibility lab. It is
  experimental evidence, not the foundation or UI for the new product.
- That lab established that app-controlled reference audio can become silent
  while timing continues. It also established that direct Apple Music muting
  did not work in the tested configuration.
- Apple Music, Spotify, Apple Watch, physical-instrument listening, production
  UI, release activity, and external services remain out of scope.

## Phase 0: ratify the direction

Documentation-only phase.

- Confirm the product statement, audience, promise, input modes, game loop,
  scoring principles, visual contract, and MVP boundary.
- Preserve the earlier feasibility findings as historical evidence.
- Keep all new implementation locked until the owner authorizes Phase 1.

Exit gate: the owner confirms this direction is ready for implementation.

## Phase 1: core audio and scoring feasibility

Build a narrow engineering lab, not production UI.

### Scope

- Use one locally bundled, fully owned test track with a verified beat map.
- Play it on an app-controlled audio timeline.
- Fade the app-owned audio to zero and back without pausing its timeline.
- Schedule gap boundaries from audio sample time rather than UI timers.
- Capture Tap touch-down timestamps.
- Capture Strum reference-crossing timestamps and stroke direction.
- Fit an audible-section baseline, then calculate consistency, tempo drift, and
  re-entry error through a silent gap.
- Exercise identical prerecorded input fixtures to make scoring deterministic.
- Test repeated trials on a physical iPhone across intended audio routes.

### Excluded

- Production navigation, art, onboarding, accounts, analytics, store flows,
  microphone input, Watch, streaming services, and a song catalog.

### Exit gate

- Audio fades and returns on the mapped timeline without pause, seek, or drift.
- Identical simulated inputs receive stable results.
- Deliberate acceleration, deceleration, jitter, and phase shifts produce the
  expected diagnosis.
- Tap and Strum timestamps are repeatable enough for musician-credible scoring.
- A physical-device run confirms the complete audible-to-silent-to-audible
  loop.

Stop and revise the model if this gate fails. Do not hide engine uncertainty
behind polished UI.

## Phase 2: one-song game vertical slice

Build the smallest complete playable experience around the validated engine.

### Scope

- Three primary screens: challenge selection, play, and result.
- One polished musical track and a small set of prebuilt gap challenges.
- Tap and Strum selection without advanced configuration.
- Clear preparation, non-rhythmic gap warning, silent progress, return, and
  plain-language result.
- Retry, next challenge, and personal best.
- Local persistence for trials and compatible-session comparison.
- VoiceOver, Dynamic Type, reduced-motion, and high-contrast foundations.

### Product test

Put the slice in the hands of musicians who already understand gap-click
practice. Compare it with a click-based gap trainer and observe whether players:

- Understand TapHap without explanation.
- Voluntarily retry after the song returns.
- Trust the score after repeated identical attempts.
- Prefer the musical challenge strongly enough to make it a separate product.

### Exit gate

The core loop is reliable, immediately understandable, and meaningfully more
engaging than a click-only gap exercise.

## Phase 3: training game MVP

Turn the vertical slice into a bounded daily training product.

### Content

- Ship a small set of enjoyable, fully owned or expressly licensed songs with
  verified beat maps.
- Cover a useful but controlled range of tempos and beat clarity.
- Designate at least one benchmark track and separate transfer challenges.
- Store non-sensitive asset provenance in the repository and keep private
  contracts outside it.

### Training system

- Day 1 baseline made from multiple short trials.
- Three-to-five-minute daily sessions.
- Adaptive difficulty through gap length, preparation time, placement, tempo,
  groove clarity, and input pattern.
- Checkpoint retests using identical benchmark conditions.
- Transfer tests using a different track.
- Personal bests, skill chapters, grades, stars, and perfect landings tied to
  actual performance.
- Local history with transparent, compatible comparisons.

### Quality

- Unit tests for beat-map conversion, scheduling, baseline fitting, scoring,
  progression, and persistence.
- Deterministic tests for pauses, route changes, interruptions, and app
  lifecycle transitions.
- Usability tests for first-run comprehension and score clarity.

### Exit gate

A new player can establish a baseline, complete a short daily session, return
on a later checkpoint, and understand measured improvement without knowing BPM
or configuring a metronome.

## Phase 4: release candidate

- Complete accessibility review and supported-device testing.
- Verify every audio asset and its allowed app, promotional, editing, looping,
  territory, and duration uses.
- Finalize privacy disclosures for a local, account-free product.
- Handle audio interruptions, route changes, phone calls, backgrounding, and
  storage failures clearly.
- Validate scoring fairness across supported devices and routes.
- Test a free starter experience and a one-time unlock; do not add a
  subscription unless recurring content later creates recurring value.
- Run TestFlight feedback focused on replayability, score trust, song quality,
  and willingness to pay.
- Prepare App Store copy around the musical disappearance challenge rather than
  a long feature list.

Exit gate: the standalone iPhone product is reliable, understandable, legally
documented, and useful without a network, account, streaming subscription, or
external hardware.

## Phase 5: Split Focus expansion

Begin only after the core game demonstrates retention.

- Add static reading and speaking prompts that do not reveal beat timing.
- Let players sing from memory while using Tap or Strum.
- Compare split-focus performance with the player's compatible normal baseline.
- Report attention cost through changes in consistency, drift, and re-entry.
- Add progressive challenges without attempting to judge vocal pitch or lyric
  correctness.

Exit gate: the secondary task increases useful difficulty without corrupting
timing measurement or becoming an accidental visual metronome.

## Phase 6: user-imported audio

Begin only with a separately approved feasibility plan.

- Import user-selected, DRM-free audio files.
- Decode and analyze audio locally for tempo, phase, beat positions, and
  confidence.
- Provide a correction path when analysis is uncertain.
- Handle variable tempo, pickup measures, silence, and ambiguous meter.
- Keep imported audio private and local by default.

Exit gate: imported tracks can produce beat maps and gap returns reliable
enough for scoring without pretending uncertain analysis is exact.

## Phase 7: physical-instrument input

Begin only after the touchscreen product succeeds.

- Test microphone onset detection with percussion and clear guitar strums.
- Test separated USB-audio and timestamped MIDI input.
- Calibrate device and route latency.
- Determine supported instruments and playing styles from measured evidence.
- Treat simultaneous acoustic singing and instrument recognition as a separate
  high-risk experiment.

Exit gate: supported input methods produce repeatable onset timestamps and
honest limitations can be communicated to players.

## Future possibilities, not commitments

- Teacher assignments and private progress sharing.
- Optional Apple Watch companion.
- Carefully bounded social challenges.
- Additional paid song or curriculum packs with explicit rights.

These require separate product decisions. Do not revive streaming playback,
group synchronization, or a generic metronome feature race without revising
the product direction first.
