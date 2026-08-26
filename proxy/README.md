# Kindling step proxy

A Cloudflare Worker that turns an avoided-task title into one small first step.

Its whole reason to exist is that **an iOS app cannot hold an API key safely** —
anything in the binary can be extracted from it. The OpenAI key lives here.

## Do you even need this?

Kindling tries **Apple Intelligence on-device first**. On an iPhone 15 Pro or later
running iOS 26+, this Worker is never called — the step is generated on the phone,
free, offline, and with nothing to disclose. This Worker exists to serve everyone
on older hardware. If you decide that audience can live with template steps, you
can skip deploying it entirely and the app still works.

## Deploy

```sh
# 0. Get an OpenAI API key: https://platform.openai.com/api-keys
#    Add a little credit at https://platform.openai.com/settings/organization/billing
#    and set a low monthly usage cap while testing.
cd proxy
npx wrangler login
npx wrangler secret put OPENAI_API_KEY   # paste your OpenAI key
npx wrangler secret put APP_TOKEN        # any long random string: openssl rand -hex 32
npx wrangler deploy
```

Then put the deployed host and the same `APP_TOKEN` into `ios/Config/Base.xcconfig`:

```
KINDLING_STEP_HOST = kindling-step.maskedsyntax.workers.dev
KINDLING_APP_TOKEN = <the APP_TOKEN you just set>
```

Note the host is stored **without** a scheme — `xcconfig` treats `//` as a comment,
so `https://` is added in Swift. Until both values are set, the app is local-only
and the "Smarter first steps" toggle is hidden rather than shown broken.

## Changing the model

`MODEL` is a plain var in `wrangler.toml`. Edit it and `npx wrangler deploy` —
no Xcode change, no App Store review.

## Privacy

The task title is the most sensitive thing Kindling handles. In this Worker it is
forwarded to OpenAI and then dropped: never logged or stored by Kindling or the
Worker, and never echoed in an error response. The Responses request sets
`store: false`, but OpenAI's default abuse-monitoring logs may still retain API
content for up to 30 days. Every `console.log` is content-free by design — check
that any line you add keeps that true, and note that an upstream error body can
contain the prompt, which is why only the status code is logged.

**This changes Kindling's privacy posture, and the policy has to say so.** With
the toggle on, task text leaves the device and OpenAI becomes a data processor.
See `docs/ai-privacy-todo.md`.

## What protects the endpoint

- **`APP_TOKEN`** — checked on every request. It ships in the app, so treat it as
  *rotatable*, not secret: its value is that you can revoke and replace it
  server-side in seconds, without an app update.
- **Per-IP rate limit** — 20 requests/minute (`wrangler.toml`). Raise it if real
  users hit it; the point is to stop a scraped token becoming a free LLM.
- **200-character task cap** — a task title is a phrase. Longer input is either a
  bug or someone using this as a general-purpose model.

If the token leaks and gets abused, rotate it (`wrangler secret put APP_TOKEN`,
update the xcconfig, ship) and consider per-install tokens issued at first launch.

## Local development

```sh
cp .dev.vars.example .dev.vars   # then edit in a real OPENAI_API_KEY
npx wrangler dev
```

`compatibility_date` is pinned to a date the installed `workerd` supports. Setting
it to "today" makes `wrangler dev` refuse to start ("newest date supported by this
server binary is ...") even though `wrangler deploy` accepts it — bump it
deliberately, after upgrading wrangler.

**The app cannot talk to `wrangler dev` directly.** `StepEngineFactory` hard-codes
`https://`, because `xcconfig` treats `//` as a comment so the scheme cannot live
there. Test the Worker with `curl` (below) and the app against a deployed Worker.

## Testing without the app

```sh
curl -s https://kindling-step.maskedsyntax.workers.dev/ \
  -H "authorization: Bearer $APP_TOKEN" \
  -H "content-type: application/json" \
  -d '{"task":"talking to a friend","attempt":0}'
```
