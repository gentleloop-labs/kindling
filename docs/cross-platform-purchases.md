# Carrying a purchase between iOS and Android

Created 2026-08-18. A staged plan, deliberately sequenced so **nothing is built until
there is evidence anyone needs it.**

## The problem, in one paragraph

Apple records purchases against an Apple ID; Google records them against a Google
account; the two never talk. Someone who buys on iPhone and later installs the Android
build looks, to Google, like a brand-new user who has never paid. RevenueCat can bridge
this — it keeps its own record of who owns what — but only if it can tell the two
installs belong to the same person, which means giving it a stable app user ID.

## What is needed for the iOS release: nothing

On iOS alone this problem does not exist. Apple restores purchases automatically and
forever, against the buyer's Apple ID, with no account and no code. **§7's "no accounts"
is not a compromise on iOS — it is simply correct.** Ship 2026-08-31 with no work here.

## Who this actually affects

Only people who bought on one platform, *also* use the other, *and* want it on both. Per
§15's own projection, 1,000 installs yields roughly **30-60 paying users**; the slice
crossing platforms is a handful in the first year.

That number is the whole argument for the staging below. Building an auth system for a
few people, before knowing whether those people exist, is the kind of speculative work
§4's anti-creep principles exist to prevent.

## Stage 1 — DONE 2026-08-18

**Restore Purchases** ships in the iOS release. This was initially scoped as "do nothing",
which was wrong: restore is needed for any app selling subscriptions, so a returning user
who reinstalls can get their purchase back. It has nothing to do with Android — it just
happens to be the row the Stage 2 line will attach to.

- Settings → "Restore purchases", calling `RevenueCatEntitlementStore.restore()`.
- Three distinct outcomes. **"Nothing to restore" is not an error** — it is the correct
  answer for anyone who never bought, which is most people who tap it. §13 copy: no red,
  no alert box.
- The whole section is hidden when RevenueCat is not configured, matching the AI toggle.
  Verified in both states.

One further decision, made now because it is free: when RevenueCat is configured,
leave app user IDs **anonymous**. RevenueCat's `logIn` can later fold an anonymous user
into a named one, so no September buyer is stranded by a later change. This was
previously written up as needing a self-generated install ID up front; that was
overstated — aliasing covers it.

## Stage 2 — at Android launch (~Oct-Nov 2026)

Add **one line in Settings**, on both platforms:

> Bought Kindling on another device? Get in touch and we'll restore it.

...linking to a support email. When someone writes in, grant the entitlement by hand in
the RevenueCat dashboard. Thirty seconds per request, zero engineering, cannot break.

**This is instrumentation as much as support.** Every email is a data point on whether
the automated version is worth building. Log the count.

### Runbook (for when the first email arrives)
1. Ask which store they purchased on, and the approximate date.
2. Find the customer in RevenueCat (search by transaction or store).
3. Grant the `multi_task` entitlement to their other-platform user ID.
4. Record the request in a running tally.

## Stage 3 — only if Stage 2 generates real volume

**Trigger: roughly ten requests in a month**, or support becoming a nuisance. Below that,
manual handling remains cheaper than any code you could write.

**The approach is already chosen: sign-in, not a restore code.** Decided 2026-08-18 after
working through the sharing question. What is *not* decided is whether to build it at all —
that still waits on Stage 2 evidence.

**Rollout, when it happens:** incrementally across several releases rather than one drop —
the identifier plumbing first, then the sign-in entry point, then anything that depends on
it. Confirmed 2026-08-18. Nothing here is urgent enough to justify a big-bang change to the
purchase path, which is the one part of the app where a regression costs real money.

### Why not the restore code

A shared code makes everyone who types it **literally the same RevenueCat customer**.
`logIn("KIND-7F3A")` resolves against RevenueCat's own backend and grants the entitlement
regardless of what the device's store account ever bought — which is exactly what makes it
work cross-platform, and exactly what makes it shareable without limit.

RevenueCat's [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
setting does **not** help here. Its default, *Transfer to New App User ID*, revokes access
from the previous user when a purchase moves between **different** app user IDs — so only
one customer holds it at a time. A shared code means there is no different ID, so no
transfer occurs and nothing is prevented. Capping redemptions would need a backend, which
is the thing the code design existed to avoid.

Sign-in does not have this hole: different people get different app user IDs, so the
default transfer behaviour applies and the entitlement moves rather than duplicates.
People also guard an Apple ID far more carefully than a code they would paste into a chat.

| | Restore code | Sign-in |
|---|---|---|
| Recoverable if lost | No | Yes |
| Resists sharing | **No — unlimited** | Yes, via transfer behaviour |
| Build cost | ~1 day | ~2-3 days |
| Extra App Store obligations | none | in-app account deletion |

The code wins only on build cost and loses on both things that matter over time. An earlier
version of this document presented the two as roughly even; that was under-analysed.

### Detail, for whenever it is built

| | Restore code | Sign in with Apple / Google |
|---|---|---|
| Build cost | ~1 day | ~2-3 days |
| Dependencies | none | Google SDK (Apple's is native) |
| Backend | none | none, if the provider's user ID is used directly as the RevenueCat app user ID |
| Recoverable if lost | **No** — this is its real weakness | Yes, the provider remembers |
| App Store obligations | none | must offer in-app **account deletion**; offering Google requires an equivalent privacy-preserving option alongside |
| §7 "no accounts" | intact | intact *only if* strictly optional and purchase-scoped |


- **Optional and purchase-scoped only.** Reachable from Settings, never during
  onboarding, never a gate on the rescue flow. §3 lists required accounts as a leading
  competitor complaint; a login on the path to getting unstuck would make Kindling the
  thing it positions against.
- Use the provider's stable user identifier as the RevenueCat app user ID.
- Note the trust boundary: without server-side token verification the client is trusted.
  The IDs are long and opaque so guessing one is impractical, but the hole is real, and
  closing it properly needs a backend — which nothing else here requires.
- Budget for the account-deletion requirement; reviewers check it.

## What not to do

- Do not gate the rescue flow behind sign-in, ever, under any deadline.
- Do not build Stage 3 before Stage 2 has produced evidence.
- Do not add a backend for this. Nothing here needs one.
