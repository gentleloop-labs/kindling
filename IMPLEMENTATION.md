# Kindling — Implementation Plan

## Context

`docs/kindling-full-plan.md` is the product source of truth for Kindling, an ADHD task-initiation app: name the avoided task → get a small first step → run a short timer → three no-shame outcomes. This document is the engineering counterpart — it turns that product plan into an executable sequence.

**Kindling is an iOS app.** It is built in Swift and SwiftUI, in one Xcode project, with no cross-platform layer. Android is not planned, not scaffolded, and not designed for; it becomes a question only if there is a real, evidenced demand signal after iOS v1 ships, and it would be a separate native build starting from this same product plan.

This supersedes the earlier Kotlin Multiplatform plan. §10 of the product plan chose KMP to share logic between two native UIs — with only one platform, that argument disappears entirely and the shared-module tax is pure cost. §11's Room dependency goes with it.

**Decisions this plan is built on:**

| Decision | Choice | Why |
|---|---|---|
| Platform | iOS only, Swift + SwiftUI | Single target; native Live Activity / Dynamic Island support is a core feature, not polish |
| Minimum OS | iOS 17 | Unlocks SwiftData, `@Observable`, and mature ActivityKit with no availability branching |
| Persistence | SwiftData | Native, minimal code, integrates directly with SwiftUI; App Group container shared with the widget target |
| Concurrency | Swift 6 language mode, strict concurrency | Cheap to adopt in a greenfield codebase, expensive to retrofit |
| Sequencing | Validation gate first | Unchanged from the original plan — §25 says the next step is validation, not engineering |
| Billing | **RevenueCat** (decided 2026-08-18) | Reversed from StoreKit 2 — see Phase 5. Android is intended eventually, which restores the original cross-platform-entitlement argument; subscription analytics are the near-term payoff |

**Feature scope is unchanged.** Every feature in §7 of the product plan ships as specified. Nothing was added or cut in this replan — only the stack under it changed.

**Intended outcome:** a shippable iOS v1 of the free rescue flow, built only after the core assumption gets a real signal.

---

## Target repo layout

```
kindling/
├── docs/
│   ├── kindling-full-plan.md        # product source of truth
│   ├── design-tokens.md             # §13 tokens + WCAG results
│   └── validation-results.md        # Phase 0 findings and the gate decision
├── design/tokens.css                # canonical token values, consumed by web surfaces
├── landing/                         # Astro static site → kindling.maskedsyntax.com
│   └── public/try/                  # prototype build output, served at /try
├── prototype/                       # standalone clickable onboarding mock
└── ios/                             # created in Phase 1, not before
    ├── Kindling.xcodeproj
    ├── Kindling/                    # app target (SwiftUI)
    ├── KindlingWidget/              # widget extension: Live Activity + (v1.1) home screen
    └── Packages/
        └── KindlingCore/            # local SPM package — models, step engine, session logic
```

`KindlingCore` is a **local Swift package, not a framework target**. It exists for one reason: the domain logic must be testable without launching the app, and importable by both the app and the widget extension. Keep it free of SwiftUI and of anything that requires a running app — that constraint is what keeps its tests fast.

---

## Phase 0 — Validation (no app code)

**Status: engineering assets complete, live validation pending.** See `docs/implementation-status.md` for the current state and `docs/phase-0-validation-playbook.md` for execution.

**Goal:** a real read on whether a dedicated app beats a free tool already at hand.

### 0.1 Design tokens — done
`docs/design-tokens.md` and `design/tokens.css` carry the §13 palette with a completed WCAG pass. The light accent was darkened for interactive/text use while the bright value is kept for the Ember glow only. **Phase 3 consumes these values — do not re-derive colors in Swift.** Port them once into a `Color` extension backed by an asset catalog with light/dark variants, and keep the token names identical to the CSS so the landing page, prototype, and app can never drift.

### 0.2 Clickable prototype — done
Seven §14 onboarding screens, no build step, real timer with a dev fast-forward, deterministic step rules, private local event export with no task text.

The JS step engine here is a **throwaway whose value is the rule set, not the code.** Its 20-case test suite is the specification Phase 2 ports to Swift — carry the cases over verbatim so the Swift engine is provably equivalent to the one that was validated with real users.

### 0.3 Landing page — code complete
Astro site with `/try/`, `/privacy/`, `/terms/`. Waitlist endpoint and deployment remain pending external setup.

### 0.4 Measure
Two numbers decide the gate: **visitor → waitlist conversion** and **prototype completion rate** (reached the success screen). Plus 5–8 interviews per §19, listening for how people already describe being stuck.

### Gate
**Do not create `ios/` until `docs/validation-results.md` records an explicit `GO`, `REDIRECT`, or `STOP`.** A weak signal isn't a failure — it's a redirect (a widget-only build, an iOS Shortcut, a web app) that saves months of native work. Watch **sample-chip usage rate** specifically; §14 names blank-page freeze on screen 2 as the biggest drop-off risk.

If the decision is `REDIRECT`, revise this document before scaffolding anything.

---

## Phase 1 — Xcode foundation (`ios/`)

**Status: complete.** Project generated by XcodeGen from `ios/project.yml` with build settings in `ios/Config/*.xcconfig`, so configuration changes review as readable diffs. `Kindling.xcodeproj` is a generated artifact rather than the source of truth.

§22 says this phase deserves real budgeted time rather than assumed smoothness. That still holds — the risky integration is just different now. The KMP/Gradle/XCFramework friction is gone; what remains is **SwiftData sharing a store with an extension target**, which is where this stack's version of the same problem lives.

### 1.1 Project scaffold
One Xcode project, three targets: app, widget extension, and the `KindlingCore` local package. Swift 6 language mode on from the first commit. Deployment target iOS 17.0.

Configure the **App Group** (`group.dev.aftaab.kindling` or equivalent) on both the app and the widget extension before writing any persistence code — retrofitting a store relocation after data exists is a migration you don't want to write for free.

Commit the `.xcodeproj` but keep build settings in `.xcconfig` files, so config changes review as readable diffs rather than as project-file churn.

### 1.2 SwiftData schema
All five §11 entities as `@Model` types in `KindlingCore`: `Task`, `FirstStep`, `StarterSession`, `UserPreference`, `AiRequestLog`. Follow §11 exactly, **including what's deliberately absent** — no `Reminder` entity, no persisted mascot state, no `SubscriptionEntitlement` yet.

Two things to get right at the schema level rather than the UI level:
- `StarterSession.outcome` is a three-value enum with **no failure state**. This is the no-shame principle enforced in the data model.
- `AiRequestLog` has **no prompt/response property**, making it structurally impossible to leak task content.

SwiftData specifics that matter here:
- Build the `ModelContainer` with a `ModelConfiguration` pointing at the **App Group container URL**, not the default app-sandbox location. Do this in `KindlingCore` so app and extension get the identical configuration from one place and cannot disagree.
- Adopt **`VersionedSchema` and a `SchemaMigrationPlan` from v1**, with `SchemaV1` named as such even though there is nothing to migrate from yet. Lightweight migrations are only free if the versioning scaffolding already exists.
- `Task` deletes cascade to `FirstStep`, `StarterSession`, and `AiRequestLog` — set the delete rules explicitly rather than relying on defaults.
- The settings "exclude from backup" toggle (§11) sets `isExcludedFromBackup` on the store file URL. Write and test that helper here, while the file layout is fresh.

`Task` is also the name of Swift's concurrency type. Namespace the model (`KindlingCore.Task`) or name it `AvoidedTask` — decide once, in this phase, before it appears in a hundred call sites.

### 1.3 Widget extension smoke test
An **empty but wired** widget extension target that reads one row through the shared container and renders it. Nothing product-facing.

**Exit criterion:** the SwiftUI app writes a `Task` row, reads it back after a cold launch, the widget extension reads the same row through the App Group, and the extension builds and installs on a device. If SwiftData and the extension sandbox are going to fight each other, find out here with nothing else in flight.

---

## Phase 2 — Domain core (`KindlingCore`)

**Status: complete.** 40 tests, no simulator required.

Pure Swift, no SwiftUI, fully unit-tested. This is the most testable part of the app and should be finished before UI work starts. Use Swift Testing (`@Test`/`#expect`), not XCTest.

**Template step engine** (`KindlingCore/Step/`) — port the rules validated in Phase 0's JS prototype, carrying its 20 test cases across as the baseline suite. Deterministic, offline, zero latency, per §12: **no AI in v1 at all.** Define the engine behind a protocol so v1.1's AI layer can slot in as an opt-in decorator that falls back to the template path on any failure — declare the protocol, but do not build the AI plumbing behind it.

**Session state machine** (`KindlingCore/Session/`) — `Task` status transitions (`active` → `stepped_away` → `done`/`discarded`) and the session lifecycle. The hard cases are all about time passing outside the app: backgrounded, force-quit mid-session, device rebooted, clock changed.

**Persist `started_at` and derive remaining time from wall-clock on every resume** rather than trusting an in-memory countdown. This single decision is what makes §22's "stress-test force-quit paths" survivable, and it's what lets the Live Activity in Phase 4 be a pure render of a date range rather than a thing that needs feeding.

Inject a clock (a `now: () -> Date` dependency or the `Clock` protocol) rather than calling `Date()` inline — the interrupted-session tests are unwritable otherwise, and they are the tests that matter most.

**Tests:** table-driven over the step engine with real task strings collected in Phase 0; exhaustive transition coverage on the state machine including every interrupted-session path.

---

## Phase 3 — App UI (SwiftUI)

**Status: complete, simulator-verified.**

Build in the §14 onboarding order, since onboarding *is* the first rescue — the same screens serve both first-run and every subsequent use.

- **Task entry** — cursor active on appear (`@FocusState` set in `.task`, not `onAppear`, so it survives the first layout pass), `"What are you avoiding?"` placeholder, sample chip present.
- **First step** — task echoed back, step large, `Start (2 min)` primary, `Try a different step` secondary.
- **Timer session** — full-screen, circular ring in the accent color with the Ember centered, **no color shift as time runs low** (§13: no red anywhere, including the final seconds), step stays visible, Stop always available.
- **Three-choice end screen** — equal visual weight on all three; any hierarchy here implies a right answer and breaks the core principle.
- **First success** — Ember blooms, no confetti, no numbers.
- **Resume** — the parked task reopens exactly where it was with nothing to re-enter.
- **Settings** — haptics toggle, notification opt-in, clear finished tasks, exclude-from-backup toggle (§11).

**Architecture:** `@Observable` view models over `KindlingCore` types. Use SwiftData's `@Query` only for genuinely simple list reads; route anything with real logic through the session state machine so the rules stay in the tested layer rather than migrating into views.

**The Ember** is one SwiftUI view driven by a five-case state enum (§9), consumed by the app, the widget, and later the Watch app — so it lives in `KindlingCore`'s UI-adjacent module or its own small package the extension can import. Its state is **derived, never persisted** (§11). Every state change needs an explicit VoiceOver label: state is conveyed by glow, which is invisible to a screen reader.

Accessibility is built in as you go, not as a final sweep: Dynamic Type on every screen, 48×48pt minimum targets, reduced-motion fallbacks (opacity fades replace movement), no color-only signaling.

---

## Phase 4 — Live Activity (highest-risk item)

**Status: code complete; the failure paths below still need a physical device.** See `docs/implementation-status.md` for the exact outstanding list.

§23 names this the most likely source of a launch-week bug, so it gets its own phase with its own buffer. This is the item that justified going native in the first place — it now sits in the same language as the rest of the app, which removes the bridging layer but none of the OS-level failure modes.

ActivityKit Live Activity showing the timer on the lock screen and in the Dynamic Island. Use a **`ClosedRange<Date>` timer style so the OS renders the countdown itself** — do not push per-second updates; you'll exhaust the update budget and drain battery. Because Phase 2 persists `started_at` and derives remaining time, the Activity's content state is a date range computed once at session start and never refreshed for normal countdown.

Then work the failure paths deliberately, because these are where it breaks in the field:
- App force-quit mid-session — does the Activity persist and stay accurate?
- Activity dismissed by the user while a session runs — the app must reconcile on next foreground.
- Session ending while the app is backgrounded → local notification fallback per §17 (*"Your 2 minutes are up. Keep going, or that's enough for today — both are wins."*).
- Device reboot mid-session.
- **Notification and Live Activity text never contains the task's own title** (§17) — it renders on a public lock screen. Write a test asserting this, over the actual content-state construction, not over a copy of the strings.

---

## Phase 5 — Pre-launch stack

The deferred work, batched so it lands together before beta.

### Billing — a decision this replan reopens
§10 and §15 chose RevenueCat, and the stated reason was **cross-platform entitlement state**: "is the multi-task tier unlocked" resolving identically whether the purchase came from Apple or Google. With Android gone, that reason is gone with it. StoreKit 2 on its own is a small, well-documented API for one non-consumable and two subscriptions, and it removes both a dependency and RevenueCat's fee on top of Apple's 15%.

**Decision: RevenueCat. Reversed 2026-08-18.**

The rejection above was reasoned from a premise that no longer holds. It killed
RevenueCat because cross-platform entitlement state — its original justification —
became irrelevant once Android was dropped. **Android is intended again**, so that
justification returns on its own terms. This is a reversal of the premise, not an
override of the conclusion.

Two further reasons the original analysis under-weighted, both of which hold even
while the app is iOS-only:

- **Subscription analytics.** MRR, churn, trial conversion, and cohort data arrive
  for free. §15's revenue model is explicitly labelled assumption rather than
  forecast ("3-6% freemium conversion, no ADHD-specific benchmark available"), and
  §15 names the number that actually matters — *what fraction of active users
  attempt a second task in their first month*. RevenueCat answers that on day one;
  StoreKit 2 leaves it a guess unless the instrumentation is hand-built.
- **§18's pricing and paywall-timing A/B tests**, which the StoreKit 2 choice had
  written off as manual work across releases.

Costs, unchanged and still real:
- A third-party dependency in the purchase path.
- **A third data processor** in the privacy policy, alongside TelemetryDeck and
  OpenAI. Legal review is already on the critical path; this adds to it.
- RevenueCat's fee above Apple's 15% — though at §15's own projected scale this is
  theoretical for a long while, since RevenueCat is free below its tracked-revenue
  threshold.

**Shipaton is not the reason.** Entering it requires the RevenueCat SDK, and Kindling
is being entered — but the release window (2026-08-01 to 09-30) already contains the
independently chosen 08-31 submission date, so eligibility costs nothing extra and
justifies nothing on its own.

### What this does *not* change

Android returning as an intention does not re-open the rest of the iOS-only cascade.
KMP stays rejected, SwiftData stays. But record the real cost honestly: **`KindlingCore`
is Swift**, so an Android build means reimplementing the step engine and session state
machine, not sharing them. RevenueCat makes *entitlements* cross-platform; it does
nothing for the domain layer. Revisit only against a real demand signal, per §10.

Either way: the free-tier ceiling is **one active task at a time** (§15) — enforce it in `KindlingCore` so the rule is unit-tested rather than scattered through view code.

### The rest
- **TelemetryDeck** (native Swift SDK) + the §18 event taxonomy in `KindlingCore`. `second_task_attempted` is the single most important event — the direct read on whether the monetization boundary lands. Verify current pricing before committing (§24).
- **Paywall UI** on second-task attempt only. Never during onboarding, never mid-session.
- **Notifications** (§17): the single opted-in stepped-away nudge, capped at one per day.
- **Local JSON data export** (§20).
- **Privacy policy, terms, App Store privacy labels, non-diagnostic disclaimer.** §20 flags these as needing actual legal review — start that early, it has external latency. The processor list did **not** shrink as the original replan hoped: it is now TelemetryDeck **plus RevenueCat** (billing) **plus OpenAI** (optional AI steps, where the device cannot run them on-device). See `docs/ai-privacy-todo.md`.
- **App Review notes** explaining the non-medical, task-initiation-only positioning (§20 store-policy risk).

Then: private alpha (5–10 people via TestFlight, hammering force-quit and backgrounding paths), public beta (20–50 people, 2–4 weeks, watching first-session completion and zero data loss on resume), launch per §21.

---

## What this plan deliberately leaves out

Per §7 and the §4 anti-creep principles: no AI in v1, no calendar or day planning, no streaks, no accounts, no mandatory voice input, no multiple concurrent tasks in the free tier, no `Reminder` entity. Watch app, home-screen widget, and Patterns are v1.1/v1.5.

**And no Android.** The budget the original plan reserved for a second native UI, a second timer surface, and a second accessibility pass is not reallocated to new features — it comes off the top. A narrower plan finishing sooner is the point.

---

## Verification

| Phase | How it's verified |
|---|---|
| **0** | Landing page and prototype deployed; all seven screens walked on a real phone browser; events fire with no task text in any payload; waitlist submissions arrive. Success is a decision recorded in `docs/validation-results.md`, not a green build. |
| **1** | Project builds clean under Swift 6 strict concurrency. App writes and reads a `Task` row across a cold launch. Widget extension reads the same row through the App Group and installs on a device. |
| **2** | `swift test` on `KindlingCore` — step engine table tests (ported from the prototype's 20 cases) and full state-machine transition coverage, including force-quit and clock-change paths. Runs without a simulator. |
| **3** | Simulator and real device. Manual accessibility pass: VoiceOver through a full session confirming every Ember state is announced; largest Dynamic Type size on every screen with no clipping; reduced-motion enabled. |
| **4** | Device-only and manual: start a session, lock the screen, confirm the Dynamic Island countdown; force-quit mid-session and confirm the Activity survives and stays accurate; background the app through session end and confirm the notification fallback; reboot mid-session. Assert no task text on any lock-screen surface. |
| **5** | Sandbox purchase, restore, and entitlement check across a reinstall. Export produces valid JSON. Alpha and beta exit criteria per §22. |

**Cross-cutting, run before each phase closes:** kill the app mid-session and confirm resume loses nothing. §22 names zero data loss in resume as a beta exit criterion, and it's cheaper to hold that line continuously than to chase it at the end.
