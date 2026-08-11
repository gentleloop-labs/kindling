# Kindling — Implementation Plan

## Context

`kindling-full-plan.md` is a complete product plan for Kindling, an ADHD task-initiation app: name the avoided task → get a small first step → run a short timer → three no-shame outcomes. The repo is currently empty of code (`README.md`, `.gitignore`, the plan doc). This document turns that product plan into an executable engineering sequence.

Two things shape the sequence:

1. **§25 of the product plan says the next step is validation, not engineering.** The single biggest unproven assumption is that people will install a dedicated app rather than reach for Goblin Tools in a browser tab. So Phase 0 is a landing page + clickable prototype, and Phase 1+ is explicitly **gated** on that signal.
2. **§10's finding that widgets/Live Activities can't be cross-platform** drives the stack: Kotlin Multiplatform for shared logic, fully native SwiftUI and Compose UIs.

**Decisions made for this plan** (confirmed with the user):
- Validation first, engineering staged behind it as a gate.
- **iOS first**, Android as a later phase — confronts the highest-risk item (Live Activity) early.
- **Free flow first**: RevenueCat/paywall and TelemetryDeck are deferred to a distinct pre-launch phase, not in the first build pass. This deviates from the §22 backlog, which marks IAP as P0.
- Web prototype, Astro landing page, one monorepo.

**Intended outcome:** a shippable iOS v1 of the free rescue flow, built only after the core assumption gets a real signal.

---

## Target repo layout

```
kindling/
├── docs/
│   ├── kindling-full-plan.md      # moved from root
│   ├── design-tokens.md           # §13 tokens + WCAG results
│   └── validation-results.md      # Phase 0 findings, written as they come in
├── landing/                       # Astro static site → kindling.maskedsyntax.com
│   └── public/try/                # prototype build output, served at /try
├── prototype/                     # standalone clickable onboarding mock
└── app/                           # created in Phase 1, not before
    ├── shared/                    # KMP: models, step engine, session state, Room
    ├── iosApp/                    # SwiftUI + Widget Extension
    └── androidApp/                # Compose (Phase 5)
```

Keep the plan doc at `docs/kindling-full-plan.md` and treat it as the product source of truth; this file is the engineering counterpart.

---

## Phase 0 — Validation (no app code)

**Goal:** a real read on whether a dedicated app beats a free tool already at hand.

### 0.1 Design tokens, once, in one place
Write `docs/design-tokens.md` from §13 and **run a real WCAG pass** — §24 lists this as an open question. Check every foreground/background pair in both themes against 4.5:1 (body) and 3:1 (large text / UI). The accent `#E8703A` on warm-paper `#FAF6F1` is the pair most likely to fail for body text; expect to darken the accent for text use while keeping the bright value for the Ember glow only. Record pass/fail per pair in the doc — the prototype, landing page, and both native apps all consume these values, so getting them right once saves three fixes later.

### 0.2 Clickable prototype (`prototype/`)
A self-contained HTML/CSS/JS mock of the seven §14 onboarding screens: welcome → task entry (with the sample chip) → first step → timer session → three-choice end → first success → notification ask (mocked, no real permission).

- No framework, no dependencies, no build step — it must be trivially deployable under `landing/public/try/`.
- The timer runs for real (2 min, with a dev-only fast-forward for testing sessions).
- The Ember is a placeholder here — a circle with a CSS glow driven by the five §9 states. Do **not** invest in final mascot art before validation.
- Instrument the same event names the real app will use (§14 list): `onboarding_started`, `first_task_entered`, `sample_task_used`, `first_step_shown`, `step_regenerated`, `first_session_started`, `first_session_outcome`, `onboarding_completed`. Log to a simple endpoint or a local buffer with a copy-out button — **never** send task text.
- Build the template step engine here in JS **as a throwaway**. Its real value is that the rules get exercised against ~20 real task strings from interviews before being ported to Kotlin.

### 0.3 Landing page (`landing/`, Astro)
Single page: positioning line from §4, the "You don't need a fire. You need a spark." tagline, three-beat explanation of the loop, an honest "what this is not" section (it's the differentiator — say it out loud), email waitlist, and a **"Try it now"** link to `/try`.

- Waitlist: a hosted form endpoint (Buttondown/Formspark/similar) rather than a backend — no server to maintain, and no personal data sitting in your infra.
- Add `/privacy` and `/terms` stubs now; the store submission needs live URLs and they're easy to forget.
- Deploy to Cloudflare Pages or Netlify on the `kindling.maskedsyntax.com` subdomain.

### 0.4 Measure
Two numbers decide the gate: **visitor → waitlist conversion** and **prototype completion rate** (reached the success screen). Plus 5-8 interviews per §19, listening for how people already describe being stuck.

### Gate
Do not start Phase 1 until Phase 0 has produced a decision written into `docs/validation-results.md`. A weak signal here isn't a failure — it's a redirect (a widget-only build, an iOS Shortcut, a web app) that saves months of native work. Watch the **sample-chip usage rate** specifically; §14 names blank-page freeze on screen 2 as the biggest drop-off risk.

---

## Phase 1 — Technical foundation (`app/`)

§22 explicitly says this phase deserves real budgeted time rather than assumed smoothness. The point of Phase 1 is to prove the KMP + Room + native-widget integration works **before** any product code depends on it.

### 1.1 KMP scaffold
Generate via the Kotlin Multiplatform wizard (`kmp.jetbrains.com`), Gradle wrapper committed. Targets: `iosArm64`, `iosSimulatorArm64`, `androidTarget` (declared now even though the Android UI comes in Phase 5 — retrofitting a target is worse than carrying an unused one). Shared module exports an XCFramework consumed by `iosApp`.

Pin the latest stable Kotlin / AGP / Room versions **at scaffold time** rather than from this document — the product plan is dated August 2026 and version guidance goes stale fast.

### 1.2 Room KMP schema
All five §11 tables in `shared/src/commonMain`: `Task`, `FirstStep`, `StarterSession`, `UserPreference`, `AiRequestLog`. Follow §11 exactly, including what's deliberately absent (no `Reminder` table, no persisted mascot state, no `SubscriptionEntitlement` yet).

Two things to get right at the schema level rather than the UI level:
- `StarterSession.outcome` is a three-value enum with **no failure state** — this is the no-shame principle enforced in the data model.
- `AiRequestLog` has **no prompt/response column**, making it structurally impossible to leak task content.

Enable Room's exported schema JSON and commit it from day one; auto-migrations need the baseline. Platform-specific database builders (`expect`/`actual`) resolve the sandbox path per platform.

### 1.3 Native shells + empty Widget Extension
A SwiftUI app that calls one function in the shared module and renders the result, plus an **empty but wired** iOS Widget Extension target with App Group entitlement configured. This is the integration smoke test — if KMP, Room, and the extension target are going to fight each other, find out here with nothing else in flight.

**Exit criterion:** SwiftUI app writes a `Task` row via shared Kotlin, reads it back after a cold launch, and the Widget Extension builds and appears on the lock screen (even blank).

---

## Phase 2 — Step engine and session core (shared)

Everything here is platform-agnostic Kotlin with unit tests. It is the most testable part of the app and should be finished before UI work starts.

**Template step engine** (`shared/.../step/`) — port the rules validated in Phase 0's JS prototype. Deterministic, offline, zero latency, per §12: **no AI in v1 at all**. Design the interface so v1.1's AI layer slots in behind it as an opt-in decorator that falls back to the template path on any failure — but do not build the AI seam's plumbing yet, just don't foreclose it.

**Session state machine** (`shared/.../session/`) — the `Task` status transitions (`active` → `stepped_away` → `done`/`discarded`) and session lifecycle. The hard cases are all about time passing outside the app: backgrounded, force-quit mid-session, device rebooted, clock changed. **Persist `started_at` and derive remaining time from wall-clock on every resume** rather than trusting an in-memory countdown — this is the single design decision that makes §22's "stress-test force-quit paths" survivable.

Tests: table-driven over the step engine with real task strings collected in Phase 0; exhaustive transition tests on the state machine including every interrupted-session path.

---

## Phase 3 — iOS app (SwiftUI)

Build in the §14 onboarding order, since onboarding *is* the first rescue — the same screens serve both first-run and every subsequent use.

- **Task entry** — cursor active on appear, `"What are you avoiding?"` placeholder, sample chip present.
- **First step** — task echoed back, step large, `Start (2 min)` primary, `Try a different step` secondary.
- **Timer session** — full-screen, circular ring in the accent color with the Ember centered, **no color shift as time runs low** (§13: no red anywhere, including the final seconds), step stays visible, Stop always available.
- **Three-choice end screen** — equal visual weight on all three; any hierarchy here implies a right answer and breaks the core principle.
- **Resume** — the parked task reopens exactly where it was with nothing to re-enter.
- **Settings** — haptics toggle, notification opt-in, clear finished tasks, exclude-from-backup toggle (§11).

**The Ember** is one SwiftUI view driven by a five-case state enum (§9), consumed by the app, the widget, and later the Watch app. Every state change needs an explicit VoiceOver label — state is conveyed by glow, which is invisible to a screen reader.

Accessibility is built in as you go, not as a Phase-6 sweep: Dynamic Type on every screen, 48×48pt minimum targets, reduced-motion fallbacks (opacity fades replace movement), no color-only signaling.

---

## Phase 4 — Live Activity (highest-risk item)

§23 names this the most likely source of a launch-week bug, so it gets its own phase with its own buffer.

ActivityKit Live Activity showing the timer on lock screen and Dynamic Island, driven by the shared session state through an App Group. Use a **`ClosedRange<Date>` timer style so the OS renders the countdown itself** — do not push per-second updates; you'll hit the update budget and drain battery.

Then work the failure paths deliberately, because these are where it breaks in the field:
- App force-quit mid-session — does the Activity persist and stay accurate?
- Activity dismissed by the user while a session runs.
- Session ending while the app is backgrounded → local notification fallback per §17 (`"Your 2 minutes are up. Keep going, or that's enough for today — both are wins."`).
- Device reboot mid-session.
- **Notification and Live Activity text never contains the task's own title** (§17) — it renders on a public lock screen. Add a test asserting this.

---

## Phase 5 — Android (Compose)

Same shared module, native Compose UI mirroring Phase 3 screen for screen. The Live Activity equivalent is an ongoing foreground-service notification with a chronometer; §24 flags that the polished approach needs its own design pass — budget for that rather than assuming parity. Note Android 13+ runtime notification permission and 14+ foreground-service type declarations.

---

## Phase 6 — Pre-launch stack

The deferred work, batched so it lands together before beta:

- **TelemetryDeck** + the §18 event taxonomy in shared code. `second_task_attempted` is the single most important event — it's the direct read on whether the monetization boundary lands. Verify TelemetryDeck's current pricing before committing (§24).
- **RevenueCat** via `purchases-kmp` in the shared module: purchase, restore, cross-platform entitlement check. The free-tier ceiling is **one active task at a time** (§15) — enforce it at the shared-logic layer so both platforms inherit it.
- **Paywall UI** on second-task attempt only. Never during onboarding, never mid-session.
- Notifications (§17): the single opted-in stepped-away nudge, capped at one per day.
- Local JSON data export (§20).
- Privacy policy, terms, store privacy labels, non-diagnostic disclaimer. §20 flags these as needing actual legal review — start that early, it has external latency.
- App Review notes explaining the non-medical, task-initiation-only positioning (§20 store-policy risk).

Then: private alpha (5-10 people, force-quit/backgrounding paths), public beta (20-50, 2-4 weeks, watching first-session completion and zero data loss on resume), launch per §21.

---

## What this plan deliberately leaves out

Per §7 and the §4 anti-creep principles: no AI in v1, no calendar or day planning, no streaks, no accounts, no mandatory voice input, no multiple concurrent tasks in the free tier, no `Reminder` table. Watch app, home-screen widget, and Patterns are v1.1/v1.5.

---

## Verification

**Phase 0:** deploy the landing page and prototype; walk all seven screens on a real phone browser; confirm events fire with no task text in any payload; confirm waitlist submissions arrive. Success is a decision recorded in `docs/validation-results.md`, not a green build.

**Phase 1:** `./gradlew build` green; iOS app writes and reads a `Task` row across a cold launch; Widget Extension builds and installs.

**Phase 2:** `./gradlew :shared:allTests` — step engine table tests and full state-machine transition coverage, including force-quit and clock-change paths.

**Phase 3:** run on simulator and a real device. Manual accessibility pass: VoiceOver through a full session confirming every Ember state is announced; largest Dynamic Type size on every screen with no clipping; reduced-motion enabled.

**Phase 4:** device-only, and manual — start a session, lock the screen, confirm the Dynamic Island countdown; force-quit the app mid-session and confirm the Activity survives and stays accurate; background the app through session end and confirm the notification fallback; reboot mid-session. Assert no task text appears in any lock-screen surface.

**Phase 5:** same manual matrix on a physical Android device, plus notification-permission-denied and battery-optimization-killed paths.

**Cross-cutting, run before each phase closes:** kill the app mid-session and confirm resume loses nothing — §22 names zero data loss in resume as a beta exit criterion, and it's cheaper to hold that line continuously than to chase it at the end.
