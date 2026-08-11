import { cp, copyFile, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDirectory = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptsDirectory, "..");
const tokenSource = resolve(root, "design/tokens.css");

await mkdir(resolve(root, "prototype"), { recursive: true });
await mkdir(resolve(root, "landing/src/styles"), { recursive: true });
await mkdir(resolve(root, "landing/public/try"), { recursive: true });
await copyFile(tokenSource, resolve(root, "prototype/tokens.css"));
await copyFile(tokenSource, resolve(root, "landing/src/styles/tokens.css"));
await cp(resolve(root, "prototype"), resolve(root, "landing/public/try"), {
  recursive: true,
  filter: (source) => !source.includes(`${resolve(root, "prototype")}/tests`)
});

console.log("Synced shared tokens and the /try prototype.");
