///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
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

///|
test "Articulation expression evaluates to ArticulationV" {
  let ev = Evaluator::new()
  let expr = @core.Spanned::new(
    @ast.Expr::Articulation(@ast.Articulation::Accent),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(ArticulationV(@ast.Articulation::Accent)) => ()
    _ => abort("expected ArticulationV(Accent)")
  }
}

///|
test "Layer expression evaluates to LayerV" {
  let ev = Evaluator::new()
  let layer = @ast.LayerExpr::new([])
  let expr = @core.Spanned::new(@ast.Expr::Layer(layer), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(LayerV(_)) => ()
    _ => abort("expected LayerV")
  }
}

///|
test "With expression returns the base" {
  let ev = Evaluator::new()
  let base = @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy())
  let with_expr = @ast.WithExpr::new(base, [])
  let expr = @core.Spanned::new(@ast.Expr::With(with_expr), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(IntV(42L)) => ()
    _ => abort("expected with-expr to return the base IntV(42)")
  }
}

///|
