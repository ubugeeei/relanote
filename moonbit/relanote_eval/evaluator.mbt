///|
/// Evaluator — walks an AST `Program` and produces a top-level `Value`.
/// The Rust crate's evaluator is the largest module in the repository
/// (~1,500 lines plus 2,200 lines of builtins); the MoonBit port keeps
/// the public surface stable so downstream call sites can be wired up
/// before the walker arrives.
///
/// Tracked in #8.
pub struct Evaluator {
  env : Env
}

///|
pub fn Evaluator::new() -> Evaluator {
  let env = Env::new()
  install_prelude(env)
  { env, }
}

///|
pub fn Evaluator::env(self : Evaluator) -> Env {
  self.env
}

///|
/// Evaluate a program and return the final value. The skeleton returns
/// `UnitV` and reports the program as "not yet evaluated"; the real
/// walker plugs in here.
pub fn Evaluator::eval_program(
  self : Evaluator,
  program : @ast.Program,
) -> Result[Value, EvalError] {
  let _ = self
  let _ = program
  Ok(UnitV)
}

///|
/// Seed builtin bindings (scales, chords, synths, effects). The Rust
/// crate evaluates the relanote-source prelude returned by
/// `relanote_stdlib::prelude::PRELUDE`. The MoonBit port has access to
/// the same prelude text via `@stdlib.PRELUDE` so the eventual walker
/// can drive the same boot sequence.
fn install_prelude(env : Env) -> Unit {
  let _ = env
  let _ = @stdlib.PRELUDE
  // TODO(#8): parse + evaluate the embedded prelude once the parser /
  // evaluator are both real.
  ()
}
