// First-time setup: install JS deps, build the WASM bridge the playground
// depends on, prepare Nuxt's auto-generated types.

import { run } from "./_shell";

run("pnpm", ["install"], { cwd: "web" });
run("pnpm", ["install"], { cwd: "docs" });
run("wasm-pack", [
  "build",
  "crates/relanote_wasm",
  "--target", "web",
  "--out-dir", "../../web/wasm/pkg",
]);
run("pnpm", ["exec", "nuxt", "prepare"], { cwd: "web" });

console.log("\n==> Setup complete. Try `pnpm dev` next.");
