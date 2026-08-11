import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const html = await readFile(new URL("../index.html", import.meta.url), "utf8");
const appSource = await readFile(new URL("../app.js", import.meta.url), "utf8");

test("contains the seven Phase 0 onboarding screens", () => {
  const screens = [...html.matchAll(/<section class="screen[^"]*" data-screen="([^"]+)"/g)].map((match) => match[1]);
  assert.deepEqual(screens, ["welcome", "task", "step", "timer", "outcome", "success", "notification"]);
});

test("renders all outcomes with one equal-weight component", () => {
  const outcomeButtons = [...html.matchAll(/class="button button--outcome" data-outcome="([^"]+)"/g)].map((match) => match[1]);
  assert.deepEqual(outcomeButtons, ["kept_going", "stopped_enough", "distracted"]);
});

test("implements every onboarding research event", () => {
  const required = [
    "onboarding_started",
    "first_task_entered",
    "sample_task_used",
    "first_step_shown",
    "step_regenerated",
    "first_session_started",
    "first_session_outcome",
    "notification_permission_shown",
    "notification_permission_result",
    "onboarding_completed"
  ];
  for (const eventName of required) assert.match(appSource, new RegExp(`track\\(\\"${eventName}\\"`));
});

test("keeps stop visible and includes a development fast-forward", () => {
  assert.match(html, /id="stop-timer"/);
  assert.match(html, /id="fast-forward"/);
  assert.match(appSource, /devMode/);
});
