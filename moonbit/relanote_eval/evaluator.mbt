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
/// Evaluate a program. Walks each item, dispatching to `eval_item` and
/// remembering the value of the final `ExprStmt` so the CLI can print
/// it. Definitions (scale / chord / synth / let / function) update the
/// environment; non-expression items contribute `UnitV`.
pub fn Evaluator::eval_program(
  self : Evaluator,
  program : @ast.Program,
) -> Result[Value, EvalError] {
  let mut last : Value = UnitV
  for item in program.items() {
    match self.eval_item(item) {
      Ok(v) => last = v
      Err(e) => return Err(e)
    }
  }
  Ok(last)
}

///|
/// Evaluate a single top-level item.
fn Evaluator::eval_item(
  self : Evaluator,
  item : @core.Spanned[@ast.Item],
) -> Result[Value, EvalError] {
  match item.node() {
    ScaleDef(def) => {
      self.env.bind(def.name().name(), ScaleV(def))
      Ok(UnitV)
    }
    ChordDef(def) => {
      self.env.bind(def.name().name(), ChordV(def))
      Ok(UnitV)
    }
    SynthDef(def) => {
      self.env.bind(def.name().name(), SynthV(def))
      Ok(UnitV)
    }
    LetBinding(binding) => {
      let value = match self.eval_expr(binding.value()) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      match binding.pattern().node() {
        Ident(ident) => self.env.bind(ident.name(), value)
        _ => ()
      }
      Ok(UnitV)
    }
    SetBinding(binding) => {
      let value = match self.eval_expr(binding.value()) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      self.env.bind(binding.name().name(), value)
      Ok(UnitV)
    }
    FunctionDef(def) => {
      // Captured environment is the current one at definition time —
      // sufficient for the simple closures the walker will introduce
      // in the next sub-PR.
      self.env.bind(def.name().name(), ClosureV(def, self.env))
      Ok(UnitV)
    }
    ExprStmt(expr) => self.eval_expr(expr)
    // Items the evaluator doesn't yet model — tuning / groove / effect /
    // mix declarations and module-level imports / exports / mod / use.
    // These produce no value at runtime in the Rust crate either.
    TuningDef(_) | GrooveDef(_) | EffectDef(_) | MixDef(_) => Ok(UnitV)
    Import(_) | Export(_) | Mod(_) | Use(_) => Ok(UnitV)
  }
}

///|
/// Evaluate an expression. Currently covers the leaf literals only —
/// later sub-PRs in #56 extend this to identifiers, intervals, blocks,
/// lambdas, application, pipe and the remaining `Expr` variants.
pub fn Evaluator::eval_expr(
  self : Evaluator,
  expr : @core.Spanned[@ast.Expr],
) -> Result[Value, EvalError] {
  match expr.node() {
    Integer(n) => Ok(IntV(n))
    Float(f) => Ok(FloatV(f))
    StringLit(s) => Ok(StringV(s))
    BoolLit(b) => Ok(BoolV(b))
    UnitLit => Ok(UnitV)
    Ident(ident) =>
      match self.env.lookup(ident.name()) {
        Some(v) => Ok(v)
        None =>
          Err(UndefinedVariable(name=ident.name(), span=expr.span()))
      }
    Paren(inner) => self.eval_expr(inner)
    Annotated(inner, _) => self.eval_expr(inner)
    _ => {
      let _ = self
      Ok(Placeholder)
    }
  }
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
