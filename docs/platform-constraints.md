# TapHap Platform Constraints

This document records the current platform assumptions that affect product
scope. It is a dated engineering and product snapshot, not legal advice.
Re-verify official documentation and agreements before implementation and
again before App Store submission.

Last reviewed: 2026-09-10.

## Apple Music and MusicKit

Apple permits apps and games to let an authorized subscriber select and play
full Apple Music songs through MusicKit. Playback must be user-initiated and
standard controls such as play, pause, and skip must remain available.

Current technical shape:

- `ApplicationMusicPlayer` can own an app-specific queue and expose playback
  state and position.
- Public MusicKit does not expose decoded PCM audio or a supported per-player
  gain control.
- MusicKit's crossfade transition applies between queue items; it does not fade
  one playing song into silence.
- `MPMusicPlayerController.volume` is deprecated and must not be used as a
  product foundation.
- System output volume is user-controlled and must not be programmatically
  manipulated to implement an exercise.
- iOS 26 introduced boolean audio-session output muting. A physical-device
  spike must determine whether it cleanly mutes `ApplicationMusicPlayer` while
  its playhead continues and whether mute boundaries are accurate enough.
- Until that spike passes, do not claim that Apple Music can fade, mute, or
  return with musician-grade accuracy.

Current policy shape:

- MusicKit access itself cannot be required as a paid feature or indirectly
  monetized.
- Apple states that MusicKit content cannot be synchronized with other content
  unless its documentation permits it.
- Apple warns that deeper integrations may require permission from
  rightsholders.
- TapHap's proposed timing exercise therefore requires policy clarification;
  technical access is not sufficient evidence that the use is permitted.
- Do not download, record, cache, transform, export, or share Apple Music audio.
- Keep Apple Music optional and preserve the bundled-audio product.

Official references:

- [MusicKit](https://developer.apple.com/documentation/musickit)
- [ApplicationMusicPlayer](https://developer.apple.com/documentation/musickit/applicationmusicplayer)
- [MusicPlayer playback time](https://developer.apple.com/documentation/musickit/musicplayer/playbacktime)
- [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [App Review Guidelines, Apple Music](https://developer.apple.com/app-store/review/guidelines/#apple-music)
- [Apple Developer Program License Agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)

## Spotify

Do not build against Spotify for the planned exercise. Its current developer
policy prohibits games, analysis of Spotify content, and several forms of
synchronized or mixed use. Do not describe TapHap as a Spotify integration or
use Spotify branding without separate approval.

Official reference:

- [Spotify Developer Policy](https://developer.spotify.com/policy)

## Apple Watch

Apple Watch remains conditional because reliable wrist-down haptics require a
legitimate supported runtime mode.

- Do not use an inaudible audio loop to manufacture background execution.
- Do not create a workout session unless the product is genuinely recording a
  qualifying workout.
- Do not select self-care, mindfulness, physical-therapy, alarm, or another
  extended-runtime category merely because it grants desired execution time.
- Validate Core Haptics availability, scheduling, suspension behavior, and
  minimum OS support on physical devices.
- Keep the iPhone experience independently complete.

Official references:

- [watchOS background execution](https://developer.apple.com/documentation/watchkit/background-execution)
- [Using extended runtime sessions](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions)
- [Core Haptics](https://developer.apple.com/documentation/corehaptics)

## Audio assets

Every bundled groove must be either wholly owned or covered by an express
written license that includes the intended app, game, promotional, editing,
looping, territory, and duration rights. Preserve contracts and source records
outside the public repository and record a non-sensitive provenance summary in
the project before release.

Do not treat an Apple Music subscription, Spotify subscription, purchased song,
preview, or short duration as permission to bundle commercial music.
