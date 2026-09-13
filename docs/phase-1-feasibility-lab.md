# Historical Phase 1A/1B Feasibility Lab

Last reviewed: 2026-09-12.

## Status

This experiment is concluded and frozen. It tested an earlier product direction
that combined touch-timing analysis with Apple Music playback. It is retained
as engineering evidence and must not be treated as the active roadmap or
expanded into production UI without explicit approval.

The active direction is documented in the
[product brief](product-brief.md) and [roadmap](../ROADMAP.md).

## Questions the lab tested

1. Can TapHap capture touch-down timing, fit a stable opening pulse, continue a
   hidden grid through silence, and diagnose user drift?
2. Can app-controlled reference audio become silent and return on schedule?
3. Can `ApplicationMusicPlayer` continue advancing while an iOS audio-session
   mute silences Apple Music output?
4. If direct mute fails, can pause, seek ahead, and resume create a credible
   substitute?

## What was implemented

- Generated 120 BPM reference click with a known grid.
- Monotonic touch-down timestamps.
- Robust pulse fitting, outlier rejection, and confidence gating.
- Eight-beat gap scheduling.
- Continuous, non-pulsing gap progress.
- End drift, mean error, tempo slope, and consistency results.
- Route, reported latency, scheduling-error, and mute-call diagnostics.
- MusicKit authorization, subscription check, catalog search, song selection,
  playback, and playhead diagnostics.
- A narrow Apple Music pause/seek/resume fallback experiment.
- Portable deterministic tests for timing math and session transitions.

## Physical-device findings

### App-controlled reference click

The reference click became silent and returned as expected on the tested
iPhone. This supports the core proposition that app-owned audio can preserve a
hidden timeline through a gap.

The new roadmap does not depend on the lab's boolean session-mute technique.
Phase 1 will instead test gain fades on an app-controlled audio engine.

### Apple Music direct mute

Music authorization, search, selection, and playback worked after the MusicKit
App ID propagated and the app was cleanly reinstalled.

`AVAudioSession.setOutputMuted(_:)` did not silence
`ApplicationMusicPlayer` output in the tested configuration. The required
direct-mute architecture therefore failed.

### Apple Music pause, seek, and resume fallback

One captured run requested an eight-beat gap of approximately 2.902 seconds:

- Pause scheduling error: about +2.65 ms.
- Pause call duration: about 4.15 ms.
- Reported playhead near pause: 20.320 to 20.330 seconds.
- Resume scheduling error: about +76.82 ms.
- Seek/resume call duration: about 16.93 ms.
- Requested and observed post-seek playhead: about 23.232 seconds.
- Reported playhead advance error: about -0.2 ms.

The playhead jump was numerically close to the requested duration, but the
resume operation was requested late and the actual acoustic return was not
measured. Pausing and skipping also violates the preferred product behavior:
the song should keep advancing continuously while its gain is zero.

This fallback is not musician-credible validation and is not a production
path.

### Missing independent song beat

The lab did not detect the song's beat. It fit tempo and phase entirely from
the user's opening taps, then skipped by eight intervals of that estimated
pulse.

Independent song timing is essential to the current product. Public MusicKit
does not expose decoded PCM or a verified beat map for catalog songs, so the
lab could not establish whether a user's taps matched the actual song beat.

## Decision

- Preserve the touch-timing and scoring lessons.
- Preserve the physical finding that app-controlled audio can become silent.
- Do not continue the Apple Music path.
- Build future feasibility work around local app-controlled musical audio and
  verified beat maps.
- Do not begin that work until Phase 1 of the current roadmap is explicitly
  authorized.

## Running the frozen lab

Run only when the owner explicitly asks to reproduce or inspect the historical
experiment.

Requirements include Xcode 26 or newer and an appropriately signed iPhone build.

```sh
xcodegen generate
swift test
```

The project and portable tests are evidence from the prior phase. Passing them
does not pass a current roadmap gate.

## Primary references used by the experiment

- [MusicKit](https://developer.apple.com/documentation/musickit)
- [ApplicationMusicPlayer](https://developer.apple.com/documentation/musickit/applicationmusicplayer)
- [Music authorization](https://developer.apple.com/documentation/musickit/musicauthorization)
- [Music catalog search](https://developer.apple.com/documentation/musickit/musiccatalogsearchrequest)
- [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [UIEvent timestamp](https://developer.apple.com/documentation/uikit/uievent/timestamp)
