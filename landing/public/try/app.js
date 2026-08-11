import { normalizeTask, suggestFirstStep } from "./step-engine.js";

const EVENT_KEY = "kindling.prototype.events.v1";
const ALLOWED_EVENTS = new Set([
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
]);
const ALLOWED_PROPERTIES = new Set(["source", "outcome", "result", "generation"]);
const SCREEN_ORDER = ["welcome", "task", "step", "timer", "outcome", "success", "notification"];
const SAMPLE_TASK = "Reply to that one message I've been putting off";
const SESSION_SECONDS = 120;

const state = {
  task: "",
  step: "",
  generation: 0,
  timerStartedAt: null,
  timerHandle: null,
  timerEnded: false,
  sessionId: globalThis.crypto?.randomUUID?.() ?? `session-${Date.now()}`
};

const screens = new Map(
  [...document.querySelectorAll("[data-screen]")].map((screen) => [screen.dataset.screen, screen])
);
const taskInput = document.querySelector("#task-input");
const taskEcho = document.querySelector("#task-echo");
const stepText = document.querySelector("#step-text");
const timerText = document.querySelector("#timer-text");
const timerRing = document.querySelector("#timer-ring");
const eventCount = document.querySelector("#event-count");
const copyStatus = document.querySelector("#copy-status");
const devMode = new URLSearchParams(location.search).get("dev") === "1";

function loadEvents() {
  try {
    const parsed = JSON.parse(localStorage.getItem(EVENT_KEY) ?? "[]");
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function track(name, properties = {}) {
  if (!ALLOWED_EVENTS.has(name)) throw new Error(`Unknown analytics event: ${name}`);

  const safeProperties = Object.fromEntries(
    Object.entries(properties).filter(([key, value]) => ALLOWED_PROPERTIES.has(key) && ["string", "number", "boolean"].includes(typeof value))
  );
  const event = {
    name,
    at: new Date().toISOString(),
    session_id: state.sessionId,
    properties: safeProperties
  };
  const events = [...loadEvents(), event].slice(-250);
  localStorage.setItem(EVENT_KEY, JSON.stringify(events));
  updateEventCount();
}

function updateEventCount() {
  const count = loadEvents().length;
  eventCount.textContent = `${count} event${count === 1 ? "" : "s"} buffered on this device`;
}

function showScreen(name) {
  for (const [screenName, screen] of screens) {
    const active = name === screenName;
    screen.hidden = !active;
    screen.setAttribute("aria-hidden", String(!active));
  }
  document.body.dataset.screen = name;
  document.querySelector("#prototype-progress").textContent = `${SCREEN_ORDER.indexOf(name) + 1} of ${SCREEN_ORDER.length}`;
  if (name === "task") {
    taskInput.focus({ preventScroll: true });
  } else {
    const focusTarget = screens.get(name)?.querySelector("button, input, textarea, [tabindex='-1']");
    focusTarget?.focus({ preventScroll: true });
  }
}

function setEmberState(element, emberState) {
  const labels = {
    resting: "Ember is resting",
    ready: "Ember is glowing and ready",
    focus: "Ember is glowing steadily during the focus session",
    distracted: "Ember flickers gently; getting distracted is okay",
    celebration: "Ember blooms warmly to celebrate that you started"
  };
  element.dataset.emberState = emberState;
  element.setAttribute("aria-label", labels[emberState]);
}

function prepareStep() {
  state.step = suggestFirstStep(state.task, state.generation);
  taskEcho.textContent = state.task;
  stepText.textContent = state.step;
}

function enterTask(source) {
  const task = normalizeTask(taskInput.value);
  if (!task) {
    document.querySelector("#task-error").hidden = false;
    taskInput.focus();
    return;
  }
  document.querySelector("#task-error").hidden = true;
  state.task = task;
  state.generation = 0;
  prepareStep();
  track("first_task_entered", { source });
  track("first_step_shown", { generation: state.generation });
  showScreen("step");
}

function formatTime(seconds) {
  const safe = Math.max(0, Math.ceil(seconds));
  return `${Math.floor(safe / 60)}:${String(safe % 60).padStart(2, "0")}`;
}

function paintTimer() {
  if (!state.timerStartedAt || state.timerEnded) return;
  const elapsed = (Date.now() - state.timerStartedAt) / 1000;
  const remaining = Math.max(0, SESSION_SECONDS - elapsed);
  timerText.textContent = formatTime(remaining);
  timerRing.style.setProperty("--timer-progress", `${(remaining / SESSION_SECONDS) * 360}deg`);
  if (remaining <= 0) endTimer();
}

function startTimer() {
  state.timerStartedAt = Date.now();
  state.timerEnded = false;
  document.querySelector("#timer-step").textContent = state.step;
  track("first_session_started");
  showScreen("timer");
  paintTimer();
  state.timerHandle = setInterval(paintTimer, 250);
}

function endTimer() {
  if (state.timerEnded) return;
  state.timerEnded = true;
  clearInterval(state.timerHandle);
  state.timerHandle = null;
  showScreen("outcome");
}

function chooseOutcome(outcome) {
  track("first_session_outcome", { outcome });
  const ember = document.querySelector("#success-ember");
  setEmberState(ember, outcome === "distracted" ? "distracted" : "celebration");
  document.querySelector("#success-title").textContent = outcome === "distracted" ? "You came back." : "You started.";
  document.querySelector("#success-copy").textContent = outcome === "distracted"
    ? "Noticing is part of starting. There is no failure state here."
    : "That's the whole game.";
  showScreen("success");
}

document.querySelector("#start-onboarding").addEventListener("click", () => {
  track("onboarding_started");
  showScreen("task");
});

document.querySelector("#task-form").addEventListener("submit", (event) => {
  event.preventDefault();
  enterTask("typed");
});

document.querySelector("#sample-task").addEventListener("click", () => {
  taskInput.value = SAMPLE_TASK;
  track("sample_task_used");
  enterTask("sample");
});

document.querySelector("#regenerate-step").addEventListener("click", () => {
  state.generation += 1;
  prepareStep();
  track("step_regenerated", { generation: state.generation });
});

document.querySelector("#start-timer").addEventListener("click", startTimer);
document.querySelector("#stop-timer").addEventListener("click", endTimer);
document.querySelector("#fast-forward").addEventListener("click", () => {
  state.timerStartedAt = Date.now() - (SESSION_SECONDS - 3) * 1000;
  paintTimer();
});

for (const button of document.querySelectorAll("[data-outcome]")) {
  button.addEventListener("click", () => chooseOutcome(button.dataset.outcome));
}

document.querySelector("#show-notification-ask").addEventListener("click", () => {
  track("notification_permission_shown");
  showScreen("notification");
});

for (const button of document.querySelectorAll("[data-notification-result]")) {
  button.addEventListener("click", () => {
    track("notification_permission_result", { result: button.dataset.notificationResult });
    track("onboarding_completed");
    document.querySelector("#notification-actions").hidden = true;
    document.querySelector("#completion-message").hidden = false;
    document.querySelector("#completion-message").focus();
  });
}

document.querySelector("#copy-events").addEventListener("click", async () => {
  const exportValue = JSON.stringify({ exported_at: new Date().toISOString(), events: loadEvents() }, null, 2);
  try {
    await navigator.clipboard.writeText(exportValue);
    copyStatus.textContent = "Copied. Task and step text are never included.";
  } catch {
    const blob = new Blob([exportValue], { type: "application/json" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `kindling-events-${Date.now()}.json`;
    link.click();
    URL.revokeObjectURL(link.href);
    copyStatus.textContent = "Downloaded. Task and step text are never included.";
  }
});

document.querySelector("#clear-events").addEventListener("click", () => {
  localStorage.removeItem(EVENT_KEY);
  updateEventCount();
  copyStatus.textContent = "Local event buffer cleared.";
});

if (!devMode) document.querySelector("#fast-forward").hidden = true;
for (const ember of document.querySelectorAll("[data-ember-state]")) setEmberState(ember, ember.dataset.emberState);
updateEventCount();
showScreen("welcome");
