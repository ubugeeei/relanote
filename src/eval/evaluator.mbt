///|
/// Evaluator — walks an AST `Program` and produces a top-level `Value`.
/// The evaluator keeps the public surface stable for CLI, LSP, render,
/// and playground callers while the language packages share one runtime
/// value model.
///
/// Tracked in #8.
pub struct Evaluator {
  mut env : Env
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
fn Evaluator::set_env(self : Evaluator, env : Env) -> Unit {
  self.env = env
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
    // These produce no value at runtime in the legacy implementation either.
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
        None => Err(UndefinedVariable(name=ident.name(), span=expr.span()))
      }
    Interval(lit) => Ok(IntervalV(lit.semitones()))
    AbsolutePitch(lit) => Ok(AbsolutePitchV(absolute_pitch_to_midi(lit)))
    Root => Ok(RootV)
    Block(block) => Ok(BlockV(block))
    Tuplet(t) => Ok(TupletV(t))
    Articulation(a) => Ok(ArticulationV(a))
    Envelope(e) => Ok(EnvelopeV(e))
    Part(p) => Ok(PartV(p))
    Section(s) => Ok(SectionV(s))
    Layer(l) => {
      let values : Array[Value] = []
      for part in l.parts() {
        match self.eval_expr(part) {
          Ok(v) => values.push(v)
          Err(e) => return Err(e)
        }
      }
      Ok(ParallelV(values))
    }
    Lambda(lambda) => Ok(LambdaV(lambda.params(), lambda.body(), self.env))
    Application(app) => self.eval_application(app, expr.span())
    Pipe(pipe) => {
      // `x |> f` is sugar for `f(x)`.
      let arg = match self.eval_expr(pipe.left()) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let f = match self.eval_expr(pipe.right()) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      self.call(f, [arg], expr.span())
    }
    Paren(inner) => self.eval_expr(inner)
    Annotated(inner, _) => self.eval_expr(inner)
    Array(elements) => {
      let values : Array[Value] = []
      for elem in elements {
        match self.eval_expr(elem) {
          Ok(v) => values.push(v)
          Err(e) => return Err(e)
        }
      }
      Ok(ArrayV(values))
    }
    Tuple(elements) => {
      let values : Array[Value] = []
      for elem in elements {
        match self.eval_expr(elem) {
          Ok(v) => values.push(v)
          Err(e) => return Err(e)
        }
      }
      Ok(TupleV(values))
    }
    If(if_expr) => self.eval_if(if_expr, expr.span())
    Let(let_expr) => self.eval_let(let_expr)
    Index(idx) => self.eval_index(idx, expr.span())
    Binary(b) => self.eval_binary(b, expr.span())
    Unary(u) => self.eval_unary(u, expr.span())
    With(with_expr) =>
      // `e with { ... }` evaluates to the base; the modifications are
      // taken care of by the resolver / type checker in the legacy implementation.
      // Matches the previous evaluator's behaviour.
      self.eval_expr(with_expr.base())
    Over(left, right) => {
      // `a over b` is a polyrhythm — both sides play simultaneously.
      // The renderer is the only place that interprets the relationship
      // meaningfully; here we just evaluate both sides and return the
      // left side so a `let m = a over b` still binds a usable value.
      let _ = match self.eval_expr(right) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
      self.eval_expr(left)
    }
    Field(_) | InScale(_) | Error => Ok(Placeholder)
    _ => {
      let _ = self
      Ok(Placeholder)
    }
  }
}

///|
/// Evaluate a binary operator. Mirrors the dispatch in
/// legacy source for the basic arithmetic /
/// logical / comparison cases. Block-level operators
/// (`++` for Concat, `>>` for Compose) are deferred until the
/// renderer-driving block operations land.
