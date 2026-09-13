# Phase 1 checkpoint review

[Draft PR #2](https://github.com/codepetca/taphap/pull/2), branch
`codex/phase-1-core-feasibility`. Owner authorization permits draft checkpoint
commits, pushes and PRs while physical acceptance is pending. Merge and Phase 2
advancement require the genuine physical phase exit gate; neither is approved
by technical review alone. The PR remains draft and unmerged.

Reviewed implementation commit:
`71b695d48f26e7680da29df3566a38664ec2a8ba`.
The final evidence-only commit updates this ledger and delivery metadata; it
does not change the reviewed implementation or its source manifest.

Risk: high (foundational audio/time-domain/scoring architecture).
Used HQ PR Review skill. Reviewers inspected only and did not edit or approve.

| Wave | Reviewer | Result |
| --- | --- | --- |
| Initial, timing/failure correctness | GPT-5.6 Sol, high | Two P1 lifecycle findings accepted |
| Initial, architecture/coverage/compatibility | GPT-5.6 Terra, high | No actionable findings |
| Targeted remediation | GPT-5.6 Sol, high | Both P1 findings resolved; no new blockers |
| Final cumulative integration | GPT-5.6 Terra, high | No new blockers; 44/44 final source hashes match; historical lab preserved |

One remediation batch resolved both findings:

- Preparation-time environmental notifications now cancel the current startup
  generation; a delayed arm cannot resurrect an invalid trial. All five
  monitored notifications are tested before arming.
- A media-services reset rebuilds the engine/player and clears their old
  configuration before retry. Reset followed by a new render is tested.

Validation: 13 Swift package tests, 11 iOS simulator tests, 2 final focused
lifecycle tests, signed device build-for-testing, historical app/test build,
asset verification and final unattended app diagnostic path passed. See
[verification summary](verification-summary.json) and
[phase evidence](../../../docs/phase-1-core-feasibility.md).

Review-session budget used: 4/5 reviewer launches, 1/1 initial wave, 1/3 fix
batches, 1/3 targeted waves, 1/1 final integration wave; at most 2 concurrent.
Started 2026-09-13 02:49 UTC; completed approximately 03:02 UTC (13 minutes),
within the 45-minute total and 20-minute per-reviewer caps. No extra review
wave is warranted for unchanged source.

GitHub reports no configured checks. No external review or approval is claimed.
Initial physical tests were blocked by the locked phone. After owner unlock,
installation and all 11 automated physical tests passed on the unchanged
reviewed source; see physical-device-tests.json. Owner subsequently confirmed the acoustic loop. Three real trials (two Tap,
one Strum) were captured, but all official scores were withheld as ambiguous.
Scoring usefulness and between-trial Strum repeatability remain unverified. No phase-exit pass,
merge, or Phase 2 advancement is recorded.

Physical evidence update only: no implementation change and no new review wave.
The existing source review remains valid.

Human-evidence update: owner-observations.json records the actual capture
metrics and current scoring limitation. It does not weaken the phase gate or
change the reviewed source. Any subsequent scoring fix needs focused validation
and proportionate review of the changed behavior.

## Physical-feedback remediation batch 2 — pending review

The owner’s three trials exposed a result-model limitation. Batch 2 preserves
reliable audible baseline and observed-interval facts when beat assignment
fails, while withholding landing/full score. Captured ambiguity and clock or
lifecycle invalidations still suppress all timing claims. Normalized physical
replays and phase-wrap, missed/duplicate, invalid-clock and baseline-failure
cases are covered. Local verification: 21 Swift tests and 16 affected iOS
simulator tests passed; signed build-for-testing passed. The phone app has not
been replaced. See assessment-verification.json and assessment-source-sha256.json.

This code is **not covered by the earlier clean review**. Source manifest
source-revision-sha256.json remains the historical manifest of reviewed commit
71b695d; assessment-source-sha256.json identifies the current unreviewed patch.
Used budget remains 4/5 launches, 1 initial wave, 2/3 fix batches, 1/3 targeted
waves and 1/1 final integration. At 03:36 UTC, 47 wall-clock minutes have elapsed
since the 02:49 session start, including the owner’s physical-testing interval.
No reviewer is being launched. Requested proposal through coordinator: one
focused Sol/high review of assessment/contamination/replays, then one bounded
Terra/high cumulative integration review. This requires explicit extension to
6 total launches, a second final integration wave, and additional elapsed time.
No budget reset, implicit extension, or extra reviewer has occurred.
