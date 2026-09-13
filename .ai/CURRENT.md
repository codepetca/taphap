# TapHap Current Context

Read this file at the start of every AI-assisted session.

## Current authorization update — 2026-09-12

The owner has now explicitly authorized local implementation and verification
through Roadmap Phases 1–3, sequentially, from the inherited working-tree
snapshot. Phase 0 is ratified. Follow [coordination state](COORDINATION.md) for
the active phase, task ownership, exact authority, evidence, and blockers.
The documentation-only status below records the inherited pre-orchestration
state; it does not override this newer instruction. The owner subsequently
authorized in-scope commits, pushes, PRs, review/CI fixes, and phase-checkpoint
merges after each Phase 1–3 exit gate is genuinely satisfied. Preserve the
inherited baseline in the first checkpoint PR. Phase 4 release activity and
later expansion remain unauthorized. See coordination state for the complete
authority and delivery boundaries.

## Current shape

- Product: a song-based rhythm game and measurable internal-clock trainer.
- Hook: **When the music comes back, will you still be on beat?**
- Repository: canonical product documentation, a separate Phase 1 audio/scoring
  lab, and the frozen historical feasibility lab.
- Status: Phase 0 ratified; Phase 1 feasibility gate accepted for the tested
  iPhone built-in speaker, checkpoint PR #2 merged to main as `036e81d`.
  Phase 2 one-song vertical slice is active in its owning execution task;
  actual musician product acceptance remains pending.
- Authority: owner explicitly authorizes implementation/verification through
  Phases 1–3 and checkpoint commits/PRs/merges once each genuine phase gate passes.
  See coordination state for current evidence and exact exclusions.

## Current product decisions

- TapHap is a game first and a real trainer underneath, not a configurable
  metronome with rewards added.
- The guaranteed audio source is a small set of app-controlled, fully owned or
  expressly licensed songs with verified beat maps.
- A song fades to zero while its hidden timeline continues, then returns at the
  correct continuing position.
- The MVP has two touchscreen inputs: drum-inspired **Tap** and virtual-string
  **Strum**.
- No beat, bar, visual, or haptic cue may continue through a standard gap. A
  continuous non-rhythmic progress indicator is allowed.
- Day 1 establishes a baseline from multiple trials. Later checkpoint sessions
  repeat compatible conditions, and transfer tests use different songs.
- Scoring explains consistency, tempo drift, and re-entry error before any
  composite grade.
- History is local; the core requires no account, network, microphone,
  streaming subscription, or external hardware.
- Split Focus—reading, speaking, or singing while playing—is the first planned
  post-MVP expansion.

## Historical feasibility result

- The earlier reference-click lab demonstrated working silent-gap behavior for
  app-controlled audio and portable timing/scoring tests.
- On the tested physical iPhone, `AVAudioSession.setOutputMuted` did not mute
  `ApplicationMusicPlayer` output.
- A pause/seek/resume fallback advanced the reported playhead by the intended
  duration but requested re-entry too late and did not measure acoustic return.
- MusicKit does not provide the decoded song audio or verified beat map needed
  for the essential independently mapped-song experience.
- Therefore Apple Music is not an active product path. Do not continue or
  productize that experiment without a new roadmap decision.

## Superseded concepts

Do not revive these without an explicit product-direction revision:

- Multi-iPhone or peer-to-peer synchronized metronomes.
- WatchConnectivity as a group network bridge.
- Apple Music or Spotify as the core audio source.
- Shazam-style passive listening or ambient song recognition.
- A metronome-first settings interface.
- Physical-instrument recognition in the MVP.

## Repository facts

- Repository: `codepetca/taphap`
- Default branch: `main`
- Source checkout branch: `main`, synchronized to Phase 1 merge `036e81d`.
  Phase 2 executes separately in worktree `21e6`; see coordination state.
- Authorized implementation stack: native Swift and SwiftUI.
- Existing experimental stack: iOS 26 lab, XcodeGen project description, and a
  Swift package for portable core tests.
- Canonical product direction: [docs/product-brief.md](../docs/product-brief.md)
- Canonical roadmap: [ROADMAP.md](../ROADMAP.md)
- Platform constraints: [docs/platform-constraints.md](../docs/platform-constraints.md)
- Historical lab record: [docs/phase-1-feasibility-lab.md](../docs/phase-1-feasibility-lab.md)
- License: public inspection only; express written consent required for use.

## Normal checks

- Documentation-only: `git diff --check` and changed-link review.
- Guidance-only: confirm all startup and routing links resolve.
- Frozen lab, if explicitly requested: `swift test`, then build the
  `TapHapLab` and `TapHapLabTests` targets.
- New code: use only the checks and targets established by the explicitly
  authorized roadmap phase.
