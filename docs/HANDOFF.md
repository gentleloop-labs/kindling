# Kindling StoreKit launch handoff

Updated: 2026-08-26

## Objective

Complete Kindling's paid multi-task experience, hosted-AI consent, TelemetryDeck
funnel, and App Store submission for App Store Connect app `6805423597`.

Optimize for an internal-TestFlight-only launch path, then submit as soon as
purchase, hardware, privacy, and validation checks pass.

StoreKit 2 remains the billing system. RevenueCat stays out. Banking and tax are
complete. Deferred features include Patterns, Watch, additional widgets, custom
timers, and local export.

## Implementation

### Multi-task experience and paywall

- Add a non-session **Your tasks** sheet listing active and stepped-away tasks,
  most recently updated first.
- Allow users to resume a task, mark it done, discard it, or select **Start
  something else**. Hide this control during sessions.
- Count both `active` and `stepped_away` tasks toward the free limit. Completed
  and discarded tasks do not count.
- Before starting another task, emit `second_task_attempted` and call
  `ActiveTaskPolicy`. A free user with one parked task sees the paywall; an
  entitled user continues directly.
- After a successful purchase, continue automatically into the new task-entry
  flow. Marking the existing task done or discarded also releases the free slot.
- Fix flow reset semantics so a new title creates a new `AvoidedTask` instead of
  overwriting the previously selected task.
- Add **Settings → Upgrade**. Entitled users instead see **Kindling Plus —
  Active**, Restore Purchases, and subscription-management access.

Build a custom warm-paper paywall:

- Title: **Keep more than one task warm.**
- Body: **Kindling is free for one task at a time. Upgrade to park and return to
  as many as you need.**
- Show monthly, annual, and lifetime products using StoreKit-provided names and
  localized prices. Preselect annual.
- Show **Start 7-day free trial** only when StoreKit confirms introductory-offer
  eligibility. Otherwise use **Continue**. Lifetime uses **Unlock forever**.
- Include Restore Purchases, Terms, Privacy, close, loading, unavailable-product,
  pending, cancellation, and retry states.
- Replace the purchase `Bool` with `PurchaseOutcome`: `purchased`, `pending`,
  `cancelled`, and `failed`. Cancellation and Ask-to-Buy are not errors.

### Analytics and hosted AI

- Add an SDK-independent `AnalyticsEvent` taxonomy and `AnalyticsTracking`
  protocol. Implement it with TelemetryDeck in the app target and a no-op tracker
  for tests or unconfigured builds.
- Send only whitelisted values: duration bucket, outcome, generation origin,
  paywall source, and product period. Never send task or step text, task IDs,
  SwiftData IDs, or free-form errors.
- Instrument onboarding, task entry, first-step display, regeneration, session
  start/outcome, second-task attempt, paywall display, completed upgrade,
  notification permission, and notification open.
- Configure TelemetryDeck through xcconfig, use test mode for Debug, and do not
  provide a custom user identifier. Its July 2026 free allowance is 50,000 events
  per month, but App Privacy must still disclose analytics usage. See the
  [TelemetryDeck pricing update](https://telemetrydeck.com/blog/pricing-update-2026/)
  and [privacy guidance](https://telemetrydeck.com/docs/articles/apple-app-privacy/).
- Add a versioned `hostedAIConsent` preference. Exclude remote generation from
  the engine chain until consent is granted.
- Confirmation copy: **On this iPhone, smarter steps may send only the task title
  to Kindling's Cloudflare Worker and OpenAI. Kindling and the Worker do not store
  it. OpenAI may retain API content for abuse monitoring for up to 30 days. You
  can use on-device and template steps without this.**
- Actions: **Allow cloud fallback** and **Keep it on this iPhone**. Declining
  leaves on-device AI and templates available.
- Add `store: false` to the OpenAI Responses request. Disclose that default
  abuse-monitoring logs may still be retained for up to 30 days. See
  [OpenAI data controls](https://platform.openai.com/docs/models/default-usage-policies-by-endpoint).

## ASC-first release workflow

### 1. Build the app and review artifacts

- Implement and locally test the task shelf, paywall, analytics, and AI consent
  against `ios/Kindling.storekit`.
- Capture a clean paywall screenshot for subscription and IAP review.

### 2. Create the purchase catalog

- Use `asc subscriptions setup` to create group `Multi-task`, localized as
  **Kindling Plus**.
- Create monthly `dev.aftaab.kindling.multitask.monthly` at US $3.99 and annual
  `dev.aftaab.kindling.multitask.annual` at US $19.99.
- Use `asc iap setup` for Family-Shareable lifetime
  `dev.aftaab.kindling.multitask.lifetime` at US $44.99.
- Enable Family Sharing, all current territories, automatic availability in new
  territories, and Apple's equalized regional pricing.
- Create version-scoped product/group localizations from the existing StoreKit
  copy and import a one-week free trial for both subscriptions across all
  supported territories.
- Upload the review image, then require strict `asc validate subscriptions` and
  `asc validate iap` reports with no warnings, missing metadata, incomplete
  pricing, or image failures.

### 3. Complete app information and legal work

- Pull canonical metadata with `asc metadata pull`; commit `./metadata` as the
  source of truth.
- Set primary category `PRODUCTIVITY`, no secondary category, no third-party
  content, worldwide availability, and copyright `2026 Gentleloop Labs` unless
  the App Store Connect legal owner requires a different string.
- Use subtitle **A tiny nudge when you're stuck** and URLs under
  `https://kindling.maskedsyntax.com`: `/support/`, `/privacy/`, and `/terms/`.
- Replace validation-era legal pages with launch policies naming TelemetryDeck,
  Cloudflare, and OpenAI. Include the non-medical disclaimer and obtain legal
  review.
- Complete age rating with all objectionable-content fields at none/false,
  `healthOrWellnessTopics=true`, and `medicalTreatment=NONE`.
- Run `asc metadata validate`, create durable plan/approval artifacts, preview
  with a dry run, and apply the reviewed metadata.
- Use `asc web privacy pull/plan/apply/publish`. Declare:
  - Device ID and Product Interaction: analytics, not linked, not tracking.
  - Other User Content: app functionality, not linked, not tracking, covering
    opted-in hosted task titles.
  - No purchase data collected by Kindling outside Apple's StoreKit handling.

### 4. Produce screenshots and upload a build

- Add deterministic debug seeds for the five required scenes: welcome, first
  step, timer, equal-weight outcome, and Live Activity.
- Use the ASC screenshot pipeline to capture on an iPhone 17 Pro simulator,
  frame, generate a review report, approve, validate for `IPHONE_65`, and upload
  through `asc screenshots plan/apply`.
- Use `asc xcode version edit` for the next remote-safe build number, then
  `asc xcode archive`, export, and `asc builds upload --wait`.
- Resolve encryption as exempt standard HTTPS/TLS and verify that the processed
  build is `VALID`.

### 5. Run internal TestFlight and submit

- Create an **Internal QA** group, attach the build, and add What to Test notes
  covering paywall triggers, trials, purchase, restore, Ask-to-Buy, refund, task
  switching, AI consent, force-quit resume, Live Activity, and VoiceOver.
- Test on simulator and the connected physical iPhone. Confirm no duplicate Live
  Activities, no task text in notifications/analytics/logs, and correct
  entitlement changes after renewal or refund.
- Run `asc validate --strict`, both product validators, App Privacy publish
  verification, and `asc review doctor`.
- Dry-run `asc review submit`. Include the app version, both subscription
  versions, subscription-group version, and lifetime-IAP version in the first
  review submission, then submit with explicit confirmation.

## Test and acceptance plan

- Unit-test task counting, new-task reset, selection/resume, done/discard slot
  release, free gating, and entitled unlimited tasks.
- Test every purchase outcome, missing products, offline loading, cancellation,
  pending approval, refund/revocation, restore, trial eligibility, and lifetime
  entitlement.
- Verify hosted requests are impossible without consent and that `store: false`
  is sent. Declining consent must always fall back locally.
- Assert analytics accepts only enumerated events and parameters and exposes no
  API capable of accepting task or step text.
- UI-test Dynamic Type, VoiceOver, Reduce Motion, dark mode, task-sheet actions,
  paywall legal links, and every screenshot seed.
- Acceptance gate: all local tests pass, ASC product validators are clean, the
  build is `VALID`, App Privacy is published, strict app validation has zero
  blockers, and internal purchase/hardware checks pass.

## Locked decisions and required inputs

- StoreKit 2, hosted OpenAI fallback, TelemetryDeck, a minimal task picker,
  one-time hosted-AI consent, and ASAP submission are locked.
- The user must create or expose a TelemetryDeck app ID through local
  configuration; it is not available through ASC.
- App Review contact phone/email and the final copyright legal owner must be
  supplied securely during execution.
- The hosted Worker and production token remain enabled. Preserve its task-free
  logs and rate limiting.
