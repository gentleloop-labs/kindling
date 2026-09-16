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

await mkdir(resolve(root, "landing/src/styles"), { recursive: true });
await mkdir(publicAssets, { recursive: true });
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
      <linearGradient id="card" x1="0" y1="0" x2="1" y2="1">
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
      <tspan x="60" dy="0">Remember where</tspan>
      <tspan x="60" dy="78">life happened.</tspan>
    </text>
    <text x="64" y="349" fill="#735b4d" font-family="Arial, Helvetica, sans-serif" font-size="29" font-weight="400">Turn selected trip photos into a private Memory Trail.</text>

    <g transform="translate(60 411)">
      <rect width="650" height="128" rx="30" fill="url(#card)" stroke="#e8d7c8" stroke-width="2" />
      <text x="30" y="39" fill="#a26b4a" font-family="Arial, Helvetica, sans-serif" font-size="17" font-weight="700" letter-spacing="2">A WEEKEND IN LISBON</text>
      <path d="M42 92 C 138 34, 228 115, 319 69 S 486 40, 597 86" fill="none" stroke="#f36f2c" stroke-width="5" stroke-linecap="round" />
      <circle cx="42" cy="92" r="10" fill="#ffb13b" />
      <circle cx="319" cy="69" r="10" fill="#ffb13b" />
      <circle cx="597" cy="86" r="10" fill="#ffb13b" />
    </g>

    <g transform="translate(810 445)">
      <rect width="298" height="120" rx="28" fill="#fffaf3" stroke="#e4cdbb" stroke-width="2" />
      <text x="28" y="38" fill="#a26b4a" font-family="Arial, Helvetica, sans-serif" font-size="17" font-weight="700" letter-spacing="2">A SMALL SPARK</text>
      <text x="28" y="75" fill="#33251e" font-family="Arial, Helvetica, sans-serif" font-size="21" font-weight="700">What did this</text>
      <text x="28" y="101" fill="#33251e" font-family="Arial, Helvetica, sans-serif" font-size="21" font-weight="700">place sound like?</text>
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
