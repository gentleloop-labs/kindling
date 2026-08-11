# Phase 0 validation results

Status: **collecting evidence — Phase 1 is gated**

Decision: **not made**

Kindling should not proceed to native app engineering until the owner records an explicit `GO`, `REDIRECT`, or `STOP` decision here, supported by the evidence below.

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

The prototype includes 20 synthetic test cases to exercise the initial rules. Replace or supplement them with anonymized wording collected in interviews before porting the engine to Kotlin. Never commit an interviewee's identifiable or sensitive task verbatim.

## Decision record

- Decision date: Pending
- Decision: Pending (`GO`, `REDIRECT`, or `STOP`)
- Evidence summary: Pending
- Weakest signal / uncertainty: Pending
- If `REDIRECT`, chosen direction: Pending (widget-only, Shortcut, web app, or another tested direction)
- Owner: Pending
