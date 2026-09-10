# TapHap Current Context

Read this file at the start of every AI-assisted session.

## Current shape

- Product: music-based internal-clock trainer with a secondary metronome.
- Repository: documentation and a consent-required source license only.
- Status: product planning; no implementation exists.
- Authority: implementation is not authorized until the user explicitly says
  to begin a phase or implementation task.

## Current product decisions

- The training flow requires no BPM entry.
- The user taps with audible music, continues through silence, and receives a
  drift and consistency result when music returns.
- During silence, a one-way progress visual may show when music returns but may
  not pulse, tick, or expose individual beats.
- Bundled original audio is the guaranteed core.
- Apple Music is conditional on policy clarification and physical-device
  timing tests.
- Spotify integration is excluded.
- Apple Watch is conditional and the iPhone product must stand alone.
- Practice history is local by default; there is no account or backend.

## Superseded concepts

Do not revive these without an explicit roadmap revision:

- MultipeerConnectivity or multi-iPhone clock synchronization.
- WatchConnectivity as a network bridge for groups.
- Automatic microphone or Shazam-style song detection.
- A commercial-song clip catalog.
- A Spotify-based game.

## Repository facts

- Repository: `codepetca/taphap`
- Default branch: `main`
- Implementation stack: not yet created; expected direction is native Swift and
  SwiftUI only after approval.
- Canonical product brief: [docs/product-brief.md](../docs/product-brief.md)
- Canonical roadmap: [ROADMAP.md](../ROADMAP.md)
- Dated platform research: [docs/platform-constraints.md](../docs/platform-constraints.md)
- License: public inspection only; express written consent required for use.

## Normal checks

- Documentation-only: `git diff --check` and manual link review.
- Guidance-only: confirm all startup and routing links resolve.
- Code checks: undefined until an approved implementation phase establishes the
  project and test targets.
