# TapHap Current Context

Read this file at the start of every AI-assisted session.

## Current design guidance pass — 2026-09-13

Implementation and technical verification are complete in draft PR #4; phase
acceptance remains pending. Owner requested OcuOtter-derived native design
principles before the walkthrough. This pass adds the
[UI standard](../docs/UI-UX-GUIDELINES.md) and
[flow gap assessment](../docs/phase-3-design-gaps.md) only. No app changes or phone
automation; coordinator owns the next alignment step and first-use observation.

## Phase 3 task-local work — 2026-09-13

Phase 3 implementation is active on the accepted Phase 2 merge `f4ab0fe`.
This task owns the bounded training MVP and its checkpoint PR; coordinator
retains phase acceptance, integration synchronization, and archival. Read
[training implementation and verification](../docs/phase-3-training-mvp.md).
The coordinator's worktree coordination file is authoritative for current
ownership; this task does not edit it. No Phase 4/release work is authorized.

## Current authorization and state — 2026-09-13

- Owner authorized functional Roadmap Phases 1–3, in-scope checkpoint commits,
  PRs and merges. Phase 4+, release and external integrations remain unauthorized.
- Phase 1 is accepted on the tested iPhone built-in speaker; PR #2 merged as
  `036e81d`.
- Phase 2 is accepted for MVP construction. Owner says results felt right and
  directs completion of the functional MVP before polish. Broader musician/click
  comparison is **deferred, not empirically passed**. No known engine defect waived.
  See [exact acceptance](evidence/phase2/acceptance.json).
- [PR #3](https://github.com/codepetca/taphap/pull/3) records Phase 2 integration.
  Coordinator verifies its merge and safely syncs before dispatching Phase 3.
- Phase 3 scope remains the roadmap's content, baseline, daily adaptation,
  checkpoints, transfer and earned rewards/history. This Phase 2 task does not
  dispatch or implement Phase 3. Follow [coordination state](COORDINATION.md).

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
- Source checkout: `/Users/stew/Repos/taphap`. Coordinator owns safe synchronization
  after Phase 2 merge; inspect its actual state before acting.
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
