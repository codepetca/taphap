# TapHap AI Starting Checklist

Use this compact checklist at the start of every AI-assisted session.

## Start here

1. Resolve the repository root and inspect `git status --short --branch`.
2. Read [.ai/CURRENT.md](CURRENT.md).
3. Read [docs/ai-instructions.md](../docs/ai-instructions.md).
4. Load only the task-specific documents routed there.
5. Confirm whether the owner authorized discussion, documentation, a bounded
   feasibility phase, or product implementation. Do not infer authorization
   from the existence of a roadmap or experimental code.

## Boundaries

- The canonical product is the song-based game/trainer in
  [docs/product-brief.md](../docs/product-brief.md).
- The documentation update does not authorize Phase 1 implementation.
- The earlier MusicKit feasibility lab is frozen historical evidence, not the
  starting point for production UI.
- The MVP uses app-controlled, rights-cleared songs and touchscreen Tap and
  Strum input. It does not use streaming services, microphones, Watch, a
  backend, or a configurable metronome flow.
- Do not use fake workouts, inaudible keep-alive audio, deprecated volume APIs,
  private APIs, system-volume manipulation, or media extraction as
  workarounds.
- Do not commit secrets, credentials, signing material, or private audio-rights
  contracts.

## Before handing off

- Explain what changed and what remains locked or conditional.
- For documentation-only work, run `git diff --check` and review changed links.
- For approved code work, run the checks defined by that roadmap phase and
  report anything not run.
- Do not commit, push, publish, submit, deploy, purchase, or contact external
  parties unless the owner explicitly requests it.

## Source order

When project documents disagree, use this order:

1. The owner's latest explicit instruction.
2. [docs/product-brief.md](../docs/product-brief.md) for product behavior.
3. [ROADMAP.md](../ROADMAP.md) for sequence, phase scope, and exit gates.
4. [.ai/CURRENT.md](CURRENT.md) for current state and authority.
5. [docs/platform-constraints.md](../docs/platform-constraints.md) for dated
   technical and content constraints.
6. [docs/ai-instructions.md](../docs/ai-instructions.md) for task routing.
7. [README.md](../README.md).
