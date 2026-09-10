# TapHap AI Starting Checklist

Use this compact checklist at the start of every AI-assisted session.

## Start here

1. Resolve the repository root and inspect `git status --short --branch`.
2. Read [.ai/CURRENT.md](CURRENT.md).
3. Read [docs/ai-instructions.md](../docs/ai-instructions.md).
4. Load only the task-specific documents routed there.
5. Confirm whether the user authorized planning, a feasibility spike, or
   product implementation. Do not infer authorization from earlier discussion.

## Boundaries

- The current product is the internal-clock exercise in
  [docs/product-brief.md](../docs/product-brief.md), not the earlier synchronized
  metronome or song-listener proposal.
- The planning lock prohibits source code and scaffolding until explicit user
  approval.
- Apple Music and Apple Watch are conditional features with documented gates.
- Spotify integration is out of scope.
- Do not use fake workouts, inaudible audio, deprecated volume APIs, private
  APIs, system-volume manipulation, or media extraction as workarounds.
- Do not commit secrets, credentials, signing material, or private audio-rights
  contracts.

## Before handing off

- Explain what changed and what remains conditional.
- For documentation-only work, run `git diff --check` and review changed links.
- For later code work, run the checks defined by the implementation phase and
  report anything not run.
- Do not commit, push, publish, submit, deploy, or change external services
  unless the user explicitly requests it.

## Source order

When project documents disagree, use this order:

1. The user's latest explicit instruction.
2. [docs/product-brief.md](../docs/product-brief.md) for product behavior.
3. [ROADMAP.md](../ROADMAP.md) for sequencing and gates.
4. [.ai/CURRENT.md](CURRENT.md) for current state.
5. [docs/platform-constraints.md](../docs/platform-constraints.md) for dated
   platform research.
6. [docs/ai-instructions.md](../docs/ai-instructions.md) for task routing.
7. [README.md](../README.md).
