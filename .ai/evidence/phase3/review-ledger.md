# Phase 3 checkpoint review ledger

Scope: new bounded training MVP on accepted Phase 2 merge `f4ab0fe`.
Risk: high for persisted-history migration and foundational training state.
Planned initial reviewers: GPT-5.6 Sol/high for migration, state integrity,
failure/concurrency and honest claims; GPT-5.6 Terra/high for architecture,
compatibility, roadmap coverage, tests and documentation. Read-only reviewers.

Budget: at most 2 concurrent, 5 launches total, one initial full-diff wave,
3 targeted remediation waves, 1 final integration wave, 3 fix batches,
45 minutes elapsed review session and 20 minutes per reviewer. Stop at limits.
No reviewer launches yet; budget starts with initial dispatch.

Verification before review: 34 portable tests pass, initial hosted integration
passes; initial UI full journey had an off-screen test-control tap failure,
corrected by requiring visible control centers. Targeted rerun pending.
All raw failures remain in durable private evidence. No failure is relabeled a pass.
Phone history backed up read-only: 10 schema-1 trials and 10 diagnostic files.
Signed build succeeds; no phone installation/automation yet.

Initial review starts 2026-09-13 16:14:23 UTC on implementation `0e1f372`.
Launches 1–2: Sol/high and Terra/high, initial full-diff wave; 0 fix batches.
Targeted simulator journey passed (120.687 seconds), including process relaunch,
three practice days, later checkpoint and reserved transfer. Draft PR #4 opened.

Initial wave completed: Sol identified run/step provenance, content identity,
and semantic progress-validation blockers. Terra identified missing armed
training lifecycle tests, stale verification status, and the genuine outstanding
new-player comprehension observation. All implementation/test findings accepted;
the human observation remains a coordinator-owned phase-exit condition.

Remediation batch 1: persisted run/step association (legacy nil), pinned plan
content, canonical schedule replay and high-water/plan corruption rejection;
updated-content protection for current chapters/reliable gap; armed training
notification/stop tests; UTC day display and unconstrained history summary text.
36 portable tests and focused training lifecycle/storage tests pass. Full UI
journey rerun is in progress. No second reviewer wave has started yet.

Remediation app journey passed again (118.285 seconds). Actual ten-record
migration recheck passes. Added focused comparison-text and oldest-history
reachability assertions, including largest Dynamic Type; their UI rerun is
pending. Targeted review launch 3: Sol/high, only correction and interaction
boundaries; launches used 3/5, fix batches 1/3. Human exit observation still open.

Targeted launch 3 completed in about 6 minutes (clock checked16:35:30UTC).
The reviewer mistook the total-session start16:14 for its own start around16:30
and described a20minute cap; actual tool timestamps show no individual timeout.
Two further structural checks accepted: newest-created-session day equality,
and valid associations for unconsumed/rejected attempts. A legitimate existing
resume path advanced the day marker without a new run; batch2 changes that path
before enforcing equality. All attempted references, including failed retries,
now require an existing run and valid step/mode/challenge/content.

Batch2:37 portable tests pass; native later-day resume/lifecycle/storage recheck
in progress. Launch4 will be one targeted Sol/high correction review; launch5
reserved for final cumulative integration. Fix batches used2/3, launches3/5.
Oldest-history and largest-text UI checks passed (165.218s); sanitized screenshots
are synthetic examples, not human longitudinal evidence.
