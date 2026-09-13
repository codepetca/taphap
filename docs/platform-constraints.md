# TapHap Platform and Content Constraints

This document records the assumptions that constrain the roadmap. It is a
dated engineering and product snapshot, not legal advice. Re-verify platform
documentation and agreements before implementing a gated capability and again
before App Store submission.

Last reviewed: 2026-09-12.

## Active MVP foundation: app-controlled audio

The MVP uses fully owned or expressly licensed audio files bundled with the
app. This path gives TapHap control of decoded samples, playback position, gain,
and the beat map used for scoring.

Implementation constraints after Phase 1 approval:

- Use an audio render timeline for playback and gap scheduling.
- Fade app-owned audio gain to zero and back; do not pause or seek across a
  normal gap.
- Keep the beat map in the same track-relative time domain as the audio.
- Schedule the return from audio time rather than a UI timer.
- Keep UI animation observational. It must not drive audio or scoring.
- Record route changes and interruptions that invalidate a trial.
- Validate audible behavior on physical supported devices.

Relevant Apple references:

- [AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [AVAudioPlayerNode](https://developer.apple.com/documentation/avfaudio/avaudioplayernode)
- [AVAudioTime](https://developer.apple.com/documentation/avfaudio/avaudiotime)
- [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)

## Beat maps

Every launch track needs a verified sequence of beat positions. A BPM number
alone is insufficient when a track has a pickup, count-in, edit, pause, tempo
change, or human timing variation.

- Store beat positions against the exact shipped audio revision.
- Version the audio and beat map together.
- Include meter, downbeat positions, supported challenge sections, and known
  exclusions where needed.
- Validate maps acoustically and visually before treating them as scoring
  truth.
- Do not infer a verified beat map from user taps.

Automatic beat analysis belongs to the separately gated user-import phase. It
must report uncertainty and provide a correction or rejection path.

## Audio rights

Every bundled track must be wholly owned or covered by an express written
license that includes the intended application, game, promotional, editing,
fading, looping, territory, platform, and duration rights.

- Preserve contracts and source assets outside the public repository.
- Record a non-sensitive provenance summary in the repository before release.
- Do not assume that royalty-free means unrestricted.
- Do not treat a streaming subscription, purchased download, preview, short
  excerpt, or user familiarity as permission to bundle music.
- Do not ship commercial lyrics without the necessary rights. Split Focus can
  use original or public-domain text, user-provided text, or singing from
  memory without displaying licensed lyrics.

## Apple Music and MusicKit: inactive path

Apple Music is not part of the active roadmap.

The earlier lab established the following on a signed physical-device build:

- Music authorization, search, selection, and playback worked.
- `AVAudioSession.setOutputMuted(_:)` silenced the app-controlled reference
  click but did not silence `ApplicationMusicPlayer` output in the tested
  configuration.
- A pause/seek/resume fallback advanced the reported playhead by the intended
  gap, but the resume request occurred too late for musician-credible timing
  and acoustic re-entry was not measured.
- Public MusicKit does not expose decoded PCM or a verified song beat map to
  the app. The experiment therefore used the player's taps, not an
  independently detected song beat.

Those findings fail the essential product requirements: the app must own the
fade and return and score against an independently verified song timeline.
Do not continue, ship, or monetize the MusicKit experiment without a new
product decision, new official documentation review, and a separate technical
and policy gate.

Historical and official references:

- [Historical feasibility lab](phase-1-feasibility-lab.md)
- [MusicKit](https://developer.apple.com/documentation/musickit)
- [ApplicationMusicPlayer](https://developer.apple.com/documentation/musickit/applicationmusicplayer)
- [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [App Review Guidelines, Apple Music](https://developer.apple.com/app-store/review/guidelines/#apple-music)

## Spotify: excluded

Do not build or market Spotify integration under the current plan. Revisit it
only after a product-direction change and a fresh review of Spotify's then
current developer policy.

Official reference:

- [Spotify Developer Policy](https://developer.spotify.com/policy)

## User-imported audio: post-MVP gate

User-selected DRM-free files could provide exact local playback control, but
they introduce beat-analysis, file-lifecycle, privacy, malformed-file, and
variable-tempo behavior.

Before implementation, define:

- Supported formats and size limits.
- Local-only storage and deletion behavior.
- Beat-analysis confidence and correction UX.
- Behavior for ambiguous meter, pickup bars, tempo changes, and silence.
- How trial comparability survives a changed or replaced file.

## Physical-instrument input: post-MVP gate

The MVP uses touchscreen Tap and Strum input. A later experiment may evaluate:

- Microphone onset detection for percussion and clear guitar attacks.
- USB audio for a separated instrument signal.
- Timestamped MIDI input.
- Route-specific latency calibration.
- Simultaneous singing and acoustic-instrument recognition as a separate,
  higher-risk case.

Do not claim general instrument recognition based on one instrument, room,
dynamic level, or playing style.

## Apple Watch: future possibility

Apple Watch is not part of the MVP or active implementation plan. Any future
companion requires its own product purpose and physical-device feasibility
phase.

- Keep the iPhone game independently complete.
- Do not use inaudible audio, fake workouts, or unrelated extended-runtime
  categories to manufacture background execution.
- Do not assume haptic timing remains reliable while the wrist is moving.

Official references:

- [watchOS background execution](https://developer.apple.com/documentation/watchkit/background-execution)
- [Using extended runtime sessions](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions)
- [Core Haptics](https://developer.apple.com/documentation/corehaptics)
