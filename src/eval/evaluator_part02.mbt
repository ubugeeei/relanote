///|
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
        (IntV(_), IntV(0L)) => Err(DivisionByZero(span~))
        (IntV(a), IntV(b)) => Ok(IntV(a / b))
        (FloatV(a), FloatV(b)) => Ok(FloatV(a / b))
        _ => Err(TypeError(expected="numeric", found="other", span~))
      }
    Mod =>
      match (left, right) {
        (IntV(_), IntV(0L)) => Err(DivisionByZero(span~))
        (IntV(a), IntV(b)) => Ok(IntV(a % b))
        _ => Err(TypeError(expected="Int", found="other", span~))
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
        _ => Err(TypeError(expected="Bool", found="other", span~))
      }
    Or =>
      match (left, right) {
        (BoolV(a), BoolV(b)) => Ok(BoolV(a || b))
        _ => Err(TypeError(expected="Bool", found="other", span~))
      }
    Concat => eval_concat(left, right, span)
    // Function composition lands with the full callable value model.
    Compose => Ok(Placeholder)
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
    _ => Err(TypeError(expected="numeric", found="other", span~))
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
    _ => Err(TypeError(expected="numeric", found="other", span~))
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
        _ => Err(TypeError(expected="numeric", found="other", span~))
      }
    Not =>
      match operand {
        BoolV(b) => Ok(BoolV(!b))
        _ => Err(TypeError(expected="Bool", found="other", span~))
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
        // `if c then a` with no else returns Unit, matching the legacy implementation.
        None => Ok(UnitV)
      }
    _ => Err(TypeError(expected="Bool", found="other", span~))
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
        Err(IndexOutOfBounds(index=i, len=n, span~))
      } else {
        Ok(elems[i.to_int()])
      }
    }
    (TupleV(elems), IntV(i)) => {
      let n = elems.length()
      if i < 0L || i.to_int() >= n {
        Err(IndexOutOfBounds(index=i, len=n, span~))
      } else {
        Ok(elems[i.to_int()])
      }
    }
    _ =>
      Err(
        TypeError(
          expected="Array or Tuple with Int index",
          found="other",
          span~,
        ),
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
