# TapHap Product Direction

## Product statement

**TapHap is the rhythm game where the music disappears.**

It is a song-based internal-clock trainer. A player locks onto a musical track,
continues the pulse after the track fades to silence, and learns how accurately
they held the rhythm when the music returns.

TapHap should feel like a game first and remain an honest training instrument
underneath. It is not a conventional metronome with rewards added to it.

## Audience and positioning

Build first for musicians and music students who want steadier time. Present
the challenge in language that anyone can understand:

> When the music comes back, will you still be on beat?

Singer-players and singer-songwriters are an important future audience because
maintaining rhythm while attention moves to lyrics or melody is a natural
extension of the core skill. The initial product does not need to listen to a
physical instrument or voice.

## Core promise

> Play for a few minutes a day and measurably improve your ability to maintain
> rhythm without an external cue.

The first session must be enjoyable without music-theory knowledge, BPM entry,
time-signature setup, or metronome configuration.

## What makes it different

- Traditional rhythm games show the player when to act. TapHap removes the cue
  and asks the player to generate the missing pulse.
- Gap metronomes use clicks and expose configuration. TapHap uses enjoyable
  musical tracks and prebuilt challenges.
- A normal metronome supplies time. TapHap measures whether the player can
  continue carrying time after the reference disappears.

The absence of the song is the gameplay, and its return is the payoff.

## Canonical game loop

1. Choose a song challenge.
2. Choose **Tap** or **Strum**.
3. Play with the audible song until locked onto its pulse.
4. Receive a clear, non-rhythmic warning that a gap is approaching.
5. The song fades to silence while its playback timeline continues.
6. Keep tapping or strumming without beat, bar, visual, or haptic cues.
7. The song fades back in at its correct continuing position.
8. See whether the pulse stayed steady, accelerated, slowed, or shifted.
9. Retry, beat a personal best, or move to the next challenge.

## Input modes

### Tap

- Present one large, drum-inspired surface.
- Timestamp touch-down as the rhythmic event.
- Permit a small response to the player's own touch, but never generate a
  continuing beat cue during silence.
- Later exercises may add alternating hands, backbeats, or subdivisions.

### Strum

- Present virtual strings that the player swipes across.
- Timestamp a defined reference crossing, not gesture completion.
- Record down/up direction separately from rhythmic timing.
- Begin with downstrums on quarter notes; later exercises may add alternating
  strums and simple learned patterns.

Both modes use the same audio timeline, gap scheduler, baseline model, scoring,
and history. They are touchscreen game inputs, not claims that TapHap hears a
real drum or guitar.

## Audio and beat-map contract

- The guaranteed product uses app-controlled, fully owned or expressly
  licensed musical audio.
- Every included track has a verified beat map. A variable-tempo performance
  may be used only when its beat positions are explicitly mapped.
- The player never has to discover or enter a BPM.
- During a gap, audio gain fades to zero; playback does not pause or skip.
- The hidden song and beat timelines continue continuously through silence.
- The return is scheduled from the audio timeline rather than a UI timer.
- Song audio, beat maps, and rights provenance must be reproducible build
  inputs. Private contracts stay outside the public repository.

## Visual contract

The game may communicate that silence is approaching and approximately when
the music will return. It must not provide another beat to follow.

Allowed during silence:

- A single continuous progress arc across the entire gap.
- Overall song or challenge progress.
- A gradual, non-pulsing change near the return.
- A small response caused only by the player's own tap or swipe.

Not allowed during the standard challenge:

- Beat-synchronized pulses, flashes, animation, or haptics.
- Beat or bar tick marks.
- Numeric beat countdowns.
- Repeating movement that functions as a visual metronome.

## Honest scoring

The opening audible section establishes the player's session baseline and
stable phase preference. Scoring should emphasize change through the hidden
section rather than demanding an artificial zero-millisecond opening offset.

Core measures:

- **Consistency:** variation between rhythmic inputs.
- **Tempo drift:** whether the player accelerates or decelerates.
- **Re-entry error:** early or late position when the song returns.
- **Reliable gap:** longest gap held within the selected tolerance.

Show one simple result first, followed by optional detail. A composite score or
grade must be traceable to these measures. Compare improvement only across
compatible track, section, difficulty, input mode, assistance, and audio-route
conditions.

## Game and training structure

### Baseline

Day 1 uses repeated short trials on a designated benchmark track to establish
the player's starting ability. Do not treat one lucky or missed tap as a
baseline.

### Daily play

A normal session should take roughly three to five minutes:

1. Warm-up.
2. Two progressive challenges.
3. One personalized challenge.
4. Result, personal best, and next goal.

Difficulty adapts through longer gaps, less preparation, unpredictable gap
placement, different tempos, subtler grooves, and more demanding tap or strum
patterns.

### Proof of improvement

- Repeat the same benchmark song section under the same conditions on later
  checkpoint days.
- Report the change from the player's own baseline in plain language.
- Periodically use a different track as a transfer test so familiarity with
  one song is not mistaken for a general improvement in internal time.

### Gamification principles

Use personal bests, stars, grades, skill chapters, adaptive difficulty, and a
clear perfect-landing moment. Rewards must represent demonstrated skill.

Do not add coins, energy, consumable lives, ads, compulsory social mechanics,
or rewards based only on opening the app. Global leaderboards are inappropriate
until scoring is demonstrably comparable across devices and conditions.

## MVP boundary

The first release is intentionally narrow:

- Native iPhone app.
- A small launch set of app-controlled, rights-cleared songs with verified beat
  maps.
- Tap and Strum touchscreen modes.
- Song fade, silent continuation, precise return, and trustworthy scoring.
- Day 1 baseline, short daily challenges, checkpoint retests, transfer tests,
  personal bests, and local history.
- No required account, network, microphone, or subscription.
- No BPM, meter, or subdivision configuration in the primary flow.

## Post-MVP direction

### Split Focus

Train rhythmic independence by asking the player to read, speak, count, or sing
from memory while tapping or strumming. Static text and prompts may occupy
attention but may not advance in time with the hidden beat. Compare the result
with the player's normal baseline to show the cost of divided attention.

### Other gated possibilities

- User-imported DRM-free audio with on-device beat analysis and a correction
  path for uncertain beat maps.
- Physical-instrument onset detection through microphone, USB audio, or MIDI.
- Teacher-assigned challenges and progress sharing.
- Apple Watch or social features only after the standalone iPhone product is
  successful and a separate feasibility plan is approved.

## Explicit non-goals for the MVP

- Apple Music or Spotify playback.
- A generic metronome control panel.
- Physical-instrument or vocal recognition.
- Falling-note charts or imitation of Guitar Hero, DDR, or another game's
  protected presentation.
- A commercial-song catalog or licensing workaround.
- Apple Watch, synchronized groups, multiplayer, social feeds, or a backend.
- Claims that one universal score measures every kind of musicianship.

## Definition of a successful first release

- A new player reaches the first song gap without needing instructions outside
  the game.
- The fade, silence, return, and score feel reliable on supported devices.
- Tap and Strum feel distinct while producing comparable timing evidence.
- Repeated benchmark results are stable enough to show real change.
- A transfer challenge distinguishes song familiarity from broader skill.
- Players voluntarily retry to improve their result.
- The product is useful offline and without streaming services or extra
  hardware.
