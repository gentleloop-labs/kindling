import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const appSource = await readFile(new URL("../app.js", import.meta.url), "utf8");

test("analytics property whitelist excludes user-entered content", () => {
  const whitelist = appSource.match(/ALLOWED_PROPERTIES = new Set\(\[([^\]]+)]\)/s)?.[1] ?? "";
  assert.doesNotMatch(whitelist, /task|step|title|text|email/i);
  assert.match(whitelist, /outcome/);
  assert.match(whitelist, /result/);
});

test("event writes do not accept arbitrary payload objects", () => {
  assert.match(appSource, /Object\.entries\(properties\)\.filter/);
  assert.match(appSource, /ALLOWED_PROPERTIES\.has\(key\)/);
});

test("task input is not persisted to local storage", () => {
  const storageWrites = [...appSource.matchAll(/localStorage\.setItem\(([^;]+);/gs)].map((match) => match[1]);
  assert.ok(storageWrites.length > 0);
  for (const write of storageWrites) assert.doesNotMatch(write, /state\.task|state\.step|taskInput|taskEcho|stepText/);
});
