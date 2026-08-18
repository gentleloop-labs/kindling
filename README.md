# Kindling

Kindling is a local-first task-initiation tool for the moment someone knows what they need to do and cannot start. It is an **iOS app, and only an iOS app** — Swift, SwiftUI, iOS 17+, with no cross-platform layer. Android is not planned, now or later.

**Current state:** the app is feature-complete through Phase 4 and simulator-verified. Remaining work is Phase 5 — paywall, analytics, legal, and store assets — tracked in `docs/release-plan.md` against a 2026-08-31 App Store submission.

## Repository

- `docs/kindling-full-plan.md` — product source of truth, §-numbered
- `IMPLEMENTATION.md` — phased engineering plan and the record of the decisions behind it
- `docs/implementation-status.md` — what is actually built, phase by phase
- `docs/release-plan.md` — the path to submission; authority for Phase 5
- `ios/` — the app. App target, widget extension, and the `KindlingCore` / `KindlingUI` local packages
- `proxy/` — Cloudflare Worker backing the optional hosted AI step tier
- `design/tokens.css` — canonical cross-surface design tokens
- `prototype/` — dependency-free validation flow
- `landing/` — Astro static site; serves the prototype at `/try/`
- `docs/validation-results.md` — the Phase 0 gate and evidence record

## Build and test the app

The Xcode project is generated, so edit `ios/project.yml` rather than the `.xcodeproj`:

```sh
cd ios
xcodegen generate
open Kindling.xcodeproj
```

The domain layer tests need no simulator and are the fast feedback loop:

```sh
cd ios/Packages/KindlingCore && swift test
```

Copy `ios/Config/Local.xcconfig.example` to `Local.xcconfig` (gitignored) to point the app at a deployed step Worker. Without it the app runs template-only and the AI toggle stays hidden.

Purchases run against `ios/Kindling.storekit` in Debug, so the paywall is testable with no App Store Connect setup. Use Xcode's **Debug → StoreKit** menu to force renewals, refunds, and Ask-to-Buy.

## Deploy the step proxy

Optional — the app falls back to on-device and template steps without it. See `proxy/README.md`.

## Run the prototype

Serve the repository with any static server and open `prototype/`. Add `?dev=1` to reveal a three-second timer fast-forward control.

```sh
npx serve .
```

The prototype has no dependencies and no build step. Its Research mode panel stores only whitelisted interaction events in local browser storage; task and first-step text are not included.

## Run the landing page

```sh
cd landing
cp .env.example .env
npm install
npm run dev
```

Set `PUBLIC_WAITLIST_FORM_ACTION` to a real hosted form endpoint before deploying. `npm run build` syncs the prototype to `landing/public/try/` and produces the static site in `landing/dist/`.

## Verify Phase 0

```sh
node --test prototype/tests/*.test.mjs
cd landing && npm run check && npm run build
```

Follow `docs/phase-0-runbook.md` for phone testing and evidence collection, and `docs/phase-0-validation-playbook.md` for the full recruitment, interview, and measurement process.

Note that the Phase 0 gate was **overridden by owner decision on 2026-08-17**, not satisfied — engineering began with the evidence still outstanding. `docs/validation-results.md` records that distinction deliberately; it should not be smoothed over.
