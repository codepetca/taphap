# TapHap Product Roadmap

This is the canonical roadmap. It replaces all earlier plans for BPM Sync,
multi-device peer synchronization, automatic ambient song detection, and a
song-based rhythm game.

## Product destination

TapHap should become a simple, enjoyable internal-clock trainer that is useful
without a streaming service:

1. Music plays while the person taps.
2. TapHap establishes a personal timing baseline.
3. The audio disappears while its timeline continues.
4. A non-rhythmic progress ring shows when the audio will return without
   revealing the beat.
5. The person keeps tapping from their internal sense of time.
6. Music returns and TapHap reports drift, consistency, and progress over time.

A conventional metronome is a secondary utility. It may offer tap tempo and
direct tempo controls, but the primary exercise must never require BPM entry.

## Current state: planning lock

- Product documentation is the only approved work.
- No Xcode project, source code, dependencies, generated assets, service
  credentials, or Apple capabilities should be added yet.
- Implementation begins only after the repository owner explicitly approves a
  phase or implementation task.

## Phase 1: feasibility gates

Begin only after explicit implementation approval. Use throwaway, narrowly
scoped experiments before building product UI.

### 1A. Timing and scoring

- Play a locally controlled test groove with a known beat grid.
- Capture touchscreen tap timestamps using a monotonic clock.
- Establish a baseline from the audible section with robust fitting and outlier
  rejection.
- Continue the hidden beat timeline through silence.
- Measure end drift, tempo slope, and tap consistency.
- Test built-in speakers, wired output, and Bluetooth headphones on physical
  devices.

Exit gate: repeatable measurements distinguish genuine user drift from stable
audio-route and touch-input latency.

### 1B. Apple Music behavior

- Authenticate with MusicKit and let the user explicitly select and start a
  full song.
- Verify `ApplicationMusicPlayer` playback position behavior on physical
  devices.
- Test whether the iOS 26+ audio-session mute API cleanly silences only the
  app's Apple Music playback while the playhead continues.
- Measure mute and unmute timing across supported audio routes.
- Confirm interruption, buffering, subscription, offline, and unavailable-song
  behavior.
- Do not use deprecated player-volume APIs or manipulate system volume.

Exit gate: the music can disappear and return with musician-credible timing
without downloading, recording, decoding, or modifying Apple Music content.

### 1C. Apple Music policy

- Present Apple with the exact product behavior: user-initiated full-song
  playback, tap calibration, temporary output mute, non-beat progress display,
  local scoring, and no audio capture or export.
- Obtain a reliable interpretation of MusicKit's synchronization and
  monetization restrictions before promising or shipping the feature.
- Keep Apple Music optional and never make subscription access itself a paid
  feature.

Exit gate: the release plan has a documented, defensible App Store path. App
Review approval must not be assumed from technical feasibility alone.

### 1D. Apple Watch behavior

- Test foreground and wrist-down haptic timing on supported watchOS versions.
- Determine whether a legitimate runtime mode supports the intended session.
- Measure phone-to-watch clock mapping, drift, interruptions, and battery use.
- Never use inaudible audio, a fake workout, or an unrelated extended-runtime
  category to keep the watch app alive.

Exit gate: Watch behavior is useful and App-Review-compliant. The iPhone app
must remain complete if this gate fails.

## Phase 2: core iPhone vertical slice

Build against bundled, original test audio so the core does not depend on Apple
Music approval.

- Session state machine: prepare, calibrate, warn, silent gap, return, result.
- Large, low-latency tapping surface.
- Baseline estimation from audible taps; no required BPM input.
- Hidden timeline and deterministic scoring.
- One-way progress ring during silence with no beat pulses or subdivisions.
- Results for end drift, speeding up or slowing down, and consistency.
- Unit tests for timing math, state transitions, outlier handling, and scoring.

Exit gate: a first-time user can complete and understand one exercise without
instructions beyond concise on-screen guidance.

## Phase 3: App Store MVP

- A small set of fully owned or expressly licensed musical grooves.
- Difficulty based on silent-gap length and support level.
- Assisted mode with continuous gap progress; blind mode without it.
- Local session history and comparable improvement trends.
- Simple metronome with tap tempo and optional direct tempo adjustment.
- Accessibility, reduced motion, VoiceOver, Dynamic Type, and high-contrast
  behavior.
- Clear handling of interruptions, headphones, route changes, phone calls, and
  app lifecycle events.
- No account, backend, analytics dependency, microphone, or network requirement
  for the core exercise.

Exit gate: TapHap is independently useful, reliable, understandable, and ready
for TestFlight without Apple Music or Apple Watch.

## Phase 4: conditional Apple Music mode

Include only if both the technical and policy gates pass.

- Apple Music authorization and user-driven song selection.
- Standard play, pause, skip, and playback-position controls.
- Tap-based baseline calibration rather than audio extraction or BPM metadata.
- Boolean mute and unmute while playback continues; do not promise a gradual
  fade unless Apple introduces a supported per-player gain API.
- The same non-rhythmic progress display and local scoring used by the core.
- No song downloads, recordings, waveform access, beat-map database, sharing,
  or remote storage of Apple Music listening data.
- Graceful fallback to bundled exercises for non-subscribers or unavailable
  content.

## Phase 5: conditional Apple Watch companion

Include only if the watch feasibility gate passes.

- Remote session controls and status.
- Optional tap input for exercises.
- Haptic output for the separate metronome experience.
- Phone remains the canonical playback and scoring authority.
- No dependency on watch availability for stored history or core training.

## Phase 6: release hardening

- Verify rights and source records for every bundled audio asset.
- Prepare privacy disclosures and Apple Music usage descriptions, if applicable.
- Explain unusual MusicKit and audio behavior plainly in App Review notes.
- Test supported devices, OS versions, audio routes, accessibility settings, and
  long sessions.
- Run TestFlight feedback focused on whether scoring feels fair and whether
  users understand the progress ring.
- Publish only after all included conditional features satisfy their gates.

## Future possibilities, not commitments

- User-imported DRM-free audio.
- Adaptive gap lengths and personalized practice plans.
- More detailed progress analytics.
- Optional microphone-based tempo experiments.
- Cloud synchronization of history.
- Social challenges.
- Multi-musician or peer-to-peer synchronization.

None of these belong in the initial implementation unless the roadmap is
explicitly revised.
