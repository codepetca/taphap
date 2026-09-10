# TapHap Product Brief

## Product statement

TapHap is a simple music-based internal-clock trainer. It establishes the pulse
a person is already tapping, temporarily removes the audible reference, and
measures how their timing changes while they continue unaided.

The product is not a song detector, streaming client, synchronized group
metronome, or content-licensing workaround.

## Primary users

- Musicians who want to improve tempo stability away from their instrument or
  as part of practice.
- Music students learning to hold a pulse without continuous cues.
- General users who want a short, approachable rhythm exercise.

## Core promise

The primary exercise requires no BPM entry. A user should be able to choose a
groove, press Start, tap naturally, experience a silent gap, and receive useful
feedback in roughly one minute.

## Canonical session

### 1. Prepare

- The user chooses a groove, difficulty, and optional assistance level.
- For a conditional Apple Music mode, the user explicitly selects and starts a
  full song through standard MusicKit controls.

### 2. Calibrate

- Music remains audible.
- The user taps for enough beats to establish a stable pulse.
- TapHap fits a tempo and phase to the taps, rejects obvious outliers, and
  estimates a session-specific baseline.
- The exercise does not demand machine-perfect opening taps. It measures later
  change relative to the user's stable starting behavior.

### 3. Warn

- The interface announces that a gap is approaching.
- Any pre-gap indication must be clear but must not add a new rhythmic cue that
  competes with the music.

### 4. Silent gap

- The audio output disappears while the reference timeline continues.
- The user continues tapping.
- No visual or haptic element supplies individual beats.
- A continuous, one-way ring may show overall progress toward the return.

### 5. Return

- The ring gradually indicates proximity to the return without pulsing,
  ticking, segmenting beats, or displaying a beat countdown.
- Music becomes audible again at the scheduled point.
- The user hears whether their internal pulse still aligns.

### 6. Result

- Show a plain-language result first, such as `72 ms early`, `steady`, or
  `gradually speeding up`.
- Offer detail without requiring the user to understand statistical terms.
- Save the result locally for comparison with like-for-like sessions.

## Visual contract

During the gap, visuals may communicate position in the exercise but must not
communicate the beat.

Allowed:

- A single continuous progress arc across the entire gap.
- Overall song progress.
- A gradual, non-pulsing change in color or brightness near the return.
- A small response caused by the user's own tap.

Not allowed in the standard gap:

- Beat-synchronized pulses, flashes, bounces, or haptics.
- Tick marks or segments corresponding to beats or bars.
- Numeric beat countdowns.
- Repeating rotations or oscillations that become a visual metronome.

Assisted and blind sessions must be recorded separately because they represent
different levels of support.

## Scoring model

The baseline should account for the user's consistent phase offset and the
current device route. A person who naturally taps slightly ahead of the audible
beat should not be penalized simply for that stable preference.

Candidate measures:

- End drift: early or late at the end of the gap.
- Tempo slope: whether taps progressively accelerate or decelerate.
- Consistency: variation between consecutive silent taps.
- Mean hidden-beat error after subtracting the audible baseline.
- Longest gap completed within an agreed tolerance.

Progress comparisons must control for source, tempo, gap length, assistance
mode, input device, and audio route where those conditions materially affect
the score. Do not collapse incomparable exercises into a misleading single
number.

## Audio-source strategy

### Guaranteed core: bundled original audio

TapHap must ship with a small catalog of enjoyable, fully owned or expressly
licensed grooves. The app controls their gain and timeline precisely, enabling
deterministic gaps and reliable testing.

### Conditional: Apple Music

Apple Music is the only streaming integration currently worth investigating.
The intended mode uses user-initiated full-song playback and opening taps for
calibration. It does not require raw audio, BPM metadata, recording, or song
recognition.

This feature remains conditional on physical-device timing tests and a
defensible interpretation of Apple's current MusicKit terms. See
[platform constraints](platform-constraints.md).

### Post-MVP: user-imported audio

DRM-free files chosen by the user could provide exact local playback control.
Rights, file handling, variable-tempo behavior, and product complexity must be
reviewed before adding this path.

### Excluded: Spotify

Do not implement or market a Spotify integration. The current Spotify developer
policy prohibits game use and analysis of Spotify content.

## Metronome role

The metronome is a secondary, immediately useful tool rather than the product's
main differentiator. It may include:

- Tap tempo.
- Optional direct BPM adjustment.
- Meter and downbeat accent.
- Audible and supported haptic output.
- A simple gap-click mode.

The training flow must not send users through the metronome or require them to
know a BPM value.

## Platform roles

- iPhone is the canonical audio, timing, scoring, history, and product UI host.
- Apple Watch is a conditional companion for controls, tap input, and a
  separate haptic metronome experience.
- Watch background privileges must match the product's real purpose. Never use
  fake workouts, silent audio, or unrelated runtime categories.

## Privacy and data

The baseline product:

- Does not use the microphone.
- Does not record or upload audio.
- Stores practice history locally.
- Requires no account or backend.
- Does not collect Apple Music listening data beyond what is needed to run and
  compare the user's own exercises.

Any later analytics or cloud synchronization requires a separate product and
privacy decision.

## Explicit non-goals for the initial release

- Automatic BPM or song detection.
- Shazam-style recognition.
- Streaming-service audio extraction.
- Beat-map acquisition or sharing.
- Real-time group synchronization.
- Peer-to-peer networking.
- Competitive multiplayer or social feeds.
- A catalog of recognizable commercial clips.
- A full rhythm game.

## Definition of a successful first release

- A new user understands the exercise without prior music-theory knowledge.
- The core works without Apple Music, Apple Watch, an account, or a network.
- Results feel stable and fair across repeated identical exercises.
- The progress display prepares users for the return without becoming a hidden
  metronome.
- The app provides a reason to return by showing honest personal improvement.
