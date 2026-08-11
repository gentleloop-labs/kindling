import { readFile } from "node:fs/promises";

const path = process.argv[2];
if (!path) {
  console.error("Usage: node scripts/analyze-events.mjs path/to/events.json");
  process.exitCode = 1;
} else {
  const parsed = JSON.parse(await readFile(path, "utf8"));
  const events = Array.isArray(parsed) ? parsed : parsed.events;
  if (!Array.isArray(events)) throw new Error("Expected an event array or an object containing events");

  const sessions = new Map();
  for (const event of events) {
    if (!event?.session_id || !event?.name) continue;
    const session = sessions.get(event.session_id) ?? { names: new Set(), startedAt: null, sessionAt: null };
    session.names.add(event.name);
    if (event.name === "onboarding_started") session.startedAt = Date.parse(event.at);
    if (event.name === "first_session_started") session.sessionAt = Date.parse(event.at);
    sessions.set(event.session_id, session);
  }

  const values = [...sessions.values()];
  const started = values.filter((value) => value.names.has("onboarding_started"));
  const percent = (numerator, denominator) => denominator ? `${((numerator / denominator) * 100).toFixed(1)}%` : "n/a";
  const completionCount = started.filter((value) => value.names.has("onboarding_completed")).length;
  const sampleCount = started.filter((value) => value.names.has("sample_task_used")).length;
  const firstStepSessions = started.filter((value) => value.names.has("first_step_shown"));
  const startedSessionCount = firstStepSessions.filter((value) => value.names.has("first_session_started")).length;
  const times = started
    .filter((value) => Number.isFinite(value.startedAt) && Number.isFinite(value.sessionAt))
    .map((value) => (value.sessionAt - value.startedAt) / 1000)
    .sort((a, b) => a - b);
  const median = times.length ? times[Math.floor(times.length / 2)] : null;

  console.log(`Prototype sessions started: ${started.length}`);
  console.log(`Completion rate: ${percent(completionCount, started.length)} (${completionCount}/${started.length})`);
  console.log(`Sample-chip usage: ${percent(sampleCount, started.length)} (${sampleCount}/${started.length})`);
  console.log(`First-session start: ${percent(startedSessionCount, firstStepSessions.length)} (${startedSessionCount}/${firstStepSessions.length})`);
  console.log(`Median time to session: ${median === null ? "n/a" : `${median.toFixed(1)}s`}`);
}
