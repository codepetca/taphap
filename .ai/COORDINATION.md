# TapHap MVP coordination

## Authority and goal

Owner instruction on 2026-09-12 explicitly authorizes local implementation and
verification through ROADMAP.md Phases 1–3, sequentially. It ratifies Phase 0
and supersedes the earlier documentation-only lock for this scope. Product
direction and phase exit gates remain unchanged.

Additional explicit owner authority, received through **Main TapHap roadmap**
(`01a0882f-67ff-74a3-86df-2a6cf343417b`) on 2026-09-12: coordinator and bounded
execution tasks may commit in-scope changes, push branches, create/update PRs,
address reviews and CI, and merge into this repository's default `main` only
after the corresponding Phase 1–3 exit gate is genuinely satisfied. Prefer one
coherent checkpoint PR per phase: inherited baseline plus validated Phase 1,
then Phase 2, then Phase 3. Never merge failing, incomplete or unverified work.
Use the normal review workflow and `hq-pr-review` for proportionate independent
review with its bounded ledger; the owning execution task runs that lifecycle.
This authority was propagated to the active Phase 1 task.

Phase 4+, releases, deployment, App Store submission, purchases, licensing
deals, external messages, streaming, Watch, microphone/instrument recognition,
backend and social features remain unauthorized.

Coordinator: `01a0989f-1811-7a53-825d-84d761c57044` — Orchestrate TapHap MVP.
Tool-backed goal confirmed active on startup: orchestrate and deliver authorized
Phases 1–3 in order, verifying each exit gate and stopping before Phase 4.

## Baseline and integration

Coordinator worktree: `/Users/stew/.codex/worktrees/c999/taphap`, detached at
`2e0310b`. The source checkout `/Users/stew/Repos/taphap` remains on
`codex/phase-1-feasibility-lab`. All 29 inherited files were compared with the
source checkout before dispatch and matched. See
[baseline manifest](evidence/inherited-baseline.json) for exact hashes, status,
and a local archival snapshot. The eight modified documentation files and
untracked historical lab/package/project files are inherited owner work, not
new MVP delivery. No commit or clean-tree claim is made.

Each execution task uses an isolated worktree with the inherited working-tree
snapshot. Implementation changes are reviewed as a delta from that snapshot;
accepted work now follows the authorized phase-checkpoint PR workflow,
preserving unrelated work. The historical lab stays frozen. Coordinator owns
this record; execution tasks own implementation and evidence documents. Before
committing the checkpoint, sync the final coordination record by agreement with
the coordinator; do not overwrite concurrent updates. Synchronize checkouts
only after inspecting their dirty state and verifying inherited-file equality.

Coordinator baseline verification: `swift test` passed all 7 inherited tests
on 2026-09-12 before any MVP package change. `git diff --check` and coordination
link checks passed. Only `.ai/CURRENT.md` differs from the archived inherited
files here, to record new authority; baseline content is otherwise preserved.

## Phase state and gates

| Phase | State | Exit evidence |
| --- | --- | --- |
| 0 | Ratified by current instruction | Local implementation through Phases 1–3 explicitly requested |
| 1 | Implementation and review active; physical gate open | Initial 13 package/9 simulator tests pass; signed phone build passes; device test blocked by developer disk image mount error; direct install under investigation |
| 2 | Waiting for Phase 1 exit | Reliable/understandable one-song loop and musician comparison with click practice; engagement requires observed product testing |
| 3 | Waiting for Phase 2 exit | Multi-trial baseline, daily session, compatible checkpoint improvement and transfer; required deterministic and usability evidence |
| 4+ | Not authorized | Do not dispatch |

Physical iPhone 16 is reported available and paired at startup. Availability is
not acoustic or usability acceptance. Complete independent local work before
requesting any remaining owner observation/action. Do not weaken a gate to
advance the roadmap.

## Execution tasks

`01a098a0-eb9c-77a3-a6e0-87b457663a45` — **Validate TapHap Phase 1 audio and scoring**.
Project `5973b045-8468-4b64-9a9b-dd9bd10d8401` (taphap), local host, isolated
worktree `/Users/stew/.codex/worktrees/844e/taphap`, inherited working-tree
starting state. Model/effort: app-configured defaults; no override requested.
Owns Phase 1 implementation, deterministic checks, device verification and
`docs/phase-1-core-feasibility.md`. Dependency: reconciled inherited baseline.
Startup goal confirmed active by execution task after successful creation and
recheck; initial retrieval omitted those outputs and one follow-up clarified
them. Baseline verification confirmed `verified: 29, discrepancies: []` before
changes; current authority and coordination records copied into its worktree.
Latest compact wait cursor: `f81e82f9-1482-4beb-a83c-e3d533317518:28`.
Coordinator inspected initial package and iOS test logs: 13 package tests
(including 7 inherited) and 9 simulator tests passed. Asset verification records
64 attacks within 3 frames (0.0625 ms); task reports zero rendered gap energy
and unchanged return position over all 1,632,000 samples. These are initial
pre-review results, not final revision acceptance. Coordinator independently
hash-verified all 18 frozen lab/test/project/evidence files unchanged.
Updated
commit/PR authority acknowledged by task. Before staging, it will refresh the
coordinator-owned authority/coordination files without overwriting local edits.
PR/merge is now authorized once all gates pass, but no PR/merge exists yet.
Execution task owns the single review budget ledger; coordinator will verify
fixed-revision evidence without launching duplicate reviews. No archive yet.
Initial review wave started 2026-09-13 02:49 UTC: Sol high (timing/concurrency/
failure handling) and Terra high (architecture/coverage/compatibility), 2/5
launches, 0/3 fix batches. See execution worktree
`.ai/evidence/phase1/review-ledger.md` for authoritative evolving budget.
Default: one independently verifiable execution increment at a time.

GitHub read-only verification: `origin` is `https://github.com/codepetca/taphap.git`,
default branch is `main`, viewer has ADMIN access, and no competing open PR
exists as of 2026-09-12. Authority does not bypass branch rules or phase gates.

## Monitoring and next action

Monitor Phase 1 implementation and evidence; startup checks are complete.
Heartbeat `coordinate-taphap-mvp-phases` is ACTIVE every 15 minutes, attached to
this coordinator. Notify only meaningful changes or needed action. Pause when
only non-autonomous acceptance remains. Never dispatch Phase 2 before Phase 1
exit evidence satisfies the roadmap.
