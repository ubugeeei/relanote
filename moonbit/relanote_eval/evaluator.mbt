///|
/// Evaluator — walks an AST `Program` and produces a top-level `Value`.
/// The Rust crate's evaluator is the largest module in the repository
/// (~1,500 lines plus 2,200 lines of builtins); the MoonBit port keeps
/// the public surface stable so downstream call sites can be wired up
/// before the walker arrives.
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
    Interval(lit) => Ok(IntervalV(lit.semitones()))
    AbsolutePitch(lit) => Ok(AbsolutePitchV(absolute_pitch_to_midi(lit)))
    Root => Ok(RootV)
    Block(block) => Ok(BlockV(block))
    Tuplet(t) => Ok(TupletV(t))
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
    _ => {
      let _ = self
      Ok(Placeholder)
    }
  }
}

///|
/// Evaluate a binary operator. Mirrors the dispatch in
/// `crates/relanote_eval/src/eval.rs` for the basic arithmetic /
/// logical / comparison cases. Block-level operators
/// (`++` for Concat, `>>` for Compose) are deferred until the
/// renderer-driving block operations land.
fn Evaluator::eval_binary(
  self : Evaluator,
  binary : @ast.Binary,
  span : @core.Span,
) -> Result[Value, EvalError] {
  let left = match self.eval_expr(binary.left()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let right = match self.eval_expr(binary.right()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  match binary.op() {
    Add => arithmetic(left, right, fn(a, b) { a + b }, fn(a, b) { a + b }, span)
    Sub => arithmetic(left, right, fn(a, b) { a - b }, fn(a, b) { a - b }, span)
    Mul => arithmetic(left, right, fn(a, b) { a * b }, fn(a, b) { a * b }, span)
    Div =>
      match (left, right) {
        (IntV(_), IntV(0L)) => Err(DivisionByZero(span=span))
        (IntV(a), IntV(b)) => Ok(IntV(a / b))
        (FloatV(a), FloatV(b)) => Ok(FloatV(a / b))
        _ =>
          Err(TypeError(expected="numeric", found="other", span=span))
      }
    Mod =>
      match (left, right) {
        (IntV(_), IntV(0L)) => Err(DivisionByZero(span=span))
        (IntV(a), IntV(b)) => Ok(IntV(a % b))
        _ =>
          Err(TypeError(expected="Int", found="other", span=span))
      }
    EqOp => Ok(BoolV(values_equal(left, right)))
    NeOp => Ok(BoolV(!values_equal(left, right)))
    Lt => compare(left, right, fn(a, b) { a < b }, fn(a, b) { a < b }, span)
    Le => compare(left, right, fn(a, b) { a <= b }, fn(a, b) { a <= b }, span)
    Gt => compare(left, right, fn(a, b) { a > b }, fn(a, b) { a > b }, span)
    Ge => compare(left, right, fn(a, b) { a >= b }, fn(a, b) { a >= b }, span)
    And =>
      match (left, right) {
        (BoolV(a), BoolV(b)) => Ok(BoolV(a && b))
        _ => Err(TypeError(expected="Bool", found="other", span=span))
      }
    Or =>
      match (left, right) {
        (BoolV(a), BoolV(b)) => Ok(BoolV(a || b))
        _ => Err(TypeError(expected="Bool", found="other", span=span))
      }
    // Block-level operators land alongside the renderer port.
    Concat | Compose => Ok(Placeholder)
  }
}

///|
fn arithmetic(
  left : Value,
  right : Value,
  int_op : (Int64, Int64) -> Int64,
  float_op : (Double, Double) -> Double,
  span : @core.Span,
) -> Result[Value, EvalError] {
  match (left, right) {
    (IntV(a), IntV(b)) => Ok(IntV(int_op(a, b)))
    (FloatV(a), FloatV(b)) => Ok(FloatV(float_op(a, b)))
    _ => Err(TypeError(expected="numeric", found="other", span=span))
  }
}

///|
fn compare(
  left : Value,
  right : Value,
  int_op : (Int64, Int64) -> Bool,
  float_op : (Double, Double) -> Bool,
  span : @core.Span,
) -> Result[Value, EvalError] {
  match (left, right) {
    (IntV(a), IntV(b)) => Ok(BoolV(int_op(a, b)))
    (FloatV(a), FloatV(b)) => Ok(BoolV(float_op(a, b)))
    _ => Err(TypeError(expected="numeric", found="other", span=span))
  }
}

///|
/// Structural equality for the value variants the evaluator can
/// produce today. Variants carrying AST nodes compare reference-
/// equal by structure (i.e. not equal between separately
/// constructed values).
fn values_equal(a : Value, b : Value) -> Bool {
  match (a, b) {
    (UnitV, UnitV) => true
    (BoolV(x), BoolV(y)) => x == y
    (IntV(x), IntV(y)) => x == y
    (FloatV(x), FloatV(y)) => x == y
    (StringV(x), StringV(y)) => x == y
    (IntervalV(x), IntervalV(y)) => x == y
    (AbsolutePitchV(x), AbsolutePitchV(y)) => x == y
    (RootV, RootV) => true
    _ => false
  }
}

///|
/// Evaluate `-x` / `!x`.
fn Evaluator::eval_unary(
  self : Evaluator,
  unary : @ast.Unary,
  span : @core.Span,
) -> Result[Value, EvalError] {
  let operand = match self.eval_expr(unary.operand()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  match unary.op() {
    Neg =>
      match operand {
        IntV(n) => Ok(IntV(-n))
        FloatV(f) => Ok(FloatV(-f))
        _ => Err(TypeError(expected="numeric", found="other", span=span))
      }
    Not =>
      match operand {
        BoolV(b) => Ok(BoolV(!b))
        _ => Err(TypeError(expected="Bool", found="other", span=span))
      }
  }
}

///|
/// Evaluate `if cond then a else b`.
fn Evaluator::eval_if(
  self : Evaluator,
  if_expr : @ast.IfExpr,
  span : @core.Span,
) -> Result[Value, EvalError] {
  let cond_val = match self.eval_expr(if_expr.condition()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  match cond_val {
    BoolV(true) => self.eval_expr(if_expr.then_branch())
    BoolV(false) =>
      match if_expr.else_branch() {
        Some(else_b) => self.eval_expr(else_b)
        // `if c then a` with no else returns Unit, matching the Rust crate.
        None => Ok(UnitV)
      }
    _ =>
      Err(
        TypeError(expected="Bool", found="other", span=span),
      )
  }
}

///|
/// Evaluate `let pat = value in body`. Only ident patterns bind for
/// now; destructuring patterns land when the full pattern matcher
/// arrives.
fn Evaluator::eval_let(
  self : Evaluator,
  let_expr : @ast.LetExpr,
) -> Result[Value, EvalError] {
  let value = match self.eval_expr(let_expr.value()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let scope_env = Env::with_parent(self.env)
  match let_expr.pattern().node() {
    Ident(ident) => scope_env.bind(ident.name(), value)
    _ => ()
  }
  let outer = self.env
  self.set_env(scope_env)
  let result = self.eval_expr(let_expr.body())
  self.set_env(outer)
  result
}

///|
/// Evaluate `base[index]`. Supports arrays and tuples (with integer
/// indices); scale / chord indexing is deferred until the structured
/// values land.
fn Evaluator::eval_index(
  self : Evaluator,
  idx : @ast.Index,
  span : @core.Span,
) -> Result[Value, EvalError] {
  let base = match self.eval_expr(idx.base()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let index_v = match self.eval_expr(idx.index()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  match (base, index_v) {
    (ArrayV(elems), IntV(i)) => {
      let n = elems.length()
      if i < 0L || i.to_int() >= n {
        Err(IndexOutOfBounds(index=i, len=n, span=span))
      } else {
        Ok(elems[i.to_int()])
      }
    }
    (TupleV(elems), IntV(i)) => {
      let n = elems.length()
      if i < 0L || i.to_int() >= n {
        Err(IndexOutOfBounds(index=i, len=n, span=span))
      } else {
        Ok(elems[i.to_int()])
      }
    }
    _ =>
      Err(
        TypeError(expected="Array or Tuple with Int index", found="other", span=span),
      )
  }
}

///|
/// Evaluate `f(args...)`.
fn Evaluator::eval_application(
  self : Evaluator,
  app : @ast.Application,
  span : @core.Span,
) -> Result[Value, EvalError] {
  let func = match self.eval_expr(app.func()) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let arg_values : Array[Value] = []
  for arg in app.args() {
    match self.eval_expr(arg) {
      Ok(v) => arg_values.push(v)
      Err(e) => return Err(e)
    }
  }
  self.call(func, arg_values, span)
}

///|
/// Apply a callable value to a list of evaluated arguments. Handles
/// user lambdas and user-defined functions (named `let f x = …`).
/// Builtins land in a later sub-PR of #56 — calling one today produces
/// a `NotAFunction` error.
fn Evaluator::call(
  self : Evaluator,
  func : Value,
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  match func {
    LambdaV(params, body, captured) =>
      self.run_function(params, body, captured, args, span)
    ClosureV(def, captured) =>
      self.run_function(def.params(), def.body(), captured, args, span)
    BuiltinV(name) => call_builtin(name, args, span)
    _ => Err(NotAFunction(span=span))
  }
}

///|
/// Dispatch a built-in by name. New builtins are added to this match;
/// unknown names land in the catch-all and surface a clear error so
/// the missing-binding bug is easy to track down.
fn call_builtin(
  name : String,
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  match name {
    "reverse" => builtin_reverse(args, span)
    "repeat" => builtin_repeat(args, span)
    "rotate" => builtin_rotate(args, span)
    "double_time" => builtin_double_time(args, span)
    other =>
      Err(
        Custom(
          message="unknown builtin: " + other,
          span=span,
        ),
      )
  }
}

///|
/// `rotate : Int -> Block -> Block` — shift slots left by `n` positions.
/// Negative `n` rotates right. Mirrors the Rust crate's
/// `builtin_rotate` which accepts either argument order.
fn builtin_rotate(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(WrongArity(expected=2, got=args.length(), span=span))
  }
  let (n_raw, block) = match (args[0], args[1]) {
    (IntV(n), BlockV(b)) => (n.to_int(), b)
    (BlockV(b), IntV(n)) => (n.to_int(), b)
    _ =>
      return Err(
        TypeError(expected="Int and Block", found="other", span=span),
      )
  }
  let len = block.slots().length()
  if len == 0 {
    return Ok(BlockV(block))
  }
  // Normalise n to [0, len) — Moonbit `%` keeps the sign of the dividend.
  let n = ((n_raw % len) + len) % len
  let rotated_slots : Array[@core.Spanned[@ast.Slot]] = []
  let mut i = n
  while i < len {
    rotated_slots.push(block.slots()[i])
    i += 1
  }
  i = 0
  while i < n {
    rotated_slots.push(block.slots()[i])
    i += 1
  }
  let new_block = match block.beats() {
    Some(b) => @ast.Block::with_beats(rotated_slots, b)
    None => @ast.Block::new(rotated_slots)
  }
  Ok(BlockV(new_block))
}

///|
/// `double_time : Block -> Block` — halve the block's beats, keeping
/// the slot list intact. Mirrors `builtin_double_time` in the Rust
/// crate's `block.rs` builtins module.
fn builtin_double_time(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(WrongArity(expected=1, got=args.length(), span=span))
  }
  match args[0] {
    BlockV(block) => {
      let new_beats = match block.beats() {
        Some(b) => b / 2.0
        None => 0.5
      }
      Ok(BlockV(@ast.Block::with_beats(block.slots(), new_beats)))
    }
    _ =>
      Err(TypeError(expected="Block", found="other", span=span))
  }
}

///|
/// `reverse : Block -> Block` — return a block with its slots reversed
/// in source order. The Rust crate matches the same shape; see
/// `crates/relanote_eval/src/builtins/block.rs::builtin_reverse`.
fn builtin_reverse(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 1 {
    return Err(WrongArity(expected=1, got=args.length(), span=span))
  }
  match args[0] {
    BlockV(block) => {
      let reversed_slots : Array[@core.Spanned[@ast.Slot]] = []
      let mut i = block.slots().length() - 1
      while i >= 0 {
        reversed_slots.push(block.slots()[i])
        i -= 1
      }
      let new_block = match block.beats() {
        Some(b) => @ast.Block::with_beats(reversed_slots, b)
        None => @ast.Block::new(reversed_slots)
      }
      Ok(BlockV(new_block))
    }
    _ =>
      Err(
        TypeError(expected="Block", found="other", span=span),
      )
  }
}

///|
/// `repeat : Int -> Block -> Block` — repeat the slots `n` times. The
/// resulting block's beats scale by `n`.
fn builtin_repeat(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(WrongArity(expected=2, got=args.length(), span=span))
  }
  // Support both argument orders: (Int, Block) and (Block, Int) so
  // pipe and direct application both feel natural.
  let (n, block) = match (args[0], args[1]) {
    (IntV(n), BlockV(b)) => (n.to_int(), b)
    (BlockV(b), IntV(n)) => (n.to_int(), b)
    _ =>
      return Err(
        TypeError(expected="Int and Block", found="other", span=span),
      )
  }
  let new_slots : Array[@core.Spanned[@ast.Slot]] = []
  let mut k = 0
  while k < n {
    for slot in block.slots() {
      new_slots.push(slot)
    }
    k += 1
  }
  let new_block = match block.beats() {
    Some(b) => @ast.Block::with_beats(new_slots, b * n.to_double())
    None => @ast.Block::new(new_slots)
  }
  Ok(BlockV(new_block))
}

///|
/// Bind `args` against `params` inside a fresh child of `captured`,
/// then evaluate `body`. Currently supports plain identifier
/// parameters — destructuring patterns land alongside the inference
/// walker's full pattern story.
fn Evaluator::run_function(
  self : Evaluator,
  params : Array[@core.Spanned[@ast.Pattern]],
  body : @core.Spanned[@ast.Expr],
  captured : Env,
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != params.length() {
    return Err(WrongArity(expected=params.length(), got=args.length(), span=span))
  }
  let call_env = Env::with_parent(captured)
  let mut i = 0
  while i < params.length() {
    match params[i].node() {
      Ident(ident) => call_env.bind(ident.name(), args[i])
      _ => () // wildcards / tuples land with the pattern matcher
    }
    i += 1
  }
  // Swap the active env so the body sees the call frame.
  let outer = self.env
  self.set_env(call_env)
  let result = self.eval_expr(body)
  self.set_env(outer)
  result
}

///|
/// Convert an `AbsolutePitchLit` into a MIDI note number. Middle C is
/// 60; A4 is 69. Letters are A..G, accidentals are signed semitone
/// offsets (sharps positive, flats negative).
fn absolute_pitch_to_midi(lit : @ast.AbsolutePitchLit) -> Int {
  let letter = match lit.note() {
    'C' => 0
    'D' => 2
    'E' => 4
    'F' => 5
    'G' => 7
    'A' => 9
    'B' => 11
    _ => 0
  }
  // Octave 0 is MIDI 12 (so C4 = 60).
  (lit.octave() + 1) * 12 + letter + lit.accidental()
}

///|
/// Seed builtin bindings into the runtime environment. The Rust crate
/// evaluates the relanote-source prelude (`@stdlib.PRELUDE`) for scale
/// / chord / synth definitions; this port seeds the host-implemented
/// combinators directly as `BuiltinV` values. Future sub-PRs will
/// expand the set; the long-tail scale / chord / synth presets land
/// once the parser / evaluator can drive the stdlib text.
fn install_prelude(env : Env) -> Unit {
  env.bind("reverse", BuiltinV("reverse"))
  env.bind("repeat", BuiltinV("repeat"))
  env.bind("rotate", BuiltinV("rotate"))
  env.bind("double_time", BuiltinV("double_time"))
  // TODO(#8): parse + evaluate `@stdlib.PRELUDE` once block resolution
  // is in place, to bind the scale / chord / synth presets.
  let _ = @stdlib.PRELUDE
}
