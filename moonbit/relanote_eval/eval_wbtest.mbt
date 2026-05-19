// `Value` no longer derives `Eq` (its variants now carry AST nodes that
// don't have value equality), so these tests pattern-match on lookups
// instead of using `==`.

test "Env::new is empty" {
  let env = Env::new()
  match env.lookup("x") {
    None => ()
    Some(_) => abort("expected empty env")
  }
}

test "Env::bind / lookup" {
  let env = Env::new()
  env.bind("x", IntV(42L))
  match env.lookup("x") {
    Some(IntV(42L)) => ()
    _ => abort("expected x = 42")
  }
}

test "Env::with_parent falls back to parent scope" {
  let outer = Env::new()
  outer.bind("x", IntV(1L))
  let inner = Env::with_parent(outer)
  match inner.lookup("x") {
    Some(IntV(1L)) => ()
    _ => abort("expected parent x = 1")
  }
  inner.bind("x", IntV(2L))
  match inner.lookup("x") {
    Some(IntV(2L)) => ()
    _ => abort("expected shadowed x = 2")
  }
}

test "Evaluator::eval_program returns UnitV on an empty program" {
  let ev = Evaluator::new()
  let prog = @ast.Program::empty()
  match ev.eval_program(prog) {
    Ok(UnitV) => ()
    Ok(_) => abort("expected UnitV")
    Err(_) => abort("empty program should not fail")
  }
}

test "Evaluator::eval_program threads the final expression" {
  let ev = Evaluator::new()
  let stmt : @ast.Item = @ast.ExprStmt(
    @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy()),
  )
  let prog = @ast.Program::new([
    @core.Spanned::new(stmt, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(IntV(7L)) => ()
    Ok(_) => abort("expected the last expression to surface")
    Err(_) => abort("integer literal should evaluate")
  }
}

test "Evaluator binds let value into the environment" {
  let ev = Evaluator::new()
  let pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("count")),
    @core.Span::dummy(),
  )
  let value = @core.Spanned::new(
    @ast.Expr::Integer(11L),
    @core.Span::dummy(),
  )
  let item : @ast.Item = @ast.LetBinding(
    @ast.LetBinding::new(pat, None, value),
  )
  let prog = @ast.Program::new([
    @core.Spanned::new(item, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(_) => ()
    Err(e) => abort("let binding should evaluate: " + e.message())
  }
  match ev.env().lookup("count") {
    Some(IntV(11L)) => ()
    _ => abort("expected count = 11 in the env after let")
  }
}

test "Evaluator binds scale def by name" {
  let ev = Evaluator::new()
  let def = @ast.ScaleDef::new(@ast.Ident::new("Mode"), None, [])
  let item : @ast.Item = @ast.ScaleDef(def)
  let prog = @ast.Program::new([
    @core.Spanned::new(item, @core.Span::dummy()),
  ])
  let _ = ev.eval_program(prog)
  match ev.env().lookup("Mode") {
    Some(ScaleV(_)) => ()
    _ => abort("expected Mode to be a ScaleV")
  }
}

test "Evaluator reports undefined identifier" {
  let ev = Evaluator::new()
  let expr_item : @ast.Item = @ast.ExprStmt(
    @core.Spanned::new(
      @ast.Expr::Ident(@ast.Ident::new("nope")),
      @core.Span::dummy(),
    ),
  )
  let prog = @ast.Program::new([
    @core.Spanned::new(expr_item, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(_) => abort("expected an UndefinedVariable error")
    Err(UndefinedVariable(name~, ..)) => assert_eq(name, "nope")
    Err(other) =>
      abort("expected UndefinedVariable, got " + other.message())
  }
}

test "EvalError::span is None for module-level errors" {
  let mn = ModuleNotFound(module_name="m", path="p", reason="r")
  assert_true(mn.span() == None)
  let cd = CircularModuleDependency(module_name="m")
  assert_true(cd.span() == None)
}

test "EvalError::message renders WrongArity verbatim" {
  let err = WrongArity(expected=2, got=3, span=@core.Span::dummy())
  assert_eq(err.message(), "wrong number of arguments: expected 2, got 3")
}

test "Interval expr evaluates to a semitone offset" {
  let ev = Evaluator::new()
  let m3 = @ast.IntervalLit::new(@lexer.Major, 3)
  let expr = @core.Spanned::new(
    @ast.Expr::Interval(m3),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(IntervalV(4)) => ()
    Ok(IntervalV(n)) =>
      abort("expected M3 = 4 semitones, got " + n.to_string())
    _ => abort("expected an IntervalV from M3")
  }
}

test "Absolute pitch C4 lifts to MIDI 60" {
  let ev = Evaluator::new()
  let c4 = @ast.AbsolutePitchLit::new('C', 0, 4)
  let expr = @core.Spanned::new(
    @ast.Expr::AbsolutePitch(c4),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(AbsolutePitchV(60)) => ()
    Ok(AbsolutePitchV(n)) =>
      abort("expected C4 = 60, got " + n.to_string())
    _ => abort("expected an AbsolutePitchV from C4")
  }
}

test "Absolute pitch A4 lifts to MIDI 69" {
  let ev = Evaluator::new()
  let a4 = @ast.AbsolutePitchLit::new('A', 0, 4)
  let expr = @core.Spanned::new(
    @ast.Expr::AbsolutePitch(a4),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(AbsolutePitchV(69)) => ()
    Ok(AbsolutePitchV(n)) =>
      abort("expected A4 = 69, got " + n.to_string())
    _ => abort("expected an AbsolutePitchV from A4")
  }
}

test "Block expr surfaces the AST block" {
  let ev = Evaluator::new()
  let block = @ast.Block::new([])
  let expr = @core.Spanned::new(
    @ast.Expr::Block(block),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(BlockV(_)) => ()
    _ => abort("expected a BlockV")
  }
}

test "Root expr produces RootV" {
  let ev = Evaluator::new()
  let expr = @core.Spanned::new(
    @ast.Expr::Root,
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(RootV) => ()
    _ => abort("expected RootV")
  }
}

test "Identity lambda applied to an int returns the int" {
  let ev = Evaluator::new()
  let pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let body = @core.Spanned::new(
    @ast.Expr::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let lambda = @core.Spanned::new(
    @ast.Expr::Lambda(@ast.Lambda::new([pat], body)),
    @core.Span::dummy(),
  )
  let arg = @core.Spanned::new(
    @ast.Expr::Integer(99L),
    @core.Span::dummy(),
  )
  let app = @core.Spanned::new(
    @ast.Expr::Application(@ast.Application::new(lambda, [arg])),
    @core.Span::dummy(),
  )
  match ev.eval_expr(app) {
    Ok(IntV(99L)) => ()
    Ok(_) => abort("expected IntV(99), got something else")
    Err(e) => abort("identity application should not fail: " + e.message())
  }
}

test "Pipe `x |> f` desugars to f(x)" {
  let ev = Evaluator::new()
  // f = \v -> v
  let v_pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("v")),
    @core.Span::dummy(),
  )
  let v_body = @core.Spanned::new(
    @ast.Expr::Ident(@ast.Ident::new("v")),
    @core.Span::dummy(),
  )
  let f_pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("f")),
    @core.Span::dummy(),
  )
  let f_value = @core.Spanned::new(
    @ast.Expr::Lambda(@ast.Lambda::new([v_pat], v_body)),
    @core.Span::dummy(),
  )
  let let_f : @ast.Item = @ast.LetBinding(
    @ast.LetBinding::new(f_pat, None, f_value),
  )
  // x = 7
  let x_pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let x_value = @core.Spanned::new(
    @ast.Expr::Integer(7L),
    @core.Span::dummy(),
  )
  let let_x : @ast.Item = @ast.LetBinding(
    @ast.LetBinding::new(x_pat, None, x_value),
  )
  // x |> f
  let pipe_expr = @core.Spanned::new(
    @ast.Expr::Pipe(
      @ast.Pipe::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("x")),
          @core.Span::dummy(),
        ),
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("f")),
          @core.Span::dummy(),
        ),
      ),
    ),
    @core.Span::dummy(),
  )
  let pipe_stmt : @ast.Item = @ast.ExprStmt(pipe_expr)
  let prog = @ast.Program::new([
    @core.Spanned::new(let_f, @core.Span::dummy()),
    @core.Spanned::new(let_x, @core.Span::dummy()),
    @core.Spanned::new(pipe_stmt, @core.Span::dummy()),
  ])
  match ev.eval_program(prog) {
    Ok(IntV(7L)) => ()
    Ok(_) => abort("expected the pipe to surface 7")
    Err(e) => abort("pipe should not fail: " + e.message())
  }
}

test "Calling a non-function reports NotAFunction" {
  let ev = Evaluator::new()
  let app = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Integer(5L),
          @core.Span::dummy(),
        ),
        [
          @core.Spanned::new(
            @ast.Expr::Integer(1L),
            @core.Span::dummy(),
          ),
        ],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(app) {
    Ok(_) => abort("calling 5 should not succeed")
    Err(NotAFunction(_)) => ()
    Err(other) =>
      abort("expected NotAFunction, got " + other.message())
  }
}

test "Prelude binds reverse as a BuiltinV" {
  let ev = Evaluator::new()
  match ev.env().lookup("reverse") {
    Some(BuiltinV("reverse")) => ()
    _ => abort("expected reverse to be a BuiltinV")
  }
}

test "Builtin reverse on a 3-note block reverses the slots" {
  let ev = Evaluator::new()
  let one = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(
        @ast.Pitch::ScaleIndex(1),
        @core.Span::dummy(),
      ),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let two = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(
        @ast.Pitch::ScaleIndex(2),
        @core.Span::dummy(),
      ),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let three = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(
        @ast.Pitch::ScaleIndex(3),
        @core.Span::dummy(),
      ),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let block_expr = @core.Spanned::new(
    @ast.Expr::Block(@ast.Block::new([one, two, three])),
    @core.Span::dummy(),
  )
  let call_expr = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("reverse")),
          @core.Span::dummy(),
        ),
        [block_expr],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(call_expr) {
    Ok(BlockV(b)) => {
      let slots = b.slots()
      assert_eq(slots.length(), 3)
      // The first slot now holds the pitch that was originally last.
      match slots[0].node() {
        Note(pitch~, ..) =>
          match pitch.node() {
            ScaleIndex(3) => ()
            _ => abort("expected ScaleIndex(3) at slot 0 after reverse")
          }
        _ => abort("expected a Note at slot 0")
      }
    }
    Ok(_) => abort("reverse should return a BlockV")
    Err(e) => abort("reverse should not fail: " + e.message())
  }
}

test "Builtin repeat doubles a 2-slot block to 4 slots" {
  let ev = Evaluator::new()
  let rest = @core.Spanned::new(
    @ast.Slot::Rest(duration=None),
    @core.Span::dummy(),
  )
  let block = @ast.Block::new([rest, rest])
  let block_expr = @core.Spanned::new(
    @ast.Expr::Block(block),
    @core.Span::dummy(),
  )
  let two = @core.Spanned::new(
    @ast.Expr::Integer(2L),
    @core.Span::dummy(),
  )
  let call_expr = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("repeat")),
          @core.Span::dummy(),
        ),
        [two, block_expr],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(call_expr) {
    Ok(BlockV(b)) => assert_eq(b.slots().length(), 4)
    Ok(_) => abort("repeat should return a BlockV")
    Err(e) => abort("repeat should not fail: " + e.message())
  }
}

test "Unknown builtin name surfaces a clear error" {
  let span = @core.Span::dummy()
  match call_builtin("not_a_builtin", [], span) {
    Ok(_) => abort("expected an error for an unknown builtin")
    Err(Custom(message~, ..)) =>
      assert_true(message.has_prefix("unknown builtin"))
    Err(other) => abort("expected Custom error, got " + other.message())
  }
}

test "Array literal evaluates element-wise" {
  let ev = Evaluator::new()
  let elements : Array[@core.Spanned[@ast.Expr]] = [
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(3L), @core.Span::dummy()),
  ]
  let expr = @core.Spanned::new(
    @ast.Expr::Array(elements),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(ArrayV(vs)) => {
      assert_eq(vs.length(), 3)
      match vs[0] {
        IntV(1L) => ()
        _ => abort("expected IntV(1) at index 0")
      }
    }
    _ => abort("expected ArrayV")
  }
}

test "Tuple literal evaluates element-wise" {
  let ev = Evaluator::new()
  let elements : Array[@core.Spanned[@ast.Expr]] = [
    @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy()),
  ]
  let expr = @core.Spanned::new(
    @ast.Expr::Tuple(elements),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(TupleV(vs)) => assert_eq(vs.length(), 2)
    _ => abort("expected TupleV")
  }
}

test "If true selects the then branch" {
  let ev = Evaluator::new()
  let if_expr = @ast.IfExpr::new(
    @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    Some(@core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy())),
  )
  let expr = @core.Spanned::new(@ast.Expr::If(if_expr), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(IntV(1L)) => ()
    _ => abort("expected then branch (1)")
  }
}

test "If false with no else returns Unit" {
  let ev = Evaluator::new()
  let if_expr = @ast.IfExpr::new(
    @core.Spanned::new(@ast.Expr::BoolLit(false), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    None,
  )
  let expr = @core.Spanned::new(@ast.Expr::If(if_expr), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(UnitV) => ()
    _ => abort("expected UnitV from a no-else falsy if")
  }
}

test "If non-Bool condition is a TypeError" {
  let ev = Evaluator::new()
  let if_expr = @ast.IfExpr::new(
    @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    None,
  )
  let expr = @core.Spanned::new(@ast.Expr::If(if_expr), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(_) => abort("expected a TypeError for non-Bool condition")
    Err(TypeError(_)) => ()
    Err(other) => abort("expected TypeError, got " + other.message())
  }
}

test "Let-in binds and evaluates body in the new scope" {
  let ev = Evaluator::new()
  let let_expr = @ast.LetExpr::new(
    @core.Spanned::new(
      @ast.Pattern::Ident(@ast.Ident::new("x")),
      @core.Span::dummy(),
    ),
    None,
    @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy()),
    @core.Spanned::new(
      @ast.Expr::Ident(@ast.Ident::new("x")),
      @core.Span::dummy(),
    ),
  )
  let expr = @core.Spanned::new(@ast.Expr::Let(let_expr), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(IntV(42L)) => ()
    _ => abort("expected let body to evaluate to 42")
  }
}

test "Array indexing returns the element" {
  let ev = Evaluator::new()
  let arr = @core.Spanned::new(
    @ast.Expr::Array([
      @core.Spanned::new(@ast.Expr::Integer(10L), @core.Span::dummy()),
      @core.Spanned::new(@ast.Expr::Integer(20L), @core.Span::dummy()),
      @core.Spanned::new(@ast.Expr::Integer(30L), @core.Span::dummy()),
    ]),
    @core.Span::dummy(),
  )
  let idx = @core.Spanned::new(
    @ast.Expr::Index(
      @ast.Index::new(
        arr,
        @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(idx) {
    Ok(IntV(20L)) => ()
    _ => abort("expected arr[1] = 20")
  }
}

test "Binary Add on two ints yields IntV" {
  let ev = Evaluator::new()
  let bin = @ast.Binary::new(
    @ast.Add,
    @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(3L), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Binary(bin), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(IntV(5L)) => ()
    _ => abort("expected IntV(5)")
  }
}

test "Binary Mul on two floats yields FloatV" {
  let ev = Evaluator::new()
  let bin = @ast.Binary::new(
    @ast.Mul,
    @core.Spanned::new(@ast.Expr::Float(2.5), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Float(4.0), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Binary(bin), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(FloatV(10.0)) => ()
    _ => abort("expected FloatV(10.0)")
  }
}

test "Binary Div by zero surfaces DivisionByZero" {
  let ev = Evaluator::new()
  let bin = @ast.Binary::new(
    @ast.Div,
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(0L), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Binary(bin), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(_) => abort("expected DivisionByZero")
    Err(DivisionByZero(_)) => ()
    Err(other) => abort("expected DivisionByZero, got " + other.message())
  }
}

test "Binary EqOp returns BoolV for equal ints" {
  let ev = Evaluator::new()
  let bin = @ast.Binary::new(
    @ast.EqOp,
    @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Binary(bin), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(BoolV(true)) => ()
    _ => abort("expected BoolV(true)")
  }
}

test "Binary Lt compares correctly" {
  let ev = Evaluator::new()
  let bin = @ast.Binary::new(
    @ast.Lt,
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Binary(bin), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(BoolV(true)) => ()
    _ => abort("expected BoolV(true)")
  }
}

test "Binary And on two booleans" {
  let ev = Evaluator::new()
  let bin = @ast.Binary::new(
    @ast.And,
    @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::BoolLit(false), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Binary(bin), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(BoolV(false)) => ()
    _ => abort("expected BoolV(false)")
  }
}

test "Unary Neg negates an integer" {
  let ev = Evaluator::new()
  let u = @ast.Unary::new(
    @ast.Neg,
    @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Unary(u), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(IntV(-7L)) => ()
    _ => abort("expected IntV(-7)")
  }
}

test "Unary Not on a Bool" {
  let ev = Evaluator::new()
  let u = @ast.Unary::new(
    @ast.Not,
    @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy()),
  )
  let expr = @core.Spanned::new(@ast.Expr::Unary(u), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(BoolV(false)) => ()
    _ => abort("expected BoolV(false)")
  }
}

test "Out-of-bounds index surfaces IndexOutOfBounds" {
  let ev = Evaluator::new()
  let arr = @core.Spanned::new(
    @ast.Expr::Array([
      @core.Spanned::new(@ast.Expr::Integer(10L), @core.Span::dummy()),
    ]),
    @core.Span::dummy(),
  )
  let idx = @core.Spanned::new(
    @ast.Expr::Index(
      @ast.Index::new(
        arr,
        @core.Spanned::new(@ast.Expr::Integer(99L), @core.Span::dummy()),
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(idx) {
    Ok(_) => abort("expected an IndexOutOfBounds error")
    Err(IndexOutOfBounds(index~, ..)) => assert_eq(index, 99L)
    Err(other) => abort("expected IndexOutOfBounds, got " + other.message())
  }
}

test "Wrong arity reports WrongArity" {
  let ev = Evaluator::new()
  let x_pat = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let body = @core.Spanned::new(
    @ast.Expr::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let lambda = @core.Spanned::new(
    @ast.Expr::Lambda(@ast.Lambda::new([x_pat], body)),
    @core.Span::dummy(),
  )
  let app = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        lambda,
        [
          @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
          @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy()),
        ],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(app) {
    Ok(_) => abort("two args to a 1-arg lambda should fail")
    Err(WrongArity(expected~, got~, ..)) => {
      assert_eq(expected, 1)
      assert_eq(got, 2)
    }
    Err(other) => abort("expected WrongArity, got " + other.message())
  }
}
