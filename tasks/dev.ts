// Build the WASM bridge once, then start the Nuxt dev server.

import { run } from "./_shell";

run("wasm-pack", [
  "build",
  "crates/relanote_wasm",
  "--target", "web",
  "--out-dir", "../../web/wasm/pkg",
]);
run("pnpm", ["dev"], { cwd: "web" });
