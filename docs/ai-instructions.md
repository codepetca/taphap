# AI Instructions for TapHap

This file routes AI agents to the right project context. Keep startup compact
and load only the documents needed for the current task.

## Default startup context

Read these at the beginning of every session:

1. [`.ai/START-HERE.md`](../.ai/START-HERE.md)
2. [`.ai/CURRENT.md`](../.ai/CURRENT.md)
3. [`docs/ai-instructions.md`](ai-instructions.md)

Then load task-specific documents below.

## Task routing

| Task | Read next |
|---|---|
| Product scope, UX, scoring, game mechanics, or copy | [Product direction](product-brief.md), then [roadmap](../ROADMAP.md) |
| Roadmap or prioritization | [Roadmap](../ROADMAP.md), then [product direction](product-brief.md) |
| Audio playback, beat maps, content rights, imports, or streaming | [Platform constraints](platform-constraints.md) and current official documentation when needed |
| Earlier MusicKit or timing experiment | [Historical feasibility lab](phase-1-feasibility-lab.md); do not treat it as an active plan |
| Feasibility implementation | The explicitly authorized roadmap phase and its exit gate |
| Product implementation | Product direction, roadmap, platform constraints, relevant source, and explicit phase authorization |
| Documentation-only change | Relevant document only; preserve the implementation lock |

## Product invariants

- The product is a song-based game/trainer, not a generic metronome.
- The primary flow requires no BPM, meter, or subdivision configuration.
- The MVP uses app-controlled, rights-cleared songs with verified beat maps.
- Tap and Strum are touchscreen inputs sharing one timing and scoring engine.
- Audio fades to zero while its timeline continues; it does not pause and seek
  across the gap.
- Silent-gap visuals communicate overall progress but never individual beats.
- Day 1 baseline and later improvement claims use multiple compatible trials.
- Transfer tests use a different song so familiarity is not presented as
  general skill improvement.
- Core scoring remains explainable as consistency, tempo drift, and re-entry
  error.
- The standalone core requires no streaming service, microphone, Watch,
  account, network, backend, or subscription.

## Implementation discipline after approval

- Begin with the smallest authorized phase and its exit gate, not the full app.
- For timing math, beat-map conversion, scoring, progression, persistence, and
  state machines, create deterministic tests before or alongside
  implementation.
- Keep audio sample time, touch-event time, UI animation time, and wall-clock
  time explicitly separated.
- Treat playback and input latency as measured route conditions rather than
  guessed constants.
- Use public, documented platform APIs only.
- Do not add a backend, analytics SDK, authentication, cloud storage, music
  service, audio asset, or third-party dependency without a scoped decision.
- Preserve unrelated user changes and stop if work overlaps unexpected edits.

## Authority

- The owner explicitly authorized local implementation and verification
  through Phases 1–3 sequentially, plus in-scope checkpoint commits, PRs and
  merges after each genuine phase gate passes. See current coordination state.
- The Phase 1A/1B iPhone lab remains frozen historical evidence.
- A roadmap is not implementation permission. Confirm the authorized phase
  before changing source, project configuration, dependencies, or assets.
- Current authority does not permit changing product direction, buying or
  licensing content, contacting third parties, release publishing, deployment,
  or App Store submission. Do not expand beyond the active phase assignment.

## Verification

- Documentation-only: run `git diff --check` and verify changed local links.
- Platform claims: prefer current primary sources and record the review date.
- Swift changes: run tests and physical-device checks defined by the authorized
  phase.
