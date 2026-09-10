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
| Product scope, UX, scoring, or copy | [Product brief](product-brief.md) and [roadmap](../ROADMAP.md) |
| Roadmap or prioritization | [Roadmap](../ROADMAP.md), then [product brief](product-brief.md) |
| Apple Music, Spotify, audio sessions, or content rights | [Platform constraints](platform-constraints.md) and the current official terms linked there |
| Apple Watch or haptics | [Platform constraints](platform-constraints.md), [roadmap](../ROADMAP.md), and current official watchOS documentation |
| Feasibility experiment | Relevant Phase 1 gate in the [roadmap](../ROADMAP.md); confirm explicit implementation approval first |
| Product implementation | All three canonical documents; confirm explicit implementation approval and the authorized phase |
| Documentation-only change | Relevant document only; preserve the planning lock |

## Product invariants

- The primary exercise does not require a BPM number.
- Opening taps establish a session baseline; later change is measured relative
  to stable initial behavior.
- Silent-gap visuals communicate overall progress, never individual beats.
- The core must work with bundled audio and without subscriptions, accounts,
  microphones, networks, Watch, or cloud services.
- Apple Music and Apple Watch remain gated enhancements rather than foundations.
- Spotify integration is not an implementation option under the current plan.
- User improvement claims must compare compatible sessions and avoid a
  misleading universal score.

## Implementation discipline after approval

- Begin with the smallest authorized feasibility gate, not the full app.
- For timing math, scoring, state machines, and data transformations, create
  deterministic tests before or alongside implementation.
- Keep audio time, UI time, wall-clock time, and cross-device time explicitly
  separated. Use monotonic timing for interval measurement.
- Treat Bluetooth and playback latency as measured session conditions, not
  guessed constants.
- Use public, documented platform APIs only.
- Re-verify platform availability and policy terms at implementation and App
  Store submission time; the platform document is a dated snapshot.
- Do not add a backend, analytics SDK, authentication, or remote storage without
  an explicit product decision.

## Authority

- Planning permission does not authorize source code or scaffolding.
- Implementation permission does not authorize changing the roadmap, shipping
  conditional features, purchasing licenses, contacting third parties,
  committing, pushing, or submitting to the App Store.
- Preserve unrelated user changes and stop if work overlaps unexpected edits.

## Verification

- Documentation-only: run `git diff --check` and verify changed local links.
- Platform claims: prefer current primary sources and record the review date.
- Later Swift changes: run the relevant unit tests and physical-device checks
  defined by the authorized roadmap phase.
