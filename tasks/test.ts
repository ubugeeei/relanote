// Run every test suite the workspace ships: Rust + MoonBit.

import { run } from "./_shell";

run("cargo", ["test"]);
run("moon", ["test"], { cwd: "moonbit" });
