# Kindling memory pivot — release readiness

Updated September 16, 2026. Target submission: December 7, 2026.

## Implemented

- The rejected task-starter product was tagged as `task-starter-final`; development continues on `codex/memory-pivot`.
- The iOS shell is Atlas, Memories, and Settings. No task flow, widget target, Live Activity, timer, AI proxy, or task model remains in the binary.
- `KindlingMemory.store` uses the versioned ten-entity memory schema. The previous App Group store is never migrated and can only be deleted through an explicit Settings action.
- Selected-only Photos import creates orientation-corrected image renditions, bounded 1080p video proxies, poster frames, incremental persisted ownership, deterministic clustering, opportunistic place labels, cancellation cleanup, interrupted-import rollback, and resumable review drafts.
- The complete loop is implemented: onboarding, bundled sample, import, autosaved review, cover/title/date edits, merge/split/reorder/remove, Atlas, Memories, Trail, map/list alternative, editing, and deletion.
- Local notes, Sparks, return intent, voice notes, private tags, search, filters, sensitive/hidden/do-not-resurface controls, storage reporting, and previous-data deletion are implemented.
- Static postcards and map cards have an exact privacy preview, place/pin controls, sharing, local resurfacing rules, notifications, quiet hours, and exclusion controls.
- Kindling Pro gates the third saved personal trip and adds unlimited trips, premium themes, branding controls, and expanded resurfacing controls. The first completed trail is never paywalled.
- The privacy manifest, local StoreKit configuration, content-free analytics allowlist, landing site, policies, metadata, review notes, sample media, and five iPhone screenshots are memory-product specific.

## Automated evidence

- `swift test`: 16 tests across schema, clustering, policies, analytics, and legacy-data behavior pass.
- Xcode UI tests: onboarding/sample path, Atlas sample, and Memories sample pass on iPhone 17 Pro Max simulator.
- Debug and Release simulator builds pass with iOS 17 as the deployment target.
- The 500-item deterministic clustering test completes inside the ten-second budget.
- `PrivacyInfo.xcprivacy` passes `plutil` validation.
- Landing site: Astro check reports zero errors/warnings/hints and the static production build succeeds.
- App Store screenshots validate at 1242×2688 and all five uploaded assets report `COMPLETE`.
- App Store catalog validators report zero errors and zero blockers for subscriptions and in-app purchases.

## App Store Connect state

- App record and bundle identifier are retained. The editable version remains unsubmitted.
- Public name, subtitle, promotional text, description, and keywords describe the travel-memory product.
- Primary category is Travel; secondary category is Photo & Video.
- Kindling Pro group/products exist at $4.99 monthly, $29.99 annually with a seven-day trial, and $59.99 lifetime. All are `READY_TO_SUBMIT` and excluded from the current submission until the release candidate is ready.
- The previous task products remain unreferenced by the binary and are not attached to review. App Store Connect does not permit removing an unapproved product in every state.
- Build 14 (`1.0.0`) was uploaded on September 16, 2026 and is `IN_BETA_TESTING` for the internal TestFlight group. Build 13 remains the rejected task-era build attached to the App Store version and must be replaced by the final release candidate before submission.

## External release gates still required

These cannot be truthfully completed by source changes or simulator automation:

1. TestFlight with at least 12 people across small, medium, and large libraries; limited selection; iCloud-only items; multiple countries/time zones; and older supported hardware.
2. Manual VoiceOver, Dynamic Type, Reduce Motion, increased-contrast, real-device storage, notification, microphone, Photos picker, and purchase-state audits.
3. Promote a tested build (or upload a later release candidate) and attach it to App Store version 1.0.
4. Final deep submission validation, attachment of the three new Pro products, and submission on or after December 7, 2026.

Do not submit the currently attached build 13.
