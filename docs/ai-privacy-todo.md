# AI steps — outstanding privacy and legal work

Status: **code shipped, disclosure incomplete.** Added 2026-08-17 alongside the
opt-in AI step layer (§12 v1.1, pulled forward from its planned v1.1 slot).

Until the items below are done, the "Smarter first steps" toggle should stay off
by default (it is) and should not be promoted in any store listing or marketing.

## What changed

There are now three tiers, tried in this order, and only the third sends anything:

1. **Template engine** (always available) — on-device, deterministic, offline.
2. **Apple Intelligence** (iPhone 15 Pro / iPhone 16 or later, iOS 26+) — on-device.
   Nothing leaves the phone. No key, no server, no cost, nothing to disclose.
3. **Cloudflare Worker → OpenAI** — only when the toggle is on, the device cannot
   run tier 2, and the build has an endpoint configured.

With the toggle **off**, nothing leaves the device at all.

With the toggle **on** and an Apple-Intelligence-capable phone, still nothing
leaves the device — tier 2 answers and tier 3 is never called. There is a test
asserting the hosted generator is not invoked when on-device succeeds.

With the toggle **on** and an older phone, the task title is sent to a Worker we
operate, which forwards it to OpenAI and returns one step. The Worker does not log
or store the text; Kindling does not store it off-device.

**So the disclosure has to be conditional, not blanket.** Saying "we send your
tasks to OpenAI" would be false for users on capable hardware; saying "nothing
ever leaves your device" would be false for everyone else. The Settings footer
already varies its wording by device — the policy needs to do the same.

## Measured behaviour (2026-08-17, M4 simulator + live Worker)

Latency, six real tasks each:

| Path | Latency | Notes |
|---|---|---|
| On-device, warm | 1.3-2.2s | Free, private, offline |
| On-device, first call after boot | ~5.8s | Model load; `prewarm()` on task entry mitigates |
| Worker -> OpenAI `gpt-5.2` (effort `low`) | 1.4-3.0s | 6/6 valid |
| Template | instant | Always the floor |

**On-device is placed first on evidence, not preference** — warm, it is faster than
the hosted call as well as free and private. Verified via `AiRequestLog`: when
on-device serves, `provider = on_device` and the hosted call is never made.

Model selection was measured, not assumed:
- `gpt-5.2` + `reasoning.effort: low` — chosen. `minimal`/`none` are rejected by
  this model with `unsupported_value`; default effort runs 1.8-7.5s.
- `gpt-5-nano` — rejected. Slower *and* only 2/6 responses held to the strict
  schema, even after the token-budget fix.
- `gpt-4o-mini` — fast but noticeably weaker steps.

`max_output_tokens` includes reasoning tokens on the gpt-5 series; the original 60
starved the answer entirely and produced empty responses. Now 2000.

## Outstanding

- [ ] **Privacy policy** — add OpenAI as a named sub-processor, and the Cloudflare
      Worker as the processing route. State what is sent (the task title only —
      not step history, not session data, not device identifiers), that it is not
      retained by us, and that the feature is opt-in and off by default.
      **State the tiering explicitly**: on capable devices the feature is fully
      on-device and no data is transmitted; the hosted path applies only where
      Apple Intelligence is unavailable.
- [ ] **Decide whether the hosted tier is worth keeping at all.** On-device alone
      needs no policy change, no sub-processor, no key, no server, and no ongoing
      cost — it just excludes older phones. Dropping tier 3 would close almost
      every item on this list. That is a product call, not an engineering one.
- [ ] **Confirm OpenAI's data-retention terms** for API traffic and state the
      actual retention period rather than implying none.
- [ ] **App Store privacy labels** — the current answers assume no data leaves the
      device. That is no longer true when the toggle is on; re-answer the
      questionnaire against the toggle's behaviour.
- [ ] **Legal review of the toggle's footer copy** in Settings. It is written to be
      honest and plain, but it is not lawyer-reviewed.
- [ ] **Decide whether an explicit first-use consent moment is needed** in addition
      to the Settings toggle. §14 deliberately allows only one permission ask in
      onboarding; adding a second prompt needs a decision, not a default.
- [ ] **Region/GDPR check** — ADHD-adjacent framing already brushes against
      health-app scrutiny in the EU/UK (§20); sending user-typed text to a US
      processor raises that further.

## Deliberately unchanged

- `AiRequestLog` still records only provider, latency, and success. There is no
  column for the prompt or the response, and a test asserts that stays true.
- The template engine remains the floor. Every AI failure path falls back to it,
  so turning the feature off — or losing connectivity — degrades quality, never
  function.
