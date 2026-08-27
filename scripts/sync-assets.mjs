import { copyFile, mkdir } from "node:fs/promises";
import { createRequire } from "node:module";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDirectory = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptsDirectory, "..");
const requireFromLanding = createRequire(resolve(root, "landing/package.json"));
const sharp = requireFromLanding("sharp");
const tokenSource = resolve(root, "design/tokens.css");
const mascotSource = resolve(
  root,
  "ios/Packages/KindlingUI/Sources/KindlingUI/Resources/Tokens.xcassets/EmberMascot.imageset/EmberMascot.png"
);
const appIconSource = resolve(root, "ios/Kindling/Assets.xcassets/AppIcon.appiconset/Kindling-AppIcon.png");

await mkdir(resolve(root, "prototype"), { recursive: true });
await mkdir(resolve(root, "landing/src/styles"), { recursive: true });
await mkdir(resolve(root, "landing/public/assets"), { recursive: true });
await copyFile(tokenSource, resolve(root, "prototype/tokens.css"));
await copyFile(tokenSource, resolve(root, "landing/src/styles/tokens.css"));
await sharp(mascotSource)
  .resize(400, 400, { fit: "inside", withoutEnlargement: true })
  .webp({ quality: 85, effort: 6 })
  .toFile(resolve(root, "landing/public/assets/ember-mascot.webp"));
await sharp(appIconSource)
  .resize(512, 512, { fit: "cover" })
  .png({ compressionLevel: 9, effort: 10 })
  .toFile(resolve(root, "landing/public/assets/kindling-app-icon.png"));
await sharp(appIconSource)
  .resize(256, 256, { fit: "cover" })
  .webp({ quality: 88, effort: 6 })
  .toFile(resolve(root, "landing/public/assets/kindling-app-icon.webp"));

console.log("Synced shared tokens and production app artwork.");
