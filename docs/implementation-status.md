# Implementation status

Updated: 2026-08-10

## Phase 0 — Validation

State: **engineering assets complete; live validation pending**

| Item | State | Evidence / next action |
|---|---|---|
| 0.1 Design tokens + WCAG | Complete | `design/tokens.css` and `docs/design-tokens.md`; light accent corrected for interactive use |
| 0.2 Clickable prototype | Complete | Seven-screen no-build flow in `prototype/`; real timer, dev fast-forward, deterministic step rules, private local event export |
| 0.3 Astro landing page | Code complete | Landing, `/try/`, `/privacy/`, and `/terms/` build successfully |
| Hosted waitlist | Pending external setup | Create provider form and set `PUBLIC_WAITLIST_FORM_ACTION` |
| Deploy + custom subdomain | Pending external setup | Deploy `landing/dist/` and map `kindling.maskedsyntax.com` |
| 0.4 Measurement | Pending participants | Collect landing traffic, 5–8 interviews, and 3–5 prototype sessions |
| Gate decision | Pending | Record `GO`, `REDIRECT`, or `STOP` in `docs/validation-results.md` |

Automated verification at this checkpoint:

- Prototype contract, privacy, and 20-case step-engine tests: passing.
- Astro diagnostics: 0 errors, 0 warnings, 0 hints.
- Static production build: passing.
- Served route checks: `/`, `/try/`, `/privacy/`, `/terms/`, and prototype assets return successfully.
- Visual browser walkthrough: pending because no browser runtime was connected in the implementation workspace; follow the real-phone checklist in `docs/phase-0-runbook.md`.

## Phase 1 — Technical foundation

State: **not started — intentionally gated**

Do not create `app/` until Phase 0 has real results and `docs/validation-results.md` records a decision. If the decision is `REDIRECT`, update `IMPLEMENTATION.md` before scaffolding native code.

## Phases 2–6

State: not started; depend on Phase 1 and the validation decision.
