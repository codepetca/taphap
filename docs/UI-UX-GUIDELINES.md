# TapHap UI and interaction standard

TapHap should feel calm, clear, lightweight, and immediate. The music and the
player's next action lead; the interface explains just enough to act confidently.
Musical personality is welcome without turning training into a dashboard.
“Svelte” means responsiveness and restraint here, not the Svelte framework.

This is the canonical presentation contract, adapted from OcuOtter's mature
UI standard at `20be468d0048b728334d0127ccc89c9a7d2ceb8e` on 2026-09-13.
These are TapHap decisions informed by Apple HIG, not rigid Apple mandates.
OcuOtter's web framework, motion constants, clinic workflows, and superseded
blanket hiding/spacing/animation rules do not transfer to native SwiftUI.

[Product direction](product-brief.md) controls behavior and scoring;
[roadmap](../ROADMAP.md) and current coordination control scope and acceptance.
This standard does not change data, timing, assistance, lifecycle, or comparison
semantics, authorize a redesign outside the current task, or open Phase 4/release
work. Existing screens are candidates, not automatically accepted references.
See the [current flow assessment](phase-3-design-gaps.md).

## How to apply it

**MUST** is a requirement. **DEFAULT** is a preferred pattern; document a specific
exception and its reason in the PR. Routine adherence within an authorized UI
task needs no extra approval. Preserve behavior; bring unresolved product changes
back with a concrete example. The current documentation pass assesses gaps only.

Before changing a screen, identify its task, essential context, outcome, next
action, and relevant failure states. Reuse native controls and existing patterns.
Do not add a component framework or a new navigation layer without a concrete
need. Keep design guidance here and implementation evidence in the phase record.

## Hierarchy, copy, and honest state

- MUST keep the current song, input mode, session/step, and relevant outcome
  understandable at the point of action. Preserve selections when opening details
  and returning. Context need not be repeated in every card.
- DEFAULT to one visually dominant next action per task region. Use an action
  label that describes what happens: Start baseline, Continue session, Save again.
  Keep secondary navigation available without competing for attention.
- MUST distinguish an individual attempt from a saved baseline, completed daily
  session, compatible checkpoint comparison, and separate transfer reference.
  Unsaved, incomplete, invalid, assisted, and incompatible states cannot imply
  earned progress or improvement. Show the consequence and next recovery action
  beside a relevant failure; do not bury it in details or rely on color alone.
- DEFAULT to one plain-language outcome, a compact supporting measure or
  comparison, then the next action. Keep optional definitions, reward thresholds,
  and historical context in one small, labelled detail layer for that region.
  Do not hide decision-critical qualification to make a result look better.
- MUST explain unfamiliar terms when needed: baseline is the starting reference;
  checkpoint repeats that challenge; transfer tries a different song. Distinguish
  the opening rhythm within one song from the multi-trial training baseline.
  A smaller landing error is a narrower claim than better overall musicianship.
- MUST keep developer notes, engine versions, diagnostic traces, and test
  instructions out of normal play. Use minimal end-user copy; no permanent
  explanation of every correct implementation behavior. Synthetic previews must
  remain clearly labelled wherever their invented results could be mistaken for
  real improvement. Relevant assistance restrictions and save failures stay visible.
- DEFAULT to progressive disclosure of infrequent options, not an arbitrary
  percentage of hidden content. Do not replace removed developer copy with help
  icons. Short definitions belong beside the term or in the region's detail layer.

## Native presentation and response

- DEFAULT to native navigation, Button, Picker, Toggle, DisclosureGroup, lists,
  and sheets according to the task. Use a sheet for a focused supporting task,
  not every transition; avoid nested sheets. Back/dismiss must restore useful
  context and must not silently lose an unfinished session or pending save.
- MUST preserve native control semantics, accessible labels, clear pressed and
  disabled states, and sensible focus after navigation or disclosure. Every
  essential action needs an accessible visible entry point; gestures may augment it.
- DEFAULT to system text styles, SF Symbols, semantic foreground/background/status
  colors, restrained weight, and spacing that groups related content. A small
  brand palette may provide warmth when it remains readable in supported appearances.
  Do not shrink essential text or impose huge padding to achieve a sparse layout.
- MUST provide at least 44 × 44 pt interactive targets, readable contrast, text
  or symbols alongside status colors, and Dynamic Type layouts without losing
  content or actions. Keep decorative symbols out of accessibility reading order.
  Full accessibility certification remains outside this Phase 3 scope.
- MUST respond immediately to touch and represent pending work honestly. Animation
  cannot delay input capture, audio scheduling, an error, or the next valid action.
  Prevent duplicate starts/saves using existing state contracts.
- DEFAULT to brief native transitions only where they explain continuity or
  feedback. MUST allow interruption/reversal to settle in the correct state and
  respect Reduce Motion. No universal entrance animation or copied spring constants.
- MUST preserve the silent-gap invariant: no autonomous beat/bar/pulse flashes,
  ticks, countdowns, repeating movement, or haptic cues. Continuous non-rhythmic
  progress and a small response to the player's own input are allowed. Do not
  substitute rhythmic haptics for reduced-motion feedback. Keep the input surface
  and Strum crossing target stable as phase text changes.

## Screen contracts

| Region | Essential visible content and action | Optional detail |
| --- | --- | --- |
| Today / training selection | Current mode; next available baseline, daily, checkpoint, or transfer task; short duration/step expectation; one start/resume action. Explain a genuine unavailable state and recovery. Free practice and history remain secondary. | How training advances; chapter rules; fixed UTC day convention where scheduling matters. |
| Preparation / active play | Before start: song/mode, required input pattern, session step, assistance state, Start. During play: stable large touch surface, concise phase instruction, non-rhythmic progress and End attempt. Do not crowd the instrument with scores or settings. | Brief input explanation before starting; never require opening help during the gap. |
| Result | One clear attempt outcome, landing meaning when measurable, compact earned reward, and Continue/retry. On a completed checkpoint, distinguish the session comparison from this attempt; keep compatibility limitations visible. Failed save makes Save again the recovery priority. | Consistency and drift explanation, reward thresholds, comparison conditions; no stacked explanatory essays. |
| Session summary / history | Session kind, date, completion state and compact meaningful result; next available action on the current summary. Keep benchmark and transfer references distinct. Past entries describe that past session, not repeated instructions to return tomorrow. | Per-session measures and compatible comparison explanation; preserve access to older records and all existing history. |

## Verification

For a future UI implementation change, exercise the affected flow in the native
app at normal and maximum Dynamic Type, supported light/dark appearance, and
Reduce Motion as relevant. Inspect actual screenshots and interactions: next
action is easy to find; optional details preserve context; warnings/recovery
remain visible; rapid taps and interrupted transitions do not duplicate actions.
Check accessibility labels/order/focus and touch targets; an automated audit alone
is not assistive-use acceptance. Preserve the silent-gap and timing tests when
changing active play. Do not claim audio/touch behavior from static images.

Record the rule, screen/state, evidence, impact, correction, and disposition in
the existing PR/phase record. Reuse valid checks for unchanged code. This
**documentation-only pass** requires whitespace and local-link checks, not new
app tests, new phone automation, or another reviewer launch. Human first-use and
checkpoint understanding remain unobserved until actually assessed; visual
restraint is not evidence of comprehension or longitudinal improvement.

## Sources

Official Apple references verified 2026-09-13 (including their documentation
JSON content): [design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
for clarity and familiarity; [buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
for recognizable actions and targets; [disclosure controls](https://developer.apple.com/design/human-interface-guidelines/disclosure-controls)
for relevant detail; [motion](https://developer.apple.com/design/human-interface-guidelines/motion)
for purposeful feedback; [accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
for adaptable, perceivable interaction. Native guidance informs this contract;
TapHap's no-cue gameplay constraint still controls feedback during silence.
