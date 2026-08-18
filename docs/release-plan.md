# Release plan — App Store submission by 2026-08-31

Created 2026-08-18, revised the same day. Supersedes the two-day sprint plan, which
targeted a working v1 rather than a shipped product.

**The date is 08-31.** It was chosen independently of anything external and it governs.

*Shipaton was previously noted here as a free by-product. It is not: entering requires
the RevenueCat SDK, and billing is now StoreKit 2 (see `IMPLEMENTATION.md` Phase 5), so
Kindling is not eligible. Nothing in this plan depended on it — the date was never
Shipaton's — but the eligibility is gone and should not be assumed anywhere downstream.*

## The goal changed, so the shape of the work changed

| | Sprint plan (to 08-19) | This plan (to 08-31) |
|---|---|---|
| Deliverable | Working v1 on a device | **Publicly released app on the App Store** |
| Billing | Explicitly out of scope | **Required** — StoreKit 2 powering a real purchase |
| Privacy/legal | Deferred | **Blocking** — cannot ship without it |
| Store assets | Deferred | **Blocking** |

The deliverable is a **public App Store release**, not a TestFlight build.

## What is already done

Phases 0–4 are complete and verified: the rescue flow, SwiftData in an App Group, the
tested domain core, Live Activity, accessibility, and the AI step layer (on-device →
hosted → template). 64 tests; Debug and signed Release both build clean.

**`ActiveTaskPolicy` already encodes the paywall boundary** and is unit-tested. The
entitlement check has a single home; StoreKit feeds it rather than replacing it.

## Critical path — start the slow things first

These have **external latency** and are the real risk to the date. Nothing about the
code is on the critical path; these are.

Dates below target **submission on 08-31**, with App Review after that.

| # | Item | Owner | Blocks | Start by |
|---|---|---|---|---|
| 1 | **Paid Applications Agreement**, banking + tax forms in App Store Connect | You | *All* purchases. Products cannot be sold — or reliably tested — until Apple accepts these | **Immediately** |
| 2 | App Store Connect app record + bundle ID `dev.aftaab.kindling` | You | Products, TestFlight, submission | Immediately |
| 3 | Products created in App Store Connect, with IDs matching `ProductID` in `KindlingCore` **exactly** | You + me | Real-store purchase testing (**not** local testing — see below) | Within days of 1–2 |
| 4 | Privacy policy + terms, reviewed by an actual lawyer | You | App Store submission | **Early September at the latest** |
| 5 | App Store review | Apple | Public release | Submit by **~2026-09-15** to leave buffer for a rejection |

> Item 1 is the classic silent blocker: everything looks fine until purchases fail in
> sandbox with no clear reason. Do it first.
>
> **But it no longer blocks building the paywall.** `ios/Kindling.storekit` is wired to
> the Debug scheme, so every purchase, restore, and entitlement path is exercisable
> locally today. Items 1–3 gate *shipping* purchases, not writing them — which is the
> whole reason the local config exists.

## Products (§15, unchanged)

| Product | Type | Price |
|---|---|---|
| Monthly | auto-renewing subscription | $3.99 |
| **Annual (default)** | auto-renewing subscription | **$19.99/yr** |
| Lifetime | non-consumable | $44.99 |

7-day trial. Regional pricing via Apple's built-in PPP tiers — no custom logic. Family
sharing enabled (free). One entitlement, `multi_task`, granted by any of the three —
see `ProductID` in `KindlingCore`, which is where the mapping lives and is unit-tested.

## What is paid (§15, unchanged)

Free forever: the entire rescue flow at full quality, **one active task at a time**.
Nobody is ever blocked from getting unstuck on the thing they came for.

Paid: multiple concurrent parked tasks (the primary lever), Patterns, unlimited AI steps,
and later the home-screen widget and Watch app.

## Paywall placement (decided 2026-08-18)

1. **Organic trigger, unchanged from §15** — attempting to park a *second* task while one
   is still active. This stays the primary moment.
2. **Settings → Upgrade**, always visible. §15 already called for this, and it gives
   anyone who wants to pay a way to do so without waiting to be blocked.

Explicitly **not** added: any upgrade prompt during onboarding or mid-session. §14 and §15
forbid monetising that moment, and a deadline is not a reason to break it.

## Testing purchases locally

`ios/Kindling.storekit` holds the three products and is wired to the Debug scheme, so
purchase, restore, and entitlement paths run against StoreKit's local test environment —
no App Store Connect record, no sandbox Apple ID, no Paid Applications Agreement.

Use Xcode's **Debug → StoreKit** menu to force the states that are otherwise hard to
reach: failed transactions, Ask-to-Buy approval, subscription renewal, and refund. The
`Transaction.updates` listener is what handles all four, and it is the part of the
purchase path most likely to be wrong without anything looking wrong.

The product IDs in that file must stay identical to `ProductID` in `KindlingCore` and to
App Store Connect. A mismatch is invisible at build time and shows up only as an empty
paywall.

## Engineering sequence

- **5.1 StoreKit 2 plumbing — DONE (2026-08-18).** `EntitlementProviding`,
  `Entitlement.multiTask`, and `ProductID` live in `KindlingCore` with **zero
  dependencies**, so both `ActiveTaskPolicy` and the product → entitlement mapping stay
  testable without a store account; `StoreKitEntitlementStore` implements the protocol in
  the app target, with a lifetime `Transaction.updates` listener started from
  `KindlingApp`. Unverified, revoked, offline, cancelled, and unrecognised-product all
  resolve to "not entitled" — safe precisely because the free tier is complete, so the
  worst case is a paywall a paying user briefly sees, never someone locked out of getting
  unstuck. 67 tests; Debug and signed Release both build clean.
  *(This replaced the RevenueCat plumbing of the same date. No paywall UI existed yet, so
  nothing built was discarded.)*
- **5.2a Restore Purchases — DONE (2026-08-18).** Settings row calling `AppStore.sync()`
  and re-reading `Transaction.currentEntitlements`, with the three outcomes kept distinct.
  **"Nothing to restore" is not an error** (§13: no red, no alert box) — it is the correct
  answer for anyone who never purchased, which is most people who tap it. Always visible
  now: unlike the RevenueCat version there is no key that can be missing, so there is no
  state in which the control exists but cannot work.
- **5.2 Paywall UI** — built in the existing design system so it matches the Ember/warm-paper
  language. Three options, annual pre-selected, restore purchases, links to terms and
  privacy. Testable immediately against `Kindling.storekit`.
- **5.3 Second-task trigger** — the flow currently assumes one task; the paywall appears
  where that assumption is enforced.
- **5.4 TelemetryDeck + §18 events** — `second_task_attempted` is the single most
  important event: it is the direct read on whether the boundary lands.
- **5.5 Legal + store assets** — privacy policy (naming **TelemetryDeck and OpenAI** as
  the two processors; billing adds none, since Apple is not a third party here), terms, non-diagnostic disclaimer, App Store privacy labels re-answered
  against the AI toggle, five screenshots per §21, App Review notes explaining the
  non-medical positioning.
- **5.6 TestFlight → submit.**

## Known risks

- **Device testing is currently blocked.** The iPhone is on iOS 26.6; Xcode 26.6 supports
  26.5. See `implementation-status.md`. Purchase logic itself is no longer blocked by
  this — `Kindling.storekit` runs in the simulator — but final sandbox verification on
  hardware still is.
- **Two processors, not zero.** TelemetryDeck + OpenAI. Dropping RevenueCat removed the
  third; dropping the hosted AI tier (still open in `docs/ai-privacy-todo.md`) would
  remove another and make the legal review markedly simpler.
- **Analytics are now hand-built.** RevenueCat would have supplied MRR, churn, and trial
  conversion for free. 5.4 is what replaces it, so it is no longer a nice-to-have —
  without it there is no read on whether the §15 boundary lands.
- **App Review scrutiny on mental-health-adjacent positioning** (§20) is unchanged, and a
  rejection late in September would be fatal to the date. Hence the 15th submission target.
