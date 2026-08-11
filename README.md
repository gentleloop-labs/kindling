# Kindling

Kindling is a local-first task-initiation tool for the moment someone knows what they need to do and cannot start. The current repository milestone is Phase 0 validation: a landing page, a seven-screen clickable prototype, and a documented evidence gate before native app engineering.

## Repository

- `docs/kindling-full-plan.md` — product source of truth
- `IMPLEMENTATION.md` — phased engineering plan
- `design/tokens.css` — canonical cross-surface design tokens
- `prototype/` — dependency-free validation flow
- `landing/` — Astro static site; serves the prototype at `/try/`
- `docs/validation-results.md` — Phase 1 gate and evidence record

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

Follow `docs/phase-0-runbook.md` for phone testing and evidence collection. Do not begin Phase 1 until `docs/validation-results.md` contains an explicit decision.
