import assert from "node:assert/strict";
import test from "node:test";

import { normalizeTask, suggestFirstStep, stepRuleCount } from "../step-engine.js";

const CASES = [
  ["reply to the email", "Open the conversation"],
  ["Send Maya a message", "Open the conversation"],
  ["call the dentist", "Find the number"],
  ["write the quarterly report", "Open a blank document"],
  ["Draft my proposal", "Open a blank document"],
  ["read chapter four", "Open the material"],
  ["study for the exam", "Open the material"],
  ["clean my bedroom", "Pick up one visible item"],
  ["tidy desk", "Pick up one visible item"],
  ["do the laundry", "Put one piece of clothing"],
  ["wash the dishes", "Put one dish"],
  ["pay electricity bill", "Open the bill"],
  ["book a doctor appointment", "Find the booking page"],
  ["fill the application form", "Open the form"],
  ["pack for the trip", "Put the empty bag"],
  ["go for a run", "Put on the first piece"],
  ["start doing the thing", "Put the task in front of you"],
  ["organize project notes", "Put the task in front of you"],
  ["renew my passport", "Put the task in front of you"],
  ["decide what to cook", "Put the task in front of you"]
];

test("covers the provisional Phase 0 task matrix", () => {
  assert.equal(CASES.length, 20);
  for (const [task, expectedStart] of CASES) {
    assert.match(suggestFirstStep(task), new RegExp(`^${expectedStart}`));
  }
});

test("normalizes whitespace without changing the user's words", () => {
  assert.equal(normalizeTask("  reply   to it \n today "), "reply to it today");
});

test("returns safe guidance for an empty task", () => {
  assert.match(suggestFirstStep("   "), /^Type the thing/);
});

test("regeneration is deterministic and cycles", () => {
  const first = suggestFirstStep("reply to the message", 0);
  const second = suggestFirstStep("reply to the message", 1);
  assert.notEqual(first, second);
  assert.equal(suggestFirstStep("reply to the message", 3), first);
});

test("has enough specific rule families for live validation", () => {
  assert.ok(stepRuleCount >= 10);
});
