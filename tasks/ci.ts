// Everything CI runs, in the order CI runs it: format check, clippy,
// then the full Rust + MoonBit test suites.

import { run } from "./_shell";

run("cargo", ["fmt", "--", "--check"]);
run("cargo", ["clippy", "--", "-D", "warnings"]);
run("cargo", ["test"]);
run("moon", ["check"], { cwd: "moonbit" });
run("moon", ["test"], { cwd: "moonbit" });
