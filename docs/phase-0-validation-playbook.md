# Kindling Phase 0 validation playbook

Updated: 2026-08-11

## Objective

Answer one question before native development:

> When someone with ADHD is stuck on a known task, is a dedicated, account-free rescue app meaningfully more useful than the tools already within reach?

This round is not intended to prove pricing, AI quality, retention, or clinical benefit. It tests the product format and the core rescue loop.

## Recommended platform stack

| Need | Recommended platform | Why | Alternative |
|---|---|---|---|
| Static hosting | [Vercel](https://vercel.com/docs/frameworks/frontend/astro) | Zero-configuration static Astro deployment, Git previews, and custom domains | Cloudflare Pages |
| Aggregate visitors | [Vercel Web Analytics](https://vercel.com/docs/analytics) | Anonymous, cookie-free visitor and page-view counts integrated with the deployment | Plausible if plan-independent custom events are later required |
| Email waitlist | [Formspark](https://documentation.formspark.io/setup/) | Built for static HTML forms; stores submissions and sends notifications without sender vetting | Formspree |
| Screener and consent | [Tally](https://tally.so/help/create-a-form) | Quick forms, conditional logic, hidden participant codes, and response export | Google Forms |
| Scheduling | [Cal.com](https://cal.com/) | Shareable availability and time-zone handling | Calendly or manual scheduling |
| Remote sessions | Google Meet or Zoom | Familiar screen sharing; no special research software needed for this sample size | Jitsi Meet |
| Paid recruitment | [User Interviews](https://www.userinterviews.com/) | Useful when community and personal-network recruitment is too slow | Prolific or Respondent, after checking audience availability |
| Analysis | Repository docs plus `scripts/analyze-events.mjs` | Keeps the gate evidence beside the product plan without storing task text | A private spreadsheet with the same fields |

Do **not** add session-replay software such as Clarity, Hotjar, or FullStory during this round. Task titles may reveal health, financial, employment, or relationship information. Aggregate events are enough for the gate.

Use Vercel Web Analytics for the visitor denominator and successful Formspark submissions for waitlist signups. Use the prototype's exported event buffer for recruited usability sessions. Vercel custom-event availability depends on the selected plan; if public prototype-completion analytics becomes necessary without that feature, build a tiny allowlisted event endpoint rather than installing general-purpose replay analytics.

## Suggested seven-day sequence

| Day | Work | Exit condition |
|---|---|---|
| 1 | Configure Formspark, Vercel, analytics, and the subdomain | Landing page, `/try/`, legal pages, and form work in production |
| 2 | Create screener, information sheet, consent form, scheduling page, and participant codes | One end-to-end dry run completed |
| 3 | Recruit and run one pilot interview plus one pilot usability session | Scripts adjusted; no privacy or prototype blockers |
| 4–6 | Run 5–8 interviews and 3–5 usability sessions | Notes and event exports complete |
| 7 | Synthesize evidence and record `GO`, `REDIRECT`, or `STOP` | `docs/validation-results.md` contains the decision |

Seven days is a working cadence, not a deadline. Recruitment quality matters more than completing the round in one calendar week.

## Step 1 — Deploy the validation site

### Formspark

- [ ] Create a Formspark account and a form named `Kindling waitlist`.
- [ ] Copy the action URL from the form's **Setup** section. It has the form:

  ```text
  https://submit-form.com/YOUR-FORM-ID
  ```

- [ ] Enable notification emails in the form's settings.
- [ ] Keep automatic spam filtering enabled. The landing form also includes Formspark's `_honeypot` field.
- [ ] Keep the existing `kindling-phase-0` tag so validation signups remain distinguishable.
- [ ] Formspark is the collection layer, not a marketing newsletter. Export only consenting waitlist addresses to a compliant mailing tool if product updates are sent later.

### Vercel

- [ ] Push the repository to GitHub, GitLab, or Bitbucket.
- [ ] In Vercel, select **Add New → Project** and import the repository.
- [ ] Configure:

  | Setting | Value |
  |---|---|
  | Root directory | `landing` |
  | Framework preset | Astro |
  | Build command | `npm run build` |
  | Output directory | `dist` |
  | Production branch | the repository's primary branch |

- [ ] Under **Settings → Build and Deployment → Root Directory**, keep **Include source files outside of the Root Directory in the Build Step** enabled. The build copies `prototype/` and `design/tokens.css` into the landing output.
- [ ] Add production environment variables:

  ```text
  PUBLIC_WAITLIST_FORM_ACTION=https://submit-form.com/YOUR-FORM-ID
  SITE_URL=https://kindling.maskedsyntax.com
  ```

- [ ] Leave `PUBLIC_ANALYTICS_ENDPOINT` empty unless a reviewed, privacy-safe custom collector exists.
- [ ] Deploy and verify the generated `vercel.app` preview URL.
- [ ] Add `kindling.maskedsyntax.com` under **Project Settings → Domains** and apply the DNS record Vercel provides.
- [ ] Open the project's **Analytics** tab and enable Web Analytics. The Astro layout already includes `@vercel/analytics`.
- [ ] Redeploy after enabling analytics and verify a page view appears in the Analytics dashboard.

### Production smoke test

- [ ] Open `/`, `/try/`, `/privacy/`, and `/terms/` on a phone using mobile data.
- [ ] Submit an address you control.
- [ ] Confirm it appears in Formspark with the Phase 0 tag and that the notification email arrives.
- [ ] Run the prototype once with `?dev=1` and once with the natural two-minute timer.
- [ ] Test light mode, dark mode, and reduced motion.
- [ ] Confirm the browser console has no errors.
- [ ] Confirm the typed task does not appear in the copied event JSON.
- [ ] Mark internal visits so they can be excluded from the evidence summary.

## Step 2 — Define the participants

Recruit adults who:

- are 18 or older;
- identify as having ADHD or strongly relate to ADHD-style task-initiation difficulty;
- experience a known-but-cannot-start moment at least occasionally;
- currently use or previously abandoned a to-do, focus, planning, or breakdown tool;
- use a smartphone regularly.

Do not request proof of diagnosis, medication information, treatment history, or medical records. This is product research, not clinical research.

Aim for variation in:

- device mix, with strong iOS representation because Kindling is an iOS-only app and non-iOS participants can validate the flow but not the eventual install;
- people who already use timers and people who do not;
- self-identified and formally diagnosed participants;
- age, gender, work/study context, and accessibility needs.

The interview and usability groups may overlap, but at least two usability participants should not have heard the product pitch in an earlier interview.

## Step 3 — Recruit ethically

Use channels in this order:

1. Existing network and waitlist, clearly saying this is research rather than treatment.
2. ADHD communities only after reading their rules or getting moderator permission. Disclose that you are building Kindling and do not repeatedly post.
3. ADHD coaches, occupational therapists, or community organizers who are willing to share the invitation without endorsing the product.
4. A paid research panel if the first three routes produce a biased or insufficient sample.

Offer a fair incentive based on the participant's location, the session length, and the recruitment platform's guidance. Pay even when the participant struggles with or dislikes the prototype; critical feedback is the work being requested.

### Recruitment message

```text
Research participants wanted: starting a task when you feel stuck

I am researching how adults with ADHD or ADHD-like task-initiation difficulty
handle the moment when they know what to do but cannot begin.

This is a 30–40 minute product-research conversation. It is not medical research,
diagnosis, or treatment. You may skip any question, use a non-sensitive example,
and stop at any time. Participants receive [incentive].

The session may include trying a small browser prototype. You do not need to
install anything or share proof of diagnosis.

[screener link]
```

## Step 4 — Build the screener and consent flow

Create two separate Tally forms:

1. **Recruitment form:** contact details, screening answers, availability, accessibility needs.
2. **Research response form:** participant code, prototype-event JSON, and follow-up answers—no name or email.

Keep the participant-code lookup outside the repository. Delete contact and screening data when incentives and any agreed follow-up are complete.

### Screener questions

1. Are you 18 or older? (`Yes` required.)
2. In the past month, how often have you known what task to do but felt unable to begin?
3. What do you usually do in that moment? (Optional, short text.)
4. Which tools have you tried? (Timer, to-do app, planner, AI breakdown tool, body doubling, none, other.)
5. Which phone platform do you primarily use?
6. Are you comfortable testing a browser prototype using a non-sensitive task example?
7. Do you need any accessibility accommodation for a remote session?
8. Email and availability.

Do not screen only for people who already like productivity apps. The abandoned-tool group is central to the product hypothesis.

### Information and consent checklist

Before the session, state:

- [ ] the purpose of the research;
- [ ] what will happen and how long it will take;
- [ ] what data will be collected;
- [ ] where it will be stored and when it will be deleted;
- [ ] that participation is voluntary and can stop at any time;
- [ ] whether anyone else is observing;
- [ ] whether recording is requested;
- [ ] that recording is optional and has a separate consent choice;
- [ ] how to withdraw data after the session;
- [ ] that Kindling is not diagnosis, treatment, or crisis support.

For this round, prefer notes over recordings. If a participant consents to recording, ask them to use the supplied sample task or another non-sensitive example while screen sharing.

## Step 5 — Run the interviews first

Run 5–8 interviews, approximately 30 minutes each. Ask about a recent real event before showing Kindling.

### Interview guide

**Opening — 2 minutes**

```text
We are testing an idea, not you. There are no right answers. I am interested in
what you actually do, including workarounds that seem messy. Please avoid sharing
anything you consider sensitive, and stop me whenever you want.
```

**Recent behavior — 12 minutes**

1. Tell me about the last time you knew what you needed to do but could not start.
2. What happened immediately before you noticed you were stuck?
3. What did you do next, including anything you opened on your phone?
4. How long did the stuck period last?
5. What eventually changed, if anything?

**Existing alternatives — 8 minutes**

1. Which tools or tactics have you tried in this situation?
2. What part helped?
3. Where did the tool lose you or ask for too much?
4. Have you used a timer or task-breakdown tool? What happened after it gave you the list or started the timer?

**Concept reaction — last 6 minutes only**

Read this neutral description:

```text
Kindling asks for the task, suggests one small first action, and stays with that
action for a two-minute session. It does not plan the rest of the day.
```

Then ask:

1. What feels useful, unnecessary, or missing?
2. In the situation you described earlier, where would this have broken down?
3. Would you expect this to be an app, a web page, a widget, or something else? Why?
4. What would make you avoid opening it?

Do not ask “Would you buy this?” or lead with features. Hypothetical enthusiasm is weak evidence compared with the behavior described earlier.

## Step 6 — Run prototype usability sessions

Start with one moderated pilot. After fixing any blocking issue, run 3–5 sessions. Two can be moderated for observation; the remainder can be unmoderated through Tally.

### Moderated task

```text
Think of a real but non-sensitive task you have recently avoided. If none feels
comfortable, use the sample offered by the prototype. Starting from this page,
use Kindling as you naturally would. Please say what you are expecting, but I
will mostly stay quiet.
```

Do not point out the sample chip, explain the step engine, or tell the participant which outcome to choose.

Observe:

- time before entering a task;
- whether the sample chip is used;
- whether the first step feels smaller and concrete;
- regeneration use and reason;
- whether the participant starts the session;
- whether Stop is easy to find;
- emotional reaction to the three equal outcomes;
- response to the notification question;
- whether the person describes a situation in which they would intentionally reopen Kindling.

### Follow-up questions

1. What did you expect after entering the task?
2. Was the suggested step smaller than the task? What would make it better?
3. What, if anything, did the timer add?
4. Which part was the real help: choosing a step, the timer, the no-shame ending, or something else?
5. Where would you want to access this next time: installed app, widget, shortcut, browser, or nowhere?
6. What would stop you from using it when you are actually stuck?

At the end, use **Research mode → Copy events** and paste the JSON into the research response form. The payload must not contain the task or suggested-step text.

### Unmoderated instructions

1. Open the prototype link in a new tab.
2. Use a non-sensitive task or the sample.
3. Complete the flow without refreshing.
4. Copy the Research mode events.
5. Return to the Tally response form and paste the JSON.
6. Answer the six follow-up questions.

Use a participant code in the Tally URL or hidden field. Do not pass email addresses in URL parameters.

## Step 7 — Measure without overclaiming

### Landing page

```text
visitor_to_waitlist = successful Formspark waitlist submissions / unique Vercel visitors
```

Remove obvious spam and duplicate addresses before calculating the numerator. Record the date range, traffic sources, total visitors, and the number of internal visits removed.

Aim for roughly 150 qualified visitors from at least two sources before treating the conversion rate as directional evidence. Do not run headline A/B tests at this sample size.

Internal interpretation bands—not external benchmarks:

| Qualified visitor → confirmed waitlist | Interpretation |
|---:|---|
| 10% or higher | Encouraging; inspect traffic quality and interview evidence |
| 5–10% | Mixed; positioning or audience may need refinement |
| Below 5% | Weak unless interviews reveal a clear acquisition mismatch |

These bands prevent moving the goalposts after seeing results. They are not universal industry standards and should never override strong contradictory qualitative evidence.

### Prototype

Save each copied export outside the repository using participant codes, then analyze an export with:

```sh
node scripts/analyze-events.mjs path/to/events.json
```

Copy only aggregate results into `docs/validation-results.md`.

Report counts as well as percentages because 3–5 sessions are too small for percentage precision:

- completed onboarding;
- used sample chip;
- reached first step;
- regenerated the step;
- started the timer;
- selected each outcome;
- median time from onboarding start to session start;
- stated installed-app, widget, shortcut, web, or no-use preference.

## Step 8 — Synthesize the interviews

Immediately after each session, record:

| Field | Allowed content |
|---|---|
| Participant code | Random code only |
| Existing behavior | Tool/tactic category, not sensitive task details |
| Exact language | Short anonymized phrase with identifying details removed |
| Main initiation barrier | Vague, boring, feared, logistical, other |
| Useful part | First step, timer, presence, ending, none |
| Preferred surface | App, widget, shortcut, web, other, none |
| Dedicated-app signal | Strong, mixed, weak |
| Main objection | Short anonymized theme |

After all sessions, group repeated observations. A theme should be tied to participant codes so a memorable quote from one person does not accidentally become “everyone said.”

## Step 9 — Make the gate decision

Score five dimensions:

| Dimension | Green | Yellow | Red |
|---|---|---|---|
| Problem recurrence | Repeated, specific stuck moments across participants | Real but infrequent or narrow | Mostly hypothetical |
| First-step value | Participants act or describe materially lower friction | Helpful only for some task types | Generic, annoying, or adds decisions |
| Session value | Timer/presence helps move from suggestion to action | Timer is neutral | Timer makes the flow slower or stressful |
| Dedicated surface | Participants name when/why they would reopen an installed surface | Surface preference is mixed | Browser/Shortcut is clearly sufficient or another install is rejected |
| End-to-end usability | Most complete without moderator rescue | Repeated fixable friction | Core flow cannot be completed or trusted |

### `GO`

Choose `GO` when there are no red dimensions and at least three dimensions are green, including **Dedicated surface**. Proceed to Phase 1 with the strongest observed surface and wording.

### `REDIRECT`

Choose `REDIRECT` when the underlying problem and first-step value are green, but the dedicated-app signal is yellow or red. Test the preferred format next: widget, Shortcut, or web app. Update `IMPLEMENTATION.md` before engineering.

### `STOP`

Choose `STOP` when participants do not reveal a recurring problem, the flow adds more effort than their current workaround, or interest exists only after persuasive pitching.

Do not convert a red dedicated-app signal into `GO` because native development is exciting. That is the exact risk Phase 0 exists to catch.

## Step 10 — Decide where on-device AI belongs

Do not mention AI during the initial interviews unless a participant brings it up. The gate tests the rescue experience, not implementation novelty.

After a `GO`, compare the template engine with Apple Foundation Models on 20–40 anonymized task phrases. Blind-rate each suggestion for:

- one action rather than a list;
- immediate executability;
- specificity without inventing facts;
- calm, non-judgmental language;
- safety;
- latency;
- availability and fallback behavior.

On-device AI should be an optional suggestion provider behind the same interface as the template engine. Unsupported devices, disabled system intelligence, model errors, slow responses, or rejected outputs must fall back to templates without blocking the rescue flow.

## Final checklist

- [ ] Production site and waitlist work.
- [ ] Privacy page names active third-party processors.
- [ ] Analytics and internal-traffic rules are documented.
- [ ] Screener and consent flows are tested.
- [ ] 5–8 interviews are complete.
- [ ] 3–5 usability sessions are complete.
- [ ] Raw research data is stored outside Git.
- [ ] Aggregate metrics and anonymized themes are in `docs/validation-results.md`.
- [ ] Decision is explicitly `GO`, `REDIRECT`, or `STOP`.
- [ ] If `GO`, Phase 1 scope reflects the findings.
- [ ] If `REDIRECT`, `IMPLEMENTATION.md` is revised before code starts.

## Research-practice references

- [Plan user research](https://www.gov.uk/service-manual/user-research/plan-user-research-for-your-service)
- [Plan a research round](https://www.gov.uk/service-manual/user-research/plan-round-of-user-research)
- [Find participants and protect their privacy](https://www.gov.uk/service-manual/user-research/find-user-research-participants)
- [Manage research data and participant privacy](https://www.gov.uk/service-manual/user-research/managing-user-research-data-participant-privacy)
- [Get informed consent](https://www.gov.uk/service-manual/user-research/getting-users-consent-for-research)
