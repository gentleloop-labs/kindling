# Release plan — App Store submission by 2026-08-31

Created 2026-08-18, revised the same day. Supersedes the two-day sprint plan, which
targeted a working v1 rather than a shipped product.

**The date is 08-31, not Shipaton's 09-30.** The 08-31 submission target was chosen
independently and is earlier, so it governs. Shipaton's release window (08-01 to 09-30)
already contains it, which means entering costs nothing extra — but it is not driving
the schedule and must not be allowed to loosen it.

## The goal changed, so the shape of the work changed

| | Sprint plan (to 08-19) | This plan (to 08-31) |
|---|---|---|
| Deliverable | Working v1 on a device | **Publicly released app on the App Store** |
| Billing | Explicitly out of scope | **Required** — RevenueCat SDK powering a real purchase |
| Privacy/legal | Deferred | **Blocking** — cannot ship without it |
| Store assets | Deferred | **Blocking** |

Shipaton's eligibility rules: the app must use the **RevenueCat SDK to power at least
one in-app purchase**, and its **first public release must fall between 2026-08-01 and
2026-09-30**. Kindling has never been released, so shipping on 08-31 satisfies both —
but it must actually reach the App Store, not TestFlight.

RevenueCat is being used on its own merits (cross-platform entitlements for the intended
Android build, plus subscription analytics — see `IMPLEMENTATION.md` Phase 5), not for
eligibility. Eligibility is a by-product.

## What is already done

Phases 0–4 are complete and verified: the rescue flow, SwiftData in an App Group, the
tested domain core, Live Activity, accessibility, and the AI step layer (on-device →
hosted → template). 64 tests; Debug and signed Release both build clean.

**`ActiveTaskPolicy` already encodes the paywall boundary** and is unit-tested. The
entitlement check has a single home; RevenueCat feeds it rather than replacing it.

## Critical path — start the slow things first

These have **external latency** and are the real risk to the date. Nothing about the
code is on the critical path; these are.

Dates below target **submission on 08-31**, with App Review after that.

| # | Item | Owner | Blocks | Start by |
|---|---|---|---|---|
| 1 | **Paid Applications Agreement**, banking + tax forms in App Store Connect | You | *All* purchases. Products cannot be sold — or reliably tested — until Apple accepts these | **Immediately** |
| 2 | App Store Connect app record + bundle ID `dev.aftaab.kindling` | You | Products, TestFlight, submission | Immediately |
| 3 | RevenueCat account, project, public SDK key | You | Every line of purchase code below | Immediately |
| 4 | Products created in App Store Connect **and** mapped in RevenueCat | You + me | Paywall testing | Within days of 1–3 |
| 5 | Privacy policy + terms, reviewed by an actual lawyer | You | App Store submission | **Early September at the latest** |
| 6 | App Store review | Apple | Public release | Submit by **~2026-09-15** to leave buffer for a rejection |

> Item 1 is the classic silent blocker: everything looks fine until purchases fail in
> sandbox with no clear reason. Do it first.

## Products (§15, unchanged)

| Product | Type | Price |
|---|---|---|
| Monthly | auto-renewing subscription | $3.99 |
| **Annual (default)** | auto-renewing subscription | **$19.99/yr** |
| Lifetime | non-consumable | $44.99 |

7-day trial. Regional pricing via Apple's built-in PPP tiers — no custom logic. Family
sharing enabled (free). One RevenueCat entitlement, `multi_task`, granted by any of the
three.

## What is paid (§15, unchanged)

Free forever: the entire rescue flow at full quality, **one active task at a time**.
Nobody is ever blocked from getting unstuck on the thing they came for.

Paid: multiple concurrent parked tasks (the primary lever), Patterns, unlimited AI steps,
and later the home-screen widget and Watch app.

## Paywall placement (decided 2026-08-18)

1. **Organic trigger, unchanged from §15** — attempting to park a *second* task while one
   is still active. This stays the primary moment.
2. **Settings → Upgrade**, always visible. §15 already called for this; it also means a
   Shipaton judge reaches a real purchase flow in two taps without weakening the design.

Explicitly **not** added: any upgrade prompt during onboarding or mid-session. §14 and §15
forbid monetising that moment, and a hackathon deadline is not a reason to break it.

## Build gotcha (hit 2026-08-18)

`xcodebuild -resolvePackageDependencies` fails to clone RevenueCat with the default
package cache — "Failed to clone repository". Pass an explicit path:

```sh
xcodebuild ... -clonedSourcePackagesDirPath <writable-dir> ...
```

`git ls-remote` against the same repo works fine, so this is the cache location, not
network or auth. Xcode.app itself resolves normally.

## Engineering sequence

- **5.1 RevenueCat plumbing — DONE (2026-08-18).** SDK added via SPM (resolves to
  5.83.x), configured from `KINDLING_REVENUECAT_KEY` in the gitignored `Local.xcconfig`.
  `EntitlementProviding` + `Entitlement.multiTask` live in `KindlingCore` with **zero
  dependencies**, so `ActiveTaskPolicy` stays testable without a store account;
  `RevenueCatEntitlementStore` implements it in the app target. Offline, cancelled, and
  not-configured all resolve to "not entitled" — safe precisely because the free tier is
  complete, so the worst case is a paywall a paying user briefly sees, never someone
  locked out of getting unstuck. Builds clean; awaiting a real key and products to test.
- **5.2a Restore Purchases — DONE (2026-08-18).** Settings row calling the existing
  `restore()`, with the three outcomes distinguished. See `docs/cross-platform-purchases.md`.
- **5.2 Paywall UI** — built in the existing design system, not RevenueCat's templates, so
  it matches the Ember/warm-paper language. Three options, annual pre-selected, restore
  purchases, links to terms and privacy.
- **5.3 Second-task trigger** — the flow currently assumes one task; the paywall appears
  where that assumption is enforced.
- **5.4 TelemetryDeck + §18 events** — `second_task_attempted` is the single most
  important event: it is the direct read on whether the boundary lands.
- **5.5 Legal + store assets** — privacy policy (now naming RevenueCat *and* OpenAI as
  processors), terms, non-diagnostic disclaimer, App Store privacy labels re-answered
  against the AI toggle, five screenshots per §21, App Review notes explaining the
  non-medical positioning.
- **5.6 TestFlight → submit.**

## Known risks

- **Device testing is currently blocked.** The iPhone is on iOS 26.6; Xcode 26.6 supports
  26.5. Sandbox purchase testing wants a real device, so this needs resolving — see
  `implementation-status.md`.
- **Two processors now, not zero.** The replan had hoped to ship with a short processor
  list. It is now TelemetryDeck + RevenueCat + OpenAI. That makes item 5 heavier.
- **App Review scrutiny on mental-health-adjacent positioning** (§20) is unchanged, and a
  rejection late in September would be fatal to the date. Hence the 15th submission target.
