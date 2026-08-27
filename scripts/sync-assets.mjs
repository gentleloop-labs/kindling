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
const publicAssets = resolve(root, "landing/public/assets");

await mkdir(resolve(root, "prototype"), { recursive: true });
await mkdir(resolve(root, "landing/src/styles"), { recursive: true });
await mkdir(publicAssets, { recursive: true });
await copyFile(tokenSource, resolve(root, "prototype/tokens.css"));
await copyFile(tokenSource, resolve(root, "landing/src/styles/tokens.css"));
await sharp(mascotSource)
  .resize(400, 400, { fit: "inside", withoutEnlargement: true })
  .webp({ quality: 85, effort: 6 })
  .toFile(resolve(publicAssets, "ember-mascot.webp"));
await sharp(appIconSource)
  .resize(512, 512, { fit: "cover" })
  .png({ compressionLevel: 9, effort: 10 })
  .toFile(resolve(publicAssets, "kindling-app-icon.png"));
await sharp(appIconSource)
  .resize(256, 256, { fit: "cover" })
  .webp({ quality: 88, effort: 6 })
  .toFile(resolve(publicAssets, "kindling-app-icon.webp"));

const socialCardArtwork = Buffer.from(`
  <svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="warmth" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#ffb13b" stop-opacity="0.48" />
        <stop offset="70%" stop-color="#f36f2c" stop-opacity="0.13" />
        <stop offset="100%" stop-color="#f36f2c" stop-opacity="0" />
      </radialGradient>
      <linearGradient id="step" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#fffaf3" />
        <stop offset="100%" stop-color="#f6eadc" />
      </linearGradient>
    </defs>

    <rect width="1200" height="630" fill="#faf6f1" />
    <circle cx="985" cy="309" r="310" fill="url(#warmth)" />
    <circle cx="1126" cy="62" r="126" fill="#f36f2c" opacity="0.08" />
    <circle cx="709" cy="607" r="170" fill="#ffb13b" opacity="0.08" />

    <text x="142" y="92" fill="#5a3a2b" font-family="Arial, Helvetica, sans-serif" font-size="26" font-weight="700" letter-spacing="4">KINDLING</text>
    <text x="60" y="210" fill="#2b211c" font-family="Arial, Helvetica, sans-serif" font-size="67" font-weight="750">
      <tspan x="60" dy="0">Start the task</tspan>
      <tspan x="60" dy="78">you are avoiding.</tspan>
    </text>
    <text x="64" y="349" fill="#735b4d" font-family="Arial, Helvetica, sans-serif" font-size="29" font-weight="400">One tiny first step. One short timer.</text>

    <g transform="translate(60 411)">
      <rect width="650" height="128" rx="30" fill="url(#step)" stroke="#e8d7c8" stroke-width="2" />
      <g transform="translate(25 24)">
        <circle cx="19" cy="19" r="19" fill="#f36f2c" />
        <text x="19" y="27" text-anchor="middle" fill="#ffffff" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="700">1</text>
        <text x="0" y="77" fill="#3f3028" font-family="Arial, Helvetica, sans-serif" font-size="21" font-weight="700">Name it</text>
      </g>
      <text x="190" y="72" fill="#c7a48c" font-family="Arial, Helvetica, sans-serif" font-size="31">›</text>
      <g transform="translate(238 24)">
        <circle cx="19" cy="19" r="19" fill="#f36f2c" />
        <text x="19" y="27" text-anchor="middle" fill="#ffffff" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="700">2</text>
        <text x="0" y="77" fill="#3f3028" font-family="Arial, Helvetica, sans-serif" font-size="21" font-weight="700">Tiny step</text>
      </g>
      <text x="410" y="72" fill="#c7a48c" font-family="Arial, Helvetica, sans-serif" font-size="31">›</text>
      <g transform="translate(458 24)">
        <circle cx="19" cy="19" r="19" fill="#f36f2c" />
        <text x="19" y="27" text-anchor="middle" fill="#ffffff" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="700">3</text>
        <text x="0" y="77" fill="#3f3028" font-family="Arial, Helvetica, sans-serif" font-size="21" font-weight="700">Start 2 min</text>
      </g>
    </g>

    <g transform="translate(810 445)">
      <rect width="298" height="120" rx="28" fill="#fffaf3" stroke="#e4cdbb" stroke-width="2" />
      <text x="28" y="38" fill="#a26b4a" font-family="Arial, Helvetica, sans-serif" font-size="17" font-weight="700" letter-spacing="2">YOUR FIRST STEP</text>
      <text x="28" y="75" fill="#33251e" font-family="Arial, Helvetica, sans-serif" font-size="23" font-weight="700">Open the document.</text>
      <text x="218" y="102" fill="#f36f2c" font-family="Arial, Helvetica, sans-serif" font-size="22" font-weight="700">02:00</text>
    </g>
  </svg>
`);
const socialMascot = await sharp(mascotSource)
  .resize(390, 390, { fit: "inside", withoutEnlargement: true })
  .png()
  .toBuffer();
const socialIcon = await sharp(appIconSource)
  .resize(64, 64, { fit: "cover" })
  .png()
  .toBuffer();

await sharp(socialCardArtwork)
  .composite([
    { input: socialIcon, left: 60, top: 48 },
    { input: socialMascot, left: 808, top: 75 }
  ])
  .png({ compressionLevel: 9, effort: 10, palette: false })
  .toFile(resolve(publicAssets, "kindling-social-card.png"));

console.log("Synced shared tokens, production app artwork, and the social preview card.");
