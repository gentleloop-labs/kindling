import { defineConfig } from "astro/config";

export default defineConfig({
  site: process.env.SITE_URL ?? "https://kindling.maskedsyntax.com",
  output: "static",
  build: {
    format: "directory"
  }
});
