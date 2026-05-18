// Tiny shell helper used across Vite Tasks. Wraps `child_process` so the
// task scripts read like a short imperative recipe.

import { spawnSync, type SpawnSyncOptions } from "node:child_process";

export interface RunOptions extends SpawnSyncOptions {
  /** Print the command to stdout before running it. Defaults to true. */
  echo?: boolean;
}

/**
 * Run a shell command inheriting stdio. Throws on non-zero exit.
 * The first element is the command, the rest are arguments.
 */
export function run(cmd: string, args: readonly string[] = [], opts: RunOptions = {}): void {
  const { echo = true, ...rest } = opts;
  if (echo) {
    const cwd = rest.cwd ? ` (in ${rest.cwd})` : "";
    process.stdout.write(`==> ${cmd} ${args.join(" ")}${cwd}\n`);
  }
  const result = spawnSync(cmd, args, { stdio: "inherit", shell: false, ...rest });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

/**
 * Run a shell command via the system shell (for chained pipes etc.). Use
 * the array form (`run`) when possible; this is for unavoidable shell
 * features only.
 */
export function sh(script: string, opts: RunOptions = {}): void {
  const { echo = true, ...rest } = opts;
  if (echo) {
    const cwd = rest.cwd ? ` (in ${rest.cwd})` : "";
    process.stdout.write(`==> ${script}${cwd}\n`);
  }
  const result = spawnSync(script, { stdio: "inherit", shell: true, ...rest });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}
