# Phase 0 validation runbook

## Deploy

1. Create a hosted form in Buttondown, Formspark, or an equivalent provider.
2. Set `PUBLIC_WAITLIST_FORM_ACTION` to the provider's HTTPS submission endpoint.
3. Optionally set `PUBLIC_ANALYTICS_ENDPOINT` to a first-party endpoint that accepts the privacy-safe event envelope. Without it, events remain in the browser's local buffer and can be copied out during research.
4. Run `npm install` and `npm run build` from `landing/`.
5. Deploy `landing/dist/` to Cloudflare Pages or Netlify and map `kindling.maskedsyntax.com`.

The build syncs the no-build prototype into `landing/public/try/`, so `/try/` is included in the same static deployment.

## Test on a phone

- Complete all seven screens using a real task and the sample chip.
- Complete one natural two-minute timer and one `?dev=1` fast-forward session.
- Try all three outcomes; confirm they have equal visual weight.
- Reload during the timer; a validation prototype may restart, but no event payload may expose task or step text.
- Enable reduced motion and dark mode.
- Export the local event buffer and search for the typed task. It must not appear.
- Submit a test waitlist address and confirm it appears in the hosted provider.

## Analyze an exported prototype event file

Run:

```sh
node scripts/analyze-events.mjs path/to/events.json
```

Copy the resulting aggregate metrics into `docs/validation-results.md`; do not commit raw participant-level event exports.
