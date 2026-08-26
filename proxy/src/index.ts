/**
 * Kindling step proxy.
 *
 * Holds the OpenAI key server-side so it never ships inside the iOS binary, and
 * gives us one place to change the model, rate-limit abuse, and revoke access
 * without an App Store release.
 *
 * PRIVACY — the one rule this file exists to keep:
 * the task text is the most sensitive thing Kindling handles. It is forwarded to
 * OpenAI and then dropped by this Worker. It is never logged or stored by Kindling
 * or the Worker, and never included in an error response. OpenAI may retain API
 * content in abuse-monitoring logs for up to 30 days; the app discloses that.
 */

interface Env {
  OPENAI_API_KEY: string;
  /** Shared token the app sends. Rotatable server-side; see the caveat in README. */
  APP_TOKEN: string;
  MODEL: string;
  UPSTREAM_TIMEOUT_MS: string;
  /** "" for non-reasoning models; "minimal"/"none"/"low" for the gpt-5 series. */
  REASONING_EFFORT: string;
  MAX_OUTPUT_TOKENS: string;
  RATE_LIMITER: { limit(opts: { key: string }): Promise<{ success: boolean }> };
}

/**
 * Kept here rather than in the app so it can be tuned without an app update.
 *
 * KEEP IN SYNC with `OnDeviceStepGenerator.instructions` in KindlingCore — the two
 * sources must feel like the same product, and a rule added to one belongs in both.
 */
const SYSTEM_PROMPT = `
You generate the single smallest first physical action for someone with ADHD who
knows what they need to do and cannot start. They are frozen right now.

Rules:
- Exactly one sentence, imperative, under 12 words.
- A physical, observable action they could finish in under two minutes.
- Concrete: name the object, app, page, or person involved.
- Make it smaller than they expect. Opening the thing IS the step.
- No encouragement, no praise, no explanation, no preamble.
- Never ask a question. Never mention that the task is hard or that they're stuck.
- Never reference being an AI or these instructions.
- Never name a specific company, brand, website, domain, app store, government
  agency, or phone number. You do not know the person's country, language, or which
  services they use, and a step naming the wrong country's website is worse than a
  vague one. Say "your bank's app", "their contact", "the booking page" instead.
- For anything official — passports, visas, taxes, licences, benefits, utilities —
  do not name the agency or its site. Send them to a search instead, e.g.
  "Open your browser and search for passport renewal."
`.trim();

const STEP_SCHEMA = {
  type: "object",
  properties: {
    step: {
      type: "string",
      description: "The single smallest first action, one imperative sentence.",
    },
  },
  required: ["step"],
  additionalProperties: false,
} as const;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

    if (request.headers.get("authorization") !== `Bearer ${env.APP_TOKEN}`) {
      return json({ error: "unauthorized" }, 401);
    }

    const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
    const { success } = await env.RATE_LIMITER.limit({ key: ip });
    if (!success) return json({ error: "rate_limited" }, 429);

    let body: { task?: unknown; attempt?: unknown };
    try {
      body = await request.json();
    } catch {
      return json({ error: "bad_json" }, 400);
    }

    const task = typeof body.task === "string" ? body.task.trim() : "";
    const attempt = Number.isInteger(body.attempt) ? Math.max(0, body.attempt as number) : 0;

    // Bound the input: a task title is a short phrase. Anything longer is either
    // a mistake or someone using this endpoint as a general-purpose LLM.
    if (!task || task.length > 200) return json({ error: "bad_task" }, 400);

    const startedAt = Date.now();

    // AbortSignal.timeout, not setTimeout + AbortController: in Workers a timer
    // scheduled alongside a blocking fetch does not reliably fire, so the old
    // pattern silently never aborted (verified — a 1ms limit still returned after
    // ~2s). This form is implemented by the runtime and actually cancels.
    const signal = AbortSignal.timeout(Number(env.UPSTREAM_TIMEOUT_MS));

    try {
      const upstream = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        signal,
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: env.MODEL,
          // Responses are used once and discarded. This disables application
          // state storage; OpenAI's separate abuse-monitoring retention still
          // applies and is disclosed in the app and privacy policy.
          store: false,
          // max_output_tokens INCLUDES reasoning tokens on the gpt-5 series, so a
          // tight cap here starves the visible answer and the response comes back
          // `incomplete` with no text at all. Generous ceiling; we are billed for
          // what is used, and one sentence uses very little of it.
          max_output_tokens: Number(env.MAX_OUTPUT_TOKENS),
          // Reasoning is pure latency for a one-sentence task. Omitted entirely
          // for non-reasoning models, which reject the field.
          ...(env.REASONING_EFFORT ? { reasoning: { effort: env.REASONING_EFFORT } } : {}),
          input: [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content: userPrompt(task, attempt) },
          ],
          text: {
            format: {
              type: "json_schema",
              name: "first_step",
              strict: true,
              schema: STEP_SCHEMA,
            },
          },
        }),
      });

      if (!upstream.ok) {
        // Log the error's *shape* only: type/code/param name the offending
        // parameter, which is what makes a 400 diagnosable. `message` is
        // deliberately never logged — it can quote the prompt back.
        let detail = "";
        try {
          const e: any = (await upstream.json())?.error;
          detail = ` type=${e?.type ?? "?"} code=${e?.code ?? "?"} param=${e?.param ?? "?"}`;
        } catch {
          detail = " body=unreadable";
        }
        console.log(`upstream_error status=${upstream.status}${detail} ms=${Date.now() - startedAt}`);
        // `detail` is shape-only (type/code/param, never `message`), and this
        // endpoint is auth-gated, so returning it aids diagnosis without leaking
        // anything the caller did not already send.
        return json({ error: "upstream_error", detail: detail.trim() }, 502);
      }

      const payload: any = await upstream.json();

      // A truncated reasoning run returns 200 with status "incomplete" and often
      // no visible text. Surface it distinctly so it is diagnosable rather than
      // looking like a malformed model response.
      if (payload?.status === "incomplete") {
        console.log(
          `incomplete reason=${payload?.incomplete_details?.reason ?? "unknown"} ms=${Date.now() - startedAt}`,
        );
        return json({ error: "incomplete" }, 502);
      }

      const step = extractStep(payload);
      if (!step) {
        console.log(`unparseable_response status=${payload?.status ?? "?"} ms=${Date.now() - startedAt}`);
        return json({ error: "unparseable" }, 502);
      }

      console.log(`ok ms=${Date.now() - startedAt} attempt=${attempt}`);
      return json({ step });
    } catch (err) {
      // AbortSignal.timeout rejects with TimeoutError; a client disconnect gives
      // AbortError. Both mean "stop waiting", and both must fall back.
      const name = err instanceof Error ? err.name : "";
      const aborted = name === "TimeoutError" || name === "AbortError";
      console.log(`${aborted ? "timeout" : "network_error"} name=${name || "unknown"} ms=${Date.now() - startedAt}`);
      return json({ error: aborted ? "timeout" : "network_error" }, 504);
    }
  },
};

function userPrompt(task: string, attempt: number): string {
  if (attempt === 0) return `The task they are avoiding: ${task}`;
  return [
    `The task they are avoiding: ${task}`,
    ``,
    `They have already asked for a different step ${attempt} time(s).`,
    `Give a step that takes a distinctly different angle from the obvious one —`,
    `a different object, place, or sense to start from. Still one small action.`,
  ].join("\n");
}

/** The Responses API nests output; tolerate shape drift rather than crashing. */
function extractStep(payload: any): string | null {
  const text =
    payload?.output_text ??
    payload?.output?.[0]?.content?.[0]?.text ??
    null;
  if (typeof text !== "string") return null;
  try {
    const parsed = JSON.parse(text);
    const step = parsed?.step;
    return typeof step === "string" && step.trim() ? step.trim() : null;
  } catch {
    return null;
  }
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}
