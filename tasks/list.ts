// `pnpm tasks` — print the full task surface in a readable layout.
// Mirrors the `package.json` "scripts" map, grouped by area.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "..");
const pkg = JSON.parse(readFileSync(resolve(root, "package.json"), "utf8")) as {
  scripts: Record<string, string>;
};

const groups: Array<{ heading: string; prefix?: string; only?: string[] }> = [
  { heading: "Rust", only: ["build", "release", "check", "lint", "fmt", "fmt:check", "clean", "doc", "run", "lsp", "test:rust"] },
  { heading: "MoonBit", prefix: "moon:" },
  { heading: "Stdlib", only: ["stdlib:regen"] },
  { heading: "WASM", prefix: "wasm:" },
  { heading: "Web playground", prefix: "web:" },
  { heading: "Docs", prefix: "docs:" },
  { heading: "Combined", only: ["test", "ci", "setup", "dev"] },
  { heading: "Misc", only: ["og:png", "tasks"] },
];

for (const g of groups) {
  const entries = Object.entries(pkg.scripts).filter(([name]) => {
    if (g.only) return g.only.includes(name);
    if (g.prefix) return name.startsWith(g.prefix);
    return false;
  });
  if (entries.length === 0) continue;
  console.log(`\n${g.heading}`);
  for (const [name, cmd] of entries) {
    const left = `  pnpm ${name}`.padEnd(28, " ");
    console.log(`${left}${cmd}`);
  }
}
console.log("");
