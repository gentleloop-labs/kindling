# Kindling
## Complete Product Plan — ADHD Task-Initiation App

*Consolidated from a multi-stage planning process, current as of August 3, 2026. Competitor and market research was conducted via live web search on August 2-3, 2026 and is dated accordingly; treat anything time-sensitive (pricing, store fees, tooling maturity) as needing a re-check if this document is read much later.*

---

## 1. Executive summary

Kindling is a task-initiation app for people with ADHD — not a planner, not a task manager, but a single-purpose tool for the moment someone knows what they need to do and can't start. The core loop: name the avoided task, get a small first step, run a short timer, done — with no streaks, no failure states, and no account required.

The idea is sound but the market isn't empty: **BrightMind**, an AI voice companion, already occupies nearly identical positioning language ("I can't start" paralysis → tiny doable steps). Goblin Tools owns free task breakdown; Llama Life owns single-task timeboxing; Tiimo owns visual day-planning. The real, defensible gap is narrower than the original brief assumed: **a local-first, account-free, single-session rescue tool** — not a planner, not a breakdown-and-abandon tool, not a cloud-backed AI companion.

Recommendation: **build it, narrower than first scoped, and validate the core assumption (that people will open a dedicated app rather than reach for an existing free tool) before over-investing** — see §16.

---

## 2. The problem

**Reasonably well-evidenced:** ADHD is fundamentally an executive-function disorder, and task initiation is a distinct, commonly-reported deficit separate from sustaining attention. Time blindness makes vague tasks feel infinite. The "wall of awful" / activation-energy framing is a widely used descriptive model in the ADHD community, though not a measured clinical construct. Body doubling has consistent anecdotal and some early empirical support specifically for initiation, not just sustained focus. Shame from repeated failed starts compounds avoidance over time.

**Product hypotheses, not established facts — flagged as things to validate, not build on blindly:**
- That a *dedicated, single-purpose app* changes initiation behavior more than a lightweight tool already at hand (a widget, a Shortcut, Goblin Tools in a browser tab) — the single biggest unproven assumption in the whole plan.
- That asking "why can't you start?" before offering a first step improves completion versus just offering the step immediately.
- That a mascot-led companion outperforms a text-only interaction for this specific use case.

**Segmentation reality:** a boring task, a feared task, and a vague/undefined task fail to start for different reasons and may need different first-step strategies — a real design fork, addressed by the optional obstacle-tag enhancement path in §11.

---

## 3. Competitor landscape (grounded, current as of Aug 2-3, 2026)

| Product | What it is | Initiation approach | Price | Account | Gap it leaves |
|---|---|---|---|---|---|
| **BrightMind** | AI voice/text companion, iOS + Android | Voice/text capture, AI breaks tasks into tiny steps, explicitly targets "I can't start" | Freemium subscription | Optional but pushed | Companion/inbox, not a session-holder; cloud-backed by default; expanding into calendar/integrations rather than staying narrow |
| **Goblin Tools (Magic ToDo)** | Free web tool + cheap one-time mobile wrapper | AI breakdown with adjustable "spiciness" | Free (web), ~$3-4 one-time (app) | None | "Hands you the list and walks away" — no session, no follow-through, by its own reviewers' admission |
| **Llama Life** | Timeboxing to-do + timer | Countdown per task, auto-advance, AI breakdown if stuck | $6/mo or $39/yr, no free tier | Not required | Assumes you can already name and commit to a task |
| **Tiimo** | Visual daily planner for ADHD/autism | Circular visual timeline | $8-10/mo (~$54-80/yr) | Free tier mobile-only | Plans the day, not a single stuck moment; "no project or task-manager depth" per its own users |
| **Finch** | Gamified self-care pet | Indirect, not task-focused | Free tier generous; Plus ~$40-70/yr | Yes | Explicitly not a task/productivity tool |
| **Focusmate / Flow Club / FLOWN** | Live body-doubling | Presence-based | $0-40/mo | Yes | Needs scheduling + camera/mic — the opposite of instant rescue |
| **Habitica** | RPG-gamified habit tracker | Points, streaks, party accountability | Free / small sub | Yes | The exact streak/punishment mechanic this brief rules out |

**Recurring review themes:** praise clusters around not being asked to plan a whole day, visual/spoken interaction over typed lists, cheap or free entry points. Complaints cluster around subscription fatigue (several products in the $50-80/yr range), tools that hand over a list and disengage, and required accounts for something meant to be used in a low-executive-function moment.

---

## 4. Market gap & positioning

**The open gap:** not task breakdown (Goblin Tools), not an AI companion (BrightMind), not day-planning (Tiimo) — **a local-first, account-free, single-session rescue tool that starts the moment paralysis hits and stays with you through one short session.**

**Positioning statement:** *Kindling doesn't plan your day or manage your tasks — it's the app you open in the sixty seconds before you'd otherwise give up on starting.*

**Why competitors don't already own this:** Goblin Tools disengages right when starting begins; BrightMind is cloud/voice-forward and expanding outward; timeboxing tools assume a task is already named and committed to; visual planners operate at day-scale, not stuck-moment scale.

**Why it's realistic for a solo developer:** the wedge is narrow by design — one screen that matters, one session type, no account system, no mandatory server infrastructure.

**What could make it fail:** if the rescue flow isn't meaningfully faster/calmer than free alternatives, there's no reason to install a new app. This is a low-daily-open tool by nature, which pressures both retention metrics and subscription pricing psychology. Mediocre AI step quality would make it a worse Goblin Tools with extra steps.

**Product principles against feature creep:**
1. A feature that requires planning ahead doesn't belong in v1.
2. If a screen doesn't get someone into a first step faster, cut it.
3. Add a calendar/project view only if data proves the rescue flow alone can't retain people — don't build it defensively.
4. Every AI feature ships with a working non-AI fallback first.
5. No feature can render as a failure state, even by accident.

---

## 5. Primary audience

**Primary persona:** a diagnosed or self-identified adult with ADHD, already using or having abandoned a to-do app, who specifically struggles with *starting*, not remembering. **Trigger:** staring at an avoided task, guilt-and-freeze, phone in hand, about to doomscroll instead. **Why they've abandoned similar apps:** too much setup, being asked to plan a whole day, shame-inducing streaks, a tool that broke the task down and offered nothing further.

Secondary, deliberately not the v1 target: students with a specific assignment, non-ADHD users with situational task paralysis.

---

## 6. Core user experience

Onboarding *is* the first real rescue — no demo, no sample walkthrough (see §11). The core loop:

1. Open app → text field, cursor active, placeholder *"what are you avoiding?"*
2. Type or speak (voice optional, never required)
3. Immediate smallest-first-action suggestion — template-based by default, no intermediate question screen
4. One tap starts a short timer (2 or 5 min, last choice remembered)
5. At timer end: **"keep going" / "that's enough for now" / "I got distracted"** — no visual hierarchy suggesting a "right" answer
6. Session ends; task saved exactly where it was left, ready to resume with nothing to re-enter

The optional "why can't you start?" obstacle picker lives behind a single tap, never a mandatory gate — resolving the tension between the original brief's "minimal decisions" constraint and its "ask why" idea.

---

## 7. MVP feature set

**In v1:** the rescue flow above; deterministic (template) first-step suggestion, always available offline; 2/5-minute timer with gentle audio/haptic; resume-in-progress for one active task; local-first storage, no account.

**Deferred, not cut:** widgets beyond the Live Activity, Apple Watch, multiple concurrent tasks (paid, v1.1+), body-doubling presence, task-manager integrations, session history/reflection, AI-assisted steps (v1.1, once the template baseline has proven itself), a scheduled-reminder system.

**Excluded unless validation changes this:** calendar view, day planning, project management, streak gamification, mandatory accounts, mandatory voice input.

---

## 8. Naming

**Final name: Kindling.** Pronounced **KIND-ling** (/ˈkaɪnd.lɪŋ/) — like "kindle" plus "-ing," stress on the first syllable.

Ruled out along the way: **Foothold** (an existing App Store app, "Foothold: Interview Prep," uses near-identical positioning language, plus an unrelated healthcare EHR company of the same name); **Afresh** ($233M-funded grocery AI company — real trademark/SEO conflict); **Traction** (heavily crowded across B2B software since 1996). Runner-up candidates that checked out clean: Doable, Outset, Bramble, Groundwork.

*(Domain checks were originally planned but the app will be hosted on a subdomain of maskedsyntax.com, so a dedicated-domain conflict search wasn't needed — the naming risk that mattered was App Store/trademark conflict, which was checked for the top candidates above.)*

**Brand story:** the app isn't trying to set anything ablaze — it just needs the smallest possible spark, because that's all a fire ever needs to start. Tagline direction: *"You don't need a fire. You need a spark."* App Store subtitle: *"Task starter for ADHD brains."*

---

## 9. Mascot: the Ember

Five concepts were developed (Ember, Snail, Sprout, Pebble, Bramble); **the Ember** was selected as the pairing with Kindling.

- **What it is:** a small, round, glowing coal — not a flame (harder to keep simple at icon size, skews "energy drink"). Rounded form, two dot eyes, state conveyed through glow intensity and expression rather than added detail.
- **States:** dim/grey (resting) → small warm glow (ready) → brighter pulsing glow (focus session) → flicker (distracted) → soft warm bloom, no fireworks (celebration).
- **Why it works:** the shape is the simplest of the five to execute well at every required size — icon, widget, Live Activity, watch face — and "a small glow, given attention, grows" is the entire product thesis in one image.
- **Runner-up:** the Bramble (a small tangle that loosens as a session progresses, embodying the stuck feeling itself rather than a coach standing outside it) — more conceptually original, harder to render simply at small sizes. Worth a real prototype if you want something more distinctive later.

---

## 10. Technical architecture

**Kindling is an iOS app: Swift and SwiftUI, one Xcode project, no cross-platform layer.** Minimum deployment target iOS 17. Android is not planned and would only be reconsidered against real post-launch demand, as a separate native build.

*(This section replaces an earlier Kotlin Multiplatform recommendation. That recommendation existed to share logic between two native UIs; with one platform, the shared-module machinery is cost with no benefit. The reasoning that ruled out Flutter still stands and now applies more strongly, so it's kept below.)*

**Why native rather than any cross-platform framework:** widgets, Live Activities, and the Dynamic Island — core to this app's experience, not optional polish — cannot be rendered by Flutter's engine at all. Even with the community `live_activities` plugin, you still hand-write a native Swift Widget Extension and bridge to it. So "simple app, few screens → Flutter" (a sound general rule) doesn't save Swift work here; it adds a bridge layer on top of Swift you'd write anyway. With Android off the table, there is nothing on the other side of that trade at all.

**Structure:** the app target, a widget extension for the Live Activity (and the v1.1 home-screen widget), and a local Swift package holding the domain layer — data models, the template step engine, and the session state machine. The package is importable by both targets and testable without launching the app, which is the whole reason it exists.

**Persistence: SwiftData**, in an App Group container shared with the widget extension. See §11.

**Payments: decided at build time, not here.** The original choice of RevenueCat rested on cross-platform entitlement state — one check answering "is the multi-task tier unlocked" regardless of which store the purchase came from. That reason is gone. StoreKit 2 handles one non-consumable and two subscriptions directly, with no dependency and no fee on top of Apple's 15%. The counterargument is §18's assumption that RevenueCat's paywall experimentation tools would run the pricing and paywall-timing tests. `IMPLEMENTATION.md` Phase 5 carries the trade-off; the call is made before purchase code is written.

---

## 11. Data models & local storage

**Storage engine: SwiftData** — Apple-native, minimal code, integrates directly with SwiftUI, and its `VersionedSchema` / `SchemaMigrationPlan` types cover the additive migrations this schema will actually need. *(Supersedes an earlier Room KMP choice, which existed only to serve the abandoned cross-platform stack.)*

**Where the data lives:** a single local SQLite file in an **App Group container**, so the widget extension can read it — not the default app-sandbox path. Not synced to any server. Included in the OS's own device backup by default (still local-first — it only ever leaves the device inside the user's own backup), with a settings toggle that sets `isExcludedFromBackup` on the store file for anyone who wants that.

**Five entities, deliberately minimal** (described as tables below; they map one-to-one onto `@Model` types):

**`Task`** — `id`, `title`, `status` (active/stepped_away/done/discarded), `source` (typed/voice), `obstacle_tag` (nullable), `last_first_step_id` (nullable FK), `created_at`, `updated_at`. Index on `status`. **Sensitive** — task titles can incidentally reveal health/financial/relationship information; local-only by default.

**`FirstStep`** — `id`, `task_id` (FK), `text`, `generated_by` (template/ai/edited), `created_at`. Index on `task_id`. Sensitive, same reasoning as `Task`.

**`StarterSession`** — `id`, `task_id` (FK), `first_step_id` (FK), `duration_seconds`, `started_at`, `ended_at` (nullable), `outcome` (kept_going/stopped_enough/distracted, nullable while active). Indexes on `task_id`, `started_at`. The three-value `outcome` enum, with no "failed" state possible, is the no-shame principle enforced at the schema level, not just the UI.

**`UserPreference`** — simple `key`/`value` table, no schema needed for new settings later. Not sensitive.

**`AiRequestLog`** — `id`, `task_id` (nullable FK), `requested_at`, `provider` (on_device/api), `latency_ms`, `success`. **No prompt/response column, on purpose** — structurally impossible to leak task content through this table.

**Deliberately not in the schema:** `Reminder` (feature not built yet — don't pre-build the table), a persisted mascot state (fully derivable from `Task`/`StarterSession` at render time — persisting it would create a second source of truth that can drift), `SubscriptionEntitlement` (pricing model is decided now, but this can be added as its own low-risk migration whenever billing integration is actually built), a separate `Reflection`/`Interruption` table (`outcome = 'distracted'` already covers what v1 needs).

**Migration strategy:** a `VersionedSchema` per shipped schema plus a `SchemaMigrationPlan`, both established at v1 with nothing yet to migrate — the scaffolding is what makes later lightweight migrations free. Additive changes (new optional properties, new entities) migrate lightweight with no hand-written work. String-backed enums (`status`, `outcome`) don't need a schema migration to gain a new value, just an app-level validation update.

**Retention:** no automatic deletion by default. `done`/`discarded` tasks stay until the user clears them via an explicit settings action. `FirstStep`, `StarterSession`, and `AiRequestLog` cascade-delete with their parent `Task` — set the delete rules explicitly rather than relying on defaults.

**One naming note:** `Task` collides with Swift's concurrency type. Namespace it or rename it (`AvoidedTask`) before it spreads through the codebase.

---

## 12. AI strategy

Kept deliberately minimal for v1, per the standing "no AI without a working fallback" principle:

- **v1: template-based first-step generation only, no AI at all.** Deterministic, offline-capable, zero latency, zero per-request cost, zero privacy exposure. This also means the most vulnerable moment in the whole product — someone's very first attempt to use it, in onboarding — never depends on a network call or an AI provider being up.
- **v1.1: AI-assisted step generation as an opt-in layer on top of the proven template baseline**, not a replacement for it. Candidate approach: a single hosted API call per request (task text in, one suggested step out), since bundling an on-device model is disproportionate solo-dev effort for v1.1 — Apple's and Google's on-device foundation-model APIs (Apple Intelligence / Foundation Models framework, Gemini Nano) are worth revisiting as they mature, as a lower-latency, fully private alternative once they're a better fit than a server call.
- **Evaluation criteria applied to any future AI feature:** does it solve something the deterministic path genuinely can't (rather than just sounding more impressive); what's the added latency in the moment someone's already struggling to start; what leaves the device and under what disclosure; what happens when the AI call fails or is offline (must degrade to the template path, never to a dead end).
- **Not planned:** on-device obstacle-type detection, AI-generated encouragement copy, or any AI feature whose failure mode could plausibly generate bad advice in a moment of genuine distress — kept out on the same "no feature that could render as harm" principle as the rest of the product.

---

## 13. Design system

Warm, calm, a little worn-in — not a wellness-app purple gradient, not a corporate productivity dashboard. *(Color values below are a starting proposal for prototyping, not locked tokens — they need a real WCAG contrast-checking pass before shipping.)*

**Light:** background `#FAF6F1` (warm paper), surface `#F1EAE1`, text primary `#2B2420`, text secondary `#6B5F55`, accent (Ember) `#E8703A`, glow `#F2A65C`, celebration `#E8B84B` (warm gold, not green — avoids the generic "success" cliché).

**Dark:** background `#1C1815` (warm near-black, never pure black), surface `#262019`, text primary `#F2EBE3`, text secondary `#A69A8C`, accent `#F0824A`, glow `#F5B563`.

No red anywhere in the system, including the timer's final seconds — the no-failure-state principle applies to color, not just copy.

**Type:** SF Pro Rounded — free, native, and gets full Dynamic Type accessibility support with zero extra engineering.

**Spacing/radius/motion:** 8pt grid; one consistent 18px corner-radius token everywhere (mixed radii read as un-intentional design); soft ease-in-out motion, no springy overshoot except a single subtle instance on the celebration screen; full reduced-motion fallback (opacity fades replace movement).

**Components:** flat-fill buttons, no gradient overlays (a common tell of AI-generated-looking design), 48×48pt minimum tap targets; soft-filled inputs, glow-based focus state instead of hard outlines; circular timer ring in the accent color with the Ember centered inside, no color shift as time runs low; platform-native icon sets for anything functional, with custom illustration budget reserved entirely for the Ember.

**Accessibility:** full Dynamic Type; VoiceOver/TalkBack labels on every Ember state change (state changes are visual by default and need an explicit text equivalent); no color-only signaling; reduced-motion fallback.

**Empty/error states:** a small resting Ember plus one warm line of copy for empty states; errors framed as "let's try that differently," never a red alert box.

---

## 14. Onboarding

**The core decision:** onboarding *is* the first real rescue, not a preview of one — a canned demo task would contradict the entire pitch. No account, no personalization survey, no permission prompt before there's a reason for it.

1. **Welcome:** Ember resting; *"Kindling doesn't plan your day."* / *"It just helps you start the one thing you're avoiding."*; one button, **"Show me."**
2. **Real task entry:** cursor active, placeholder *"What are you avoiding?"*; optional tappable sample chip (*"Not sure? Try: reply to that one message you've been putting off"*) to solve blank-page freeze on the very first screen of an app for people who freeze on blank pages.
3. **First step:** Ember glows softly; their task shown back to them; the suggested step, large; **"Start (2 min)"** primary, **"Try a different step"** secondary.
4. **The session:** full-screen calm timer, Ember pulsing gently, step stays visible, **"Stop"** always available.
5. **End of session:** three equal-weight buttons — *"Keep going" / "That's enough for now" / "I got distracted."*
6. **First success:** Ember blooms gently, no confetti, no numbers; *"You started. That's the whole game."*
7. **Notification permission — the only permission ask in onboarding, and only here:** *"Want a nudge if this is still hanging around tomorrow?"* — Yes/Not now, no guilt copy on decline, no re-ask this session.

**Offline by design:** the entire onboarding path uses template-based generation only — no network call, because the worst possible first impression is a spinner on someone's first, already-vulnerable attempt to start something.

**Events fired (no task text ever included):** `onboarding_started`, `first_task_entered`, `sample_task_used`, `first_step_shown`, `step_regenerated`, `first_session_started`, `first_session_outcome`, `notification_permission_shown`, `notification_permission_result`, `onboarding_completed`.

**Biggest drop-off risk:** blank-page freeze on screen 2 — the exact problem the app exists to solve, hitting the user before they've gotten any value. The sample-task chip is the direct mitigation; watch its usage rate closely post-launch as a leading indicator.

**A/B tests worth running once there's traffic:** headline framing (differentiation-first vs. benefit-first), sample-chip presence, default first-session timer length (2 vs. 5 min), and permission-ask timing (after session 1 vs. session 2).

---

## 15. Monetization & pricing (final, revised version)

**The constraint that shapes everything:** Kindling is a reach-for-it-when-stuck tool, used maybe twice a week — not a daily habit. That rules out both a $6-10/month subscription (the zone every direct competitor sits in, and the exact zone their reviews complain about as fatigue-inducing) and, less obviously, an AI-usage quota as the primary paywall boundary: at this usage frequency, most people would simply never rack up enough AI calls to hit a monthly cap, so a satisfied user could go months without ever seeing a reason to upgrade.

**Free forever:** the full rescue flow at full quality — unlimited template-based steps, the timer, resume, a small AI-assist allowance (10/month, kept as a bonus not the main lever), the Ember experience, no account.

**The free-tier ceiling: one active task at a time.** This is the real boundary. Someone can fully use Kindling, indefinitely, on one avoided task. The paywall moment is trying to rescue a *second* task while the first is still parked — a boundary people hit organically and repeatedly as they rely on the app more, unlike a quota most usage patterns never reach.

**What's paid:**
- **Multiple concurrent parked tasks** — the primary lever, scales with real attachment to the app
- **Patterns / gentle insights** — a read-only view over the already-captured `obstacle_tag` and `outcome` data, effectively free to build, and impossible to offer on day one — a natural bridge from heavy free use to paid
- Unlimited AI-assisted steps (secondary, power-user bonus)
- Home-screen widget beyond the Live Activity, Watch app, custom timer durations, additional sound themes

**Pricing:** Monthly $3.99 (offered, not default); **Annual $19.99/yr (default)** — meaningfully undercuts Tiimo (~$54-80/yr), Finch (~$40-70/yr), Llama Life ($39/yr); **Lifetime $44.99 one-time** — the real differentiator, since none of the direct competitors researched offer one, and it directly answers the subscription-fatigue complaint that shows up repeatedly in their own reviews. 7-day trial. Regional pricing via Apple's/Google's built-in PPP tiers, no custom logic. Skip student pricing for v1. Native family sharing enabled at no extra build cost.

**Store fees, confirmed current:** Apple charges **15%**, not the standard 30%, via the Small Business Program (automatic for new developers under $1M/year). If RevenueCat is chosen over StoreKit 2 (§10), its own fee sits on top of that — standard tier is free up to a monthly tracked-revenue threshold, then a small percentage; confirm the current threshold and rate directly before finalizing the revenue math, since that's a RevenueCat pricing detail rather than an Apple one. Regional pricing note above still applies; the Google Play half of it is moot.

**Payments infrastructure: RESOLVED — RevenueCat (2026-08-18).** Required for Shipaton eligibility; see `IMPLEMENTATION.md` Phase 5 for why this overrode the technical recommendation below, which is left in place as the record of the original reasoning. ~~The default is **StoreKit 2 directly**~~ — one non-consumable and two subscriptions is a small surface, and Apple handles receipt validation, renewal, and restore natively. RevenueCat remains a reasonable alternative if its paywall experimentation tooling (§18) is judged worth a dependency and an added fee; its original justification, cross-platform entitlement state, no longer applies to a single-platform app.

**Paywall timing:** shown when someone tries to start a second concurrent task, from a settings "Upgrade" entry always available, and a single soft tease of "Patterns" once there's enough session history (5-7 sessions) for it to say something real. Never during onboarding, never mid-session.

**Ethical framing:** nobody is ever blocked from getting unstuck on the thing they came for — the paywall only appears when someone wants to expand into a second simultaneous task, a genuine capability expansion rather than a toll on the core promise.

**Revenue — clearly labeled assumptions, not a forecast** (3-6% freemium conversion, a general indie-app range with no ADHD-specific benchmark available; ~$17-19 net/paying-user/year after the 15% store fee):

| Installed users | Paying users | Illustrative annual revenue |
|---|---|---|
| 1,000 | 30-60 | ~$500-1,100 |
| 10,000 | 300-600 | ~$5,100-11,400 |
| 100,000 | 3,000-6,000 | ~$51,000-114,000 |

Honest read: modest until real scale; this is a distribution problem, not a pricing problem. Worth tracking once live: what fraction of active users attempt a second task within their first month — that number will validate or invalidate the boundary faster than a year of revenue data would.

---

## 16. Retention model

Built around the same twice-a-week reality, not daily-app benchmarks. **Activation metric:** first completed session (any outcome). **North-star metric:** rescues per active user per month — measures whether the app helps people start, not how often they open it. **Retention cohorts:** W1/W4/W12 *return-and-rescue* rate, not DAU, which would make a correctly-working app look like it's failing. **Churn definition:** no completed session in 60 days — deliberately longer than a typical app's window.

**Mechanics used:** resume-in-progress, the single opted-in stepped-away nudge, Patterns as an ongoing reason to return. **Deliberately absent:** streaks, an infinite feed, mystery rewards, emotional-dependence-inducing mascot behavior.

---

## 17. Notifications

Two ground rules: **notifications never include the task's own text** (they render on a public lock screen), and **cap at one per day, never stacked.**

| Notification | Copy | Fires when |
|---|---|---|
| Stepped-away nudge | *"Something you started is still here whenever you're ready."* | Next day, opted-in only, task in `stepped_away` status |
| Timer ended (backgrounded) | *"Your 2 minutes are up. Keep going, or that's enough for today — both are wins."* | Fallback when the Live Activity isn't visible |
| Return after time away | *"It's been a while. No pressure — Kindling's still here when something needs a nudge."* | Once, after ~14 days of no sessions, never more than monthly |

Deferred (needs the `Reminder` table, not in v1 schema): a scheduled task-start reminder and any "missed reminder" copy.

---

## 18. Analytics

**Tool: TelemetryDeck** — privacy-first, open-source SDK, EU-hosted, no IPs or personal identifiers by design, a native Swift SDK — fits the local-first posture better than Firebase without the ops burden of self-hosting Matomo/PostHog solo. *(Check current pricing directly before committing — not independently re-verified as current at time of writing this consolidated version.)*

**Event taxonomy** (no task or step text in any event, ever): `task_entered`, `first_step_shown`, `step_regenerated`, `session_started`, `session_outcome`, **`second_task_attempted`** (the single most important event — the direct signal on whether the monetization boundary is landing), `paywall_shown`, `upgrade_completed`, `patterns_viewed`, `notification_permission_result`, `notification_opened`.

**Funnel:** `onboarding_started` → `task_entered` → `first_step_shown` → `session_started` → `session_outcome` → (days later) `second_task_attempted` → `paywall_shown` → `upgrade_completed`.

**Experiment framework:** a simple remote-config flag covers headline framing, sample-chip presence, and timer length. The pricing and paywall-timing tests depend on the §10/§15 billing decision: RevenueCat would cover them with its own paywall experimentation tools, whereas StoreKit 2 means running them manually across releases — the main thing given up by dropping the dependency, and worth weighing deliberately rather than by default.

---

## 19. Validation plan

**Fake-door landing page**, before any production code: Kindling's name and positioning plus an email waitlist, measuring visitor-to-signup conversion as the earliest read on the plan's single biggest open risk (§2).

**Interviews:** 5-8 open-ended sessions with the target persona, recruited from the same communities as go-to-market — listening for how people already talk about being stuck, not pitching features.

**Usability testing:** 3-5 unmoderated sessions on a working prototype, watching time-to-first-session and sample-chip usage specifically.

**Beta:** TestFlight, ~20-50 people, 2-4 weeks, watching the timer/Live Activity/widget plumbing closely — the most technically fragile part of the build per §10.

---

## 20. Legal, safety & privacy

*Engineering-level guidance on what needs professional review — not legal advice.*

**Needs an actual lawyer:** the privacy policy and terms of use (straightforward to draft given how simple the local-first data flows are, but should still get real review — ADHD-adjacent framing brushes against health-app-adjacent scrutiny in some jurisdictions, e.g. EU/UK, even for a product that explicitly isn't a medical device); the exact legal phrasing and placement of the non-diagnostic disclaimer; the App Store/Play Store age-rating questionnaire, filled out against final content.

**Straightforward, because the architecture makes it true rather than just claimed:** local-only storage by default, deletion via the existing "clear finished tasks" action (no server copy to also delete), a simple local-data export option worth adding for portability, payments handled entirely by Apple (no PCI burden; if RevenueCat is used it needs its own line in the privacy policy as a data processor, alongside TelemetryDeck below, and if StoreKit 2 is used the processor list may reduce to TelemetryDeck alone), no cloud sync in v1 (needs its own privacy review whenever it's added), voice input deferred (needs mic-usage disclosure and a retention statement when it ships).

**Needs disclosure once built:** any third-party AI provider used for AI-assist (disclose that a task's text is sent for that single request; verify the provider's *current* data-retention/training-use terms before launch, not assumed from today); TelemetryDeck/analytics collection (declared accurately in privacy policy and store privacy labels, even though it's privacy-first); any crash reporting tool, configured to scrub PII and verified not to capture task text in stack traces.

**Store policy risk:** mental-health-adjacent apps sometimes draw extra App Review scrutiny even without medical claims — be ready to explain the non-medical, task-initiation-only positioning clearly in App Review notes, and keep all marketing copy consistent with that line.

---

## 21. Go-to-market

**Standing rule:** never exploit or spam the ADHD communities this app serves — disclosed, value-first participation over targeted promotion, throughout.

**Pre-launch (30 days):** the fake-door landing page; genuine build-in-public posts about specific decisions (the Ember, the no-streak design) rather than generic hype; disclosed participation in r/ADHD and similar communities, only mentioning Kindling when actually relevant; outreach to a small number of ADHD creators/coaches for honest product feedback, not paid placement.

**Launch week:** public store listing; Product Hunt; posts in the same communities, now with the actual link, to relationships already built rather than as a first appearance.

**Post-launch (60 days):** in-app review prompt after a few completed sessions, never after a `distracted` outcome; close tracking of `second_task_attempted` as both a retention and monetization signal; light ASO using real competitor search terms ("task initiation," "executive dysfunction") without naming competitor brands.

**Screenshot narrative (App Store, 5 shots):** welcome screen → real first-step screen → timer session with Ember → the three-choice no-shame end screen → the Live Activity on a lock screen, proving genuine OS-native integration.

**FAQ line worth keeping consistent everywhere:** *Is this free? Yes — the core rescue flow always is. Does this diagnose or treat ADHD? No, and it never will.*

---

## 22. Implementation roadmap

**Validation prototype** → landing page + clickable onboarding mock, tested against the core assumption in §2. **Design prototype** → stage-13 tokens built out directly in SwiftUI previews, Ember rendered at every required size to confirm it holds up small. **Technical foundation** → Xcode project, SwiftData schema in a local Swift package, SwiftUI app shell, and an (initially empty) Widget Extension target sharing an App Group — this is where the SwiftData/extension-sandbox integration either proves smooth or reveals friction, and deserves real budgeted time rather than assumed smoothness. **MVP** → the full v1 feature set in §7, built. **Private alpha** (5-10 people) → stress-test the Live Activity/backgrounding/force-quit paths specifically. **Public beta** (20-50 people, 2-4 weeks) → first-session completion, sample-chip usage, zero data-loss in resume. **v1 launch** → per §21. **v1.1** → AI-assisted steps (now that the template core has proven itself), home-screen widget, Watch app. **v1.5** → Patterns, obstacle-aware suggestions, richer history. **v2** → deliberately left open, to be justified by real v1/v1.1 usage data rather than guessed here.

The executable form of this roadmap, with phase gates and exit criteria, is `IMPLEMENTATION.md`.

### Engineering backlog (MVP scope)

| Epic | Story | Priority | Complexity | Platform |
|---|---|---|---|---|
| Data layer | Persist all five entities per §11 | P0 | M | KindlingCore (SwiftData) |
| Onboarding | Welcome → real task entry → first step (§14) | P0 | S | App |
| Step engine | Template-based first-step generation, offline | P0 | M | KindlingCore |
| Session core | Timer, three-choice end screen | P0 | M | App + KindlingCore |
| Live Activity | Lock screen / Dynamic Island timer | P0 | **L — highest-risk item in the backlog** | Widget extension |
| Resume | Pick up the stepped-away task | P0 | M | App |
| Entitlement + IAP | Purchase, restore, entitlement check; free ceiling of one active task enforced in KindlingCore | P0 | M | App + KindlingCore |
| Paywall UI | Second-task upgrade prompt screen | P0 | S | App |
| Notifications | Single stepped-away nudge, no task text | P1 | S | App |
| Analytics | Event taxonomy, TelemetryDeck | P1 | S | KindlingCore |
| Settings | Haptics, notification opt-in, clear tasks | P1 | S | App |
| Data export | Local JSON export | P2 | S | App |
| Accessibility pass | Dynamic Type, VoiceOver, reduced motion | P1 | M | App |

Timelines aren't set here deliberately — complexity ratings are the honest input for building a schedule against actual available hours, which this document can't responsibly guess at.

---

## 23. Primary risks

1. **The core assumption is unproven:** whether people install a dedicated app for this rather than reaching for a free tool already at hand (Goblin Tools, a Shortcut). This is the single biggest risk in the whole plan and the reason §19's validation step comes before full engineering investment.
2. **Technical risk concentrated in one place:** the native Live Activity/Dynamic Island integration, flagged as the highest-complexity item in the backlog and the most likely source of a launch-week bug.
3. **Low-frequency usage caps revenue ceiling:** even the revised monetization model only becomes a meaningful living at ~100K users — a real distribution challenge for a solo-built app in a crowded category, not something a different price point fixes.
4. **Competitive drift:** BrightMind and others are actively adding features (calendar integration, broader assistant capability) — the narrow-wedge positioning that makes this defensible today could erode if competitors converge toward it, or could remain safe if they keep drifting toward "broader assistant" as their own reviews suggest they're doing.
5. **App Store review scrutiny** on mental-health-adjacent positioning, addressed but not eliminated by careful non-medical framing (§20).

## 24. Open questions

- Exact AI provider for v1.1's AI-assist, and their current data-retention/training-use terms — not resolved here, needs a check at build time, not launch-planning time.
- Whether the one-task-free / multi-task-paid boundary actually converts as intended — genuinely unknown until `second_task_attempted` data exists.
- Whether the design system's color palette passes real WCAG contrast checks as specified, or needs adjustment.
- StoreKit 2 or RevenueCat for billing (§10/§15) — the trade is the paywall-experimentation tooling in §18 against a dependency and an added fee. Decide before purchase code is written.
- Whether TelemetryDeck's current pricing still fits a pre-revenue solo budget — not reconfirmed since the initial check.

## 25. Final recommendation

Build it — but the very next step is the **validation prototype** from §22, not engineering. Everything in this plan is designed around a narrow, defensible wedge rather than the broader tool the original brief first sketched, and that narrowing is the plan's main value: it's buildable solo, it doesn't compete head-on with a well-funded incumbent, and it has a real (if modest) path to sustainability. But it rests on one assumption nothing in this document has actually tested — that a dedicated app beats reaching for a free tool already at hand. A landing page and a handful of usability sessions can tell you that in days, for a tiny fraction of the cost of finding out after a full native build. Everything from §6 onward is ready to build against the moment that signal comes back positive.
