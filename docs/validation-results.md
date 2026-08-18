# Phase 0 validation results

Status: **gate overridden by owner decision — Phase 1 unblocked, evidence still outstanding**

Decision: **`GO`, recorded 2026-08-17**

The original rule was that Kindling should not proceed to native app engineering until an explicit `GO`, `REDIRECT`, or `STOP` was recorded here and supported by the evidence below. That decision has now been made on owner judgement rather than on collected evidence. The metrics, interviews, and usability sessions below remain genuinely pending and are **not** retroactively treated as satisfied — see the decision record at the end of this document for what that costs.

## Hypothesis

People who struggle to initiate a known task will choose a dedicated, account-free rescue experience over opening an existing general-purpose breakdown or planning tool.

## Gate metrics

| Metric | Definition | Result | Notes |
|---|---|---:|---|
| Visitor → waitlist | Confirmed waitlist signups / unique landing visitors | Pending | Exclude team/internal traffic where possible |
| Prototype completion | Unique prototype sessions reaching `onboarding_completed` / sessions firing `onboarding_started` | Pending | Success screen must be reached |
| Sample-chip usage | Sessions firing `sample_task_used` / sessions reaching task entry | Pending | Leading indicator for blank-page freeze |
| First-session start | Sessions firing `first_session_started` / sessions firing `first_step_shown` | Pending | Reveals step-to-action friction |
| Median time to session | Median time from `onboarding_started` to `first_session_started` | Pending | Report alongside completion, not alone |

No universal threshold is pre-declared as proof. Interpret conversion alongside traffic source, interview language, and observed usability friction. Record the traffic sources and sample sizes so a high percentage from a tiny friendly audience is not mistaken for broad demand.

## Interviews (target: 5–8)

Ask for recent behavior before opinions:

1. Tell me about the last time you knew what to do but could not start.
2. What did you do next, including anything you opened on your phone?
3. What have you tried before? What made you stop using it?
4. How do you describe that stuck moment in your own words?
5. If something helped, what was the smallest useful part?

Do not pitch Kindling until the behavioral questions are complete. Store anonymized themes here; do not put task titles, health details, or participant contact information in this repository.

| Interview | Existing behavior | Language/theme | Dedicated-app signal | Notes |
|---|---|---|---|---|
| 1 | Pending | Pending | Pending | |
| 2 | Pending | Pending | Pending | |
| 3 | Pending | Pending | Pending | |
| 4 | Pending | Pending | Pending | |
| 5 | Pending | Pending | Pending | |

## Prototype usability (target: 3–5)

Observe task-entry hesitation, sample-chip use, whether the suggested step feels smaller than the task, and whether the three outcomes feel equally acceptable.

| Session | Completed | Sample used | Time to session | Main friction | Notes |
|---|:---:|:---:|---:|---|---|
| 1 | Pending | Pending | Pending | Pending | |
| 2 | Pending | Pending | Pending | Pending | |
| 3 | Pending | Pending | Pending | Pending | |

## Step-engine input set

The prototype includes 20 synthetic test cases to exercise the initial rules. Replace or supplement them with anonymized wording collected in interviews before porting the engine to Swift. Never commit an interviewee's identifiable or sensitive task verbatim.

## Decision record

- **Decision date:** 2026-08-17
- **Decision:** `GO` — proceed to Phase 1 and scaffold `ios/`
- **Basis:** owner judgement. The validation gate was deliberately overridden, not satisfied.
- **Evidence summary:** none of the five gate metrics has a result. No interviews conducted, no usability sessions run, no landing traffic collected. The Phase 0 engineering assets (tokens, prototype, landing page) are complete, but the live validation they exist to enable has not been executed.
- **Weakest signal / uncertainty:** the core assumption in the hypothesis above is entirely untested. Specifically unmeasured: whether anyone prefers a dedicated rescue app over a tool already at hand, and the sample-chip usage rate that `§14` names as the leading indicator for blank-page freeze — the biggest identified drop-off risk.
- **What this means going forward:** Phase 0 is not cancelled, it is deferred. The landing page and prototype remain deployable and the playbook in `docs/phase-0-validation-playbook.md` remains valid. Running that validation after v1 is built recovers the evidence but loses the option value the gate existed to protect — a `REDIRECT` finding (widget-only, an iOS Shortcut, a web app) would arrive after the native work rather than instead of it.
- **If `REDIRECT`:** not applicable; no redirect was chosen.
- **Owner:** aftaab
