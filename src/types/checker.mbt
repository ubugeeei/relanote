///|
/// Top-level type checker entry point. The legacy implementation exposes
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
/// Walk a program and return the type errors discovered. Mirrors the
/// dispatch in legacy source.
pub fn TypeChecker::check_program(
  self : TypeChecker,
  program : @ast.Program,
) -> Array[TypeError] {
  let errors : Array[TypeError] = []
  for item in program.items() {
    match self.check_item(item) {
      Ok(_) => ()
      Err(err) => errors.push(err)
    }
  }
  errors
}

///|
fn TypeChecker::check_item(
  self : TypeChecker,
  item : @core.Spanned[@ast.Item],
) -> Result[Unit, TypeError] {
  let ctx = self.context
  match item.node() {
    ScaleDef(def) => {
      ctx.bind_mono(def.name().name(), Scale)
      Ok(())
    }
    ChordDef(def) => {
      ctx.bind_mono(def.name().name(), Chord)
      Ok(())
    }
    SynthDef(def) => {
      ctx.bind_mono(def.name().name(), Synth)
      Ok(())
    }
    LetBinding(binding) => {
      let value_ty = match ctx.infer_expr(binding.value()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let scheme = ctx.generalize(value_ty)
      match binding.pattern().node() {
        Ident(ident) => ctx.bind(ident.name(), scheme)
        _ => ()
      }
      Ok(())
    }
    SetBinding(binding) => {
      let value_ty = match ctx.infer_expr(binding.value()) {
        Ok(t) => t
        Err(e) => return Err(e)
      }
      let scheme = ctx.generalize(value_ty)
      ctx.bind(binding.name().name(), scheme)
      Ok(())
    }
    FunctionDef(def) => {
      ctx.push_scope()
      let param_types : Array[Type] = []
      for param in def.params() {
        let param_ty = ctx.fresh_var()
        match param.node() {
          Ident(ident) => ctx.bind_mono(ident.name(), param_ty)
          _ => ()
        }
        param_types.push(param_ty)
      }
      let body_ty = match ctx.infer_expr(def.body()) {
        Ok(t) => t
        Err(e) => {
          ctx.pop_scope()
          return Err(e)
        }
      }
      ctx.pop_scope()
      let func_ty = Type::function_n(param_types, body_ty)
      let scheme = ctx.generalize(func_ty)
      ctx.bind(def.name().name(), scheme)
      Ok(())
    }
    ExprStmt(expr) =>
      match ctx.infer_expr(expr) {
        Ok(_) => Ok(())
        Err(e) => Err(e)
      }
    // Top-level declarations the type checker doesn't analyse yet:
    // tuning / groove / effect / mix definitions and import / export /
    // mod / use declarations. The legacy implementation is just as quiet about
    // these — they don't introduce typed identifiers into the
    // environment.
    TuningDef(_) | GrooveDef(_) | EffectDef(_) | MixDef(_) => Ok(())
    Import(_) | Export(_) | Mod(_) | Use(_) => Ok(())
  }
}

///|
/// Look up the type of a name (for hover info).
pub fn TypeChecker::lookup_type(self : TypeChecker, name : String) -> Type? {
  match self.context.lookup(name) {
    Some(scheme) => Some(self.context.apply(scheme.ty()))
    None => None
  }
}

///|
/// Install built-in bindings (transformations, effect presets, synth
/// presets, polymorphic combinators …) into the type environment.
/// Mirrors `add_builtins` in legacy source.
