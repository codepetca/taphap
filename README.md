# TapHap

**TapHap is the rhythm game where the music disappears.**

A player taps or strums with a song, continues after the song fades to silence,
and discovers whether their internal pulse is still aligned when the music
returns.

## Product promise

> Play for a few minutes a day and measurably improve your ability to maintain
> rhythm without an external cue.

TapHap is designed for musicians first but presents a challenge anyone can
understand: **When the music comes back, will you still be on beat?**

## Core experience

1. Choose a prebuilt song challenge.
2. Play using a drum-inspired Tap surface or virtual-string Strum surface.
3. Lock onto the audible song.
4. Continue through a silent gap with no rhythmic cue.
5. Hear the song return and receive a consistency, drift, and re-entry result.
6. Retry, progress, and compare later checkpoint sessions with the Day 1
   baseline.

The first release is planned around app-controlled, rights-cleared musical
tracks with verified beat maps. It does not depend on BPM entry, a streaming
subscription, microphone, account, backend, Apple Watch, or external hardware.

## Project status

The owner authorized implementation through Phases 1–3 sequentially. The
separate Phase 1 audio/scoring lab has passed its bounded feasibility gate on
the tested iPhone built-in speaker. See [Phase 1 evidence](docs/phase-1-core-feasibility.md)
and [current coordination](.ai/COORDINATION.md) for checkpoint integration and
next-phase ownership. This is not release or other-route validation.

The repository also contains an earlier iPhone feasibility lab. Its
app-controlled reference path demonstrated the basic silent-gap timing model;
its Apple Music path failed to mute playback as required. The lab is retained
as historical engineering evidence and must not be expanded into product UI.

## Start here

- [Product direction](docs/product-brief.md)
- [Roadmap](ROADMAP.md)
- [Platform constraints](docs/platform-constraints.md)
- [Historical feasibility lab](docs/phase-1-feasibility-lab.md)
- [AI instructions](docs/ai-instructions.md)

## Experimental lab

The frozen `TapHapLab` uses a native iOS project plus a Swift package for its
portable timing tests. If work on that historical experiment is explicitly
requested:

```sh
xcodegen generate
swift test
```

Passing those tests does not authorize or validate a production app.

## License

The source is publicly visible for inspection only. Use requires the copyright
holder's prior express written consent. See [LICENSE](LICENSE).
