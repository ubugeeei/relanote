///|
/// Top-level type checker entry point. The Rust crate exposes
/// `TypeChecker` as a struct that walks a `Program` and accumulates
/// `TypeError`s; the MoonBit port keeps the same public name and the
/// same `new` / `check_program` signature so downstream code can be
/// ported in place without reshaping call sites.
///
/// The actual inference body is deferred to a follow-up PR — see the note
/// in `inference.mbt`. For now `check_program` returns an empty error
/// list so callers can be wired up first.
pub struct TypeChecker {
  context : TypeContext
}

///|
pub fn TypeChecker::new() -> TypeChecker {
  let ctx = TypeContext::new()
  install_prelude(ctx)
  { context: ctx }
}

///|
pub fn TypeChecker::context(self : TypeChecker) -> TypeContext {
  self.context
}

///|
/// Walk a program and return the type errors discovered. The skeleton
/// returns no errors; the inference walker will plug in here once it is
/// ported.
pub fn TypeChecker::check_program(self : TypeChecker) -> Array[TypeError] {
  let _ = self
  []
}

///|
/// Install built-in bindings (scales, chords, drum kits, synth presets…)
/// into the type environment. Mirrors the seed code in
/// `crates/relanote_types/src/checker.rs`'s `install_prelude`. Kept here
/// as a stub so the inference port has a single spot to fill in.
fn install_prelude(_ctx : TypeContext) -> Unit {
  // TODO(#7): seed scales / chords / synth / drum kit bindings.
  ()
}
