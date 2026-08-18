# Implementation status

Updated: 2026-08-18

## Phase 0 — Validation

State: **engineering assets complete; live validation deferred — gate overridden 2026-08-17**

| Item | State | Evidence / next action |
|---|---|---|
| 0.1 Design tokens + WCAG | Complete | `design/tokens.css` and `docs/design-tokens.md`; light accent corrected for interactive use |
| 0.2 Clickable prototype | Complete | Seven-screen no-build flow in `prototype/`; real timer, dev fast-forward, deterministic step rules, private local event export |
| 0.3 Astro landing page | Code complete | Landing, `/try/`, `/privacy/`, and `/terms/` build successfully |
| Hosted waitlist | Pending external setup | Create provider form and set `PUBLIC_WAITLIST_FORM_ACTION` |
| Deploy + custom subdomain | Pending external setup | Deploy `landing/dist/` and map `kindling.maskedsyntax.com` |
| 0.4 Measurement | Pending participants | Collect landing traffic, 5–8 interviews, and 3–5 prototype sessions |
| Gate decision | `GO`, recorded 2026-08-17 | Overridden on owner judgement with evidence outstanding; see the decision record in `docs/validation-results.md` |

Execution instructions, scripts, platform choices, and the gate rubric are in `docs/phase-0-validation-playbook.md`.

Automated verification at this checkpoint:

- Prototype contract, privacy, and 20-case step-engine tests: passing.
- Astro diagnostics: 0 errors, 0 warnings, 0 hints.
- Static production build: passing.
- Served route checks: `/`, `/try/`, `/privacy/`, `/terms/`, and prototype assets return successfully.
- Visual browser walkthrough: pending because no browser runtime was connected in the implementation workspace; follow the real-phone checklist in `docs/phase-0-runbook.md`.

## Phase 1 — Xcode foundation

State: **in progress — gate released 2026-08-17**

Stack: Swift + SwiftUI, iOS 17+, SwiftData, one Xcode project. **iOS only, permanently** — see `IMPLEMENTATION.md`, which also records why the earlier Kotlin Multiplatform plan was superseded.

The `ios/` gate is released. It was released by an explicit owner `GO` recorded in `docs/validation-results.md`, not by validation evidence — that distinction is recorded there and should not be smoothed over later.

## Phases 2–4

State: **code complete; simulator-verified. Device verification of the Live Activity failure paths is outstanding.**

| Item | State | Evidence |
|---|---|---|
| Xcode project, 3 targets, Swift 6 strict concurrency | Complete | Builds clean for simulator and for a signed device destination |
| SwiftData schema, App Group container, `SchemaV1` + migration plan | Complete | Row written, process terminated, cold launch read it back from `Containers/Shared/AppGroup/` |
| Widget extension reading the shared store | Complete | Builds; App Group entitlement present on both binaries in the device build |
| Template step engine | Complete | All 20 prototype cases ported and passing |
| Session state machine + injected clock | Complete | Force-quit, reboot, clock-forward, and clock-backward paths covered |
| Design system + Ember (5 states) | Complete | Verified in light and dark, at 24/48/72pt |
| Screens 1–7, resume, settings | Complete | Walked on simulator |
| App shell | Complete | Rescue flow is the root; settings behind one control that hides during a session; debug tools are `#if DEBUG` only |
| Live Activity | Code complete | Activity created and `active` on simulator, adopted by SpringBoard and chronod (confirmed in the ActivityKit log) |
| Accessibility | Complete for Dynamic Type | Largest accessibility size on every screen with no clipping or truncation |

Automated verification: **67 tests in `KindlingCore`, passing, with no simulator required.**

Run them with `cd ios/Packages/KindlingCore && swift test`.

Debug, Release, simulator, and signed-device destinations all build clean under Swift 6 strict concurrency, with no warnings in app code.

### Bug found and fixed during Phase 4 verification

`LiveActivityController.start` originally guarded on its own in-process handle. After a
force-quit and relaunch that handle is nil while the Activity started by the previous
process is still alive, so **each relaunch mid-session stacked another Live Activity**
— two were visible in the ActivityKit log before the fix. `start` now treats
`Activity.activities` as the source of truth and adopts an existing Activity instead of
requesting a second one. This is exactly the class of failure the plan predicted for
this phase, and it was only visible in the system log rather than on screen.

### C13 — what has now been verified, and on what

Verified on the simulator (2026-08-18):

| Path | Result |
|---|---|
| Force-quit mid-session, cold relaunch | Resumed into the running session at 1:49, ring advanced correctly |
| Device reboot mid-session (`simctl shutdown` + `boot`) | Resumed at 0:43, ring correct — time survived because it derives from the persisted `startedAt` |
| Live Activity created and adopted | Confirmed via the ActivityKit log; SpringBoard and chronod both picked it up |
| No task text on any lock-screen surface | Unit-tested over the real payload **and** the real notification copy |

### Still outstanding, and why

**Device testing is blocked by a version mismatch, not by configuration.** Developer
Mode is enabled and the phone is paired. The cause is that the iPhone runs **iOS 26.6
(23G71)** while Xcode 26.6 ships the **iOS 26.5** SDK and only offers a 26.5 device
support download — the installed developer disk image is build `27A5237l`, which
matches neither. `devicectl` therefore reports "The developer disk image could not be
mounted on this device."

The fix is an Xcode version that supports iOS 26.6; no amount of local configuration
will resolve it.

Left to verify on hardware once that lands:
- Live Activity rendered on a real lock screen. **Not verifiable from the command line
  either**: `simctl io screenshot` does not composite the Activity or Dynamic Island
  layer, so the Activity is provably created and adopted but how it *looks* is
  unconfirmed on any surface.
- Activity dismissed by the user mid-session, and the app reconciling on next foreground.
- Session ending while backgrounded, and the local notification actually being delivered
  (the copy and its privacy guarantee are unit-tested; delivery is not).
- VoiceOver walked through a complete session, confirming each Ember state is announced.
- Dynamic Island — **not testable on this device at all**: the iPhone 12 has none.
  Needs an iPhone 14 Pro or later, or the simulator.


## Phase 5

State: **in progress.** Full sequence and dates in `docs/release-plan.md`, which is the
authority for this phase; this table is the summary.

| Item | State | Evidence / next action |
|---|---|---|
| Billing decision | **Settled 2026-08-18 — StoreKit 2** | Resolved after a reversal to RevenueCat and back; Android was the whole basis for the reversal. Reasoning in `IMPLEMENTATION.md` Phase 5 |
| 5.1 StoreKit 2 plumbing | Complete | `ProductID` + `EntitlementProviding` in `KindlingCore` (zero dependencies); `StoreKitEntitlementStore` in the app target with a lifetime `Transaction.updates` listener. Debug and signed Release both build clean |
| Local purchase testing | Complete | `ios/Kindling.storekit` wired to the Debug scheme — purchases testable without App Store Connect or the Paid Applications Agreement |
| 5.2a Restore Purchases | Complete | Settings row on `AppStore.sync()`, three outcomes kept distinct, always visible |
| 5.2 Paywall UI | Not started | Build against `Kindling.storekit`; no external dependency |
| 5.3 Second-task trigger | Not started | `ActiveTaskPolicy` already encodes the boundary and is unit-tested; the paywall attaches where it is enforced |
| 5.4 TelemetryDeck + §18 events | Not started | **Promoted in importance.** With RevenueCat gone this is the *only* source of subscription and conversion data; `second_task_attempted` first |
| 5.5 Legal + store assets | Not started, **blocking, external latency** | Two processors: TelemetryDeck + OpenAI. See `docs/ai-privacy-todo.md` — including the still-open question of whether the hosted AI tier is worth keeping at all |
| 5.6 TestFlight → submit | Not started | Target: submission 2026-08-31 |
| Local JSON export (§20) | Not started | |
