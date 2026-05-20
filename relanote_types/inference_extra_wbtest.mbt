///|
fn sexpr(e : @ast.Expr) -> @core.Spanned[@ast.Expr] {
  @core.Spanned::new(e, @core.Span::dummy())
}

///|
fn spat(p : @ast.Pattern) -> @core.Spanned[@ast.Pattern] {
  @core.Spanned::new(p, @core.Span::dummy())
}

///|
fn infer_ok(ctx : TypeContext, e : @ast.Expr) -> Type {
  match ctx.infer_expr(sexpr(e)) {
    Ok(t) => ctx.apply(t)
    Err(err) => abort("inference failed: " + err.message())
  }
}

///|
test "infer literals and simple wrappers" {
  let ctx = TypeContext::new()
  match infer_ok(ctx, @ast.Expr::Float(1.5)) {
    FloatTy => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::StringLit("hi")) {
    StringTy => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::UnitLit) {
    Unit => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::Paren(sexpr(@ast.Expr::BoolLit(true)))) {
    BoolTy => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::Annotated(
    sexpr(@ast.Expr::Integer(1L)),
    @ast.Named(@ast.Ident::new("Int")),
  )) {
    IntTy => ()
    other => abort(other.to_display_string())
  }
}

///|
test "infer operators and collections" {
  let ctx = TypeContext::new()
  match infer_ok(ctx, @ast.Expr::Binary(@ast.Binary::new(
    @ast.Mul,
    sexpr(@ast.Expr::Integer(2L)),
    sexpr(@ast.Expr::Integer(3L)),
  ))) {
    IntTy => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::Binary(@ast.Binary::new(
    @ast.And,
    sexpr(@ast.Expr::BoolLit(true)),
    sexpr(@ast.Expr::BoolLit(false)),
  ))) {
    BoolTy => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::Tuple([
    sexpr(@ast.Expr::Integer(1L)), sexpr(@ast.Expr::BoolLit(true)),
  ])) {
    Tuple(items) => assert_eq(items.length(), 2)
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::Index(@ast.Index::new(
    sexpr(@ast.Expr::Array([sexpr(@ast.Expr::Integer(1L))])),
    sexpr(@ast.Expr::Integer(0L)),
  ))) {
    IntTy => ()
    other => abort(other.to_display_string())
  }
}

///|
test "infer lambda application pipe and composition" {
  let ctx = TypeContext::new()
  let x = spat(@ast.Pattern::Ident(@ast.Ident::new("x")))
  let lambda = @ast.Expr::Lambda(@ast.Lambda::new(
    [x],
    sexpr(@ast.Expr::Ident(@ast.Ident::new("x"))),
  ))
  match infer_ok(ctx, @ast.Expr::Application(@ast.Application::new(
    sexpr(lambda),
    [sexpr(@ast.Expr::Integer(9L))],
  ))) {
    IntTy => ()
    other => abort(other.to_display_string())
  }
  ctx.bind_mono("is_ready", Function(IntTy, BoolTy))
  match infer_ok(ctx, @ast.Expr::Pipe(@ast.Pipe::new(
    sexpr(@ast.Expr::Integer(1L)),
    sexpr(@ast.Expr::Ident(@ast.Ident::new("is_ready"))),
  ))) {
    BoolTy => ()
    other => abort(other.to_display_string())
  }
  ctx.bind_mono("to_bool", Function(IntTy, BoolTy))
  ctx.bind_mono("to_text", Function(BoolTy, StringTy))
  let composed = @ast.Expr::Binary(@ast.Binary::new(
    @ast.Compose,
    sexpr(@ast.Expr::Ident(@ast.Ident::new("to_bool"))),
    sexpr(@ast.Expr::Ident(@ast.Ident::new("to_text"))),
  ))
  match infer_ok(ctx, composed) {
    Function(IntTy, StringTy) => ()
    other => abort(other.to_display_string())
  }
}

///|
test "infer control flow match and special music forms" {
  let ctx = TypeContext::new()
  let let_expr = @ast.Expr::Let(@ast.LetExpr::new(
    spat(@ast.Pattern::Ident(@ast.Ident::new("n"))),
    None,
    sexpr(@ast.Expr::Integer(5L)),
    sexpr(@ast.Expr::Ident(@ast.Ident::new("n"))),
  ))
  match infer_ok(ctx, let_expr) {
    IntTy => ()
    other => abort(other.to_display_string())
  }
  let arm = @ast.MatchArm::new(
    spat(@ast.Pattern::Literal(@ast.LiteralPattern::Integer(5L))),
    Some(sexpr(@ast.Expr::BoolLit(true))),
    sexpr(@ast.Expr::StringLit("five")),
  )
  match infer_ok(ctx, @ast.Expr::Match(@ast.MatchExpr::new(
    sexpr(@ast.Expr::Integer(5L)),
    [arm],
  ))) {
    StringTy => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::InScale(@ast.InScaleExpr::new(
    sexpr(@ast.Expr::Array([])),
  ))) {
    Function(Block, Block) => ()
    other => abort(other.to_display_string())
  }
  match infer_ok(ctx, @ast.Expr::With(@ast.WithExpr::new(
    sexpr(@ast.Expr::Block(@ast.Block::empty())),
    [],
  ))) {
    Block => ()
    other => abort(other.to_display_string())
  }
}

///|
test "infer patterns and error branches" {
  let ctx = TypeContext::new()
  match ctx.infer_pattern(spat(@ast.Pattern::Tuple([
    spat(@ast.Pattern::Literal(@ast.LiteralPattern::Integer(1L))),
    spat(@ast.Pattern::Literal(@ast.LiteralPattern::BoolLit(true))),
  ]))) {
    Ok(Tuple(items)) => assert_eq(items.length(), 2)
    Ok(other) => abort(other.to_display_string())
    Err(err) => abort(err.message())
  }
  match ctx.infer_pattern(spat(@ast.Pattern::Array(@ast.ArrayPattern::new([
    spat(@ast.Pattern::Literal(@ast.LiteralPattern::Integer(1L))),
    spat(@ast.Pattern::Literal(@ast.LiteralPattern::Integer(2L))),
  ], None)))) {
    Ok(ArrayTy(IntTy)) => ()
    Ok(other) => abort(other.to_display_string())
    Err(err) => abort(err.message())
  }
  match ctx.infer_expr(sexpr(@ast.Expr::Unary(@ast.Unary::new(
    @ast.Not,
    sexpr(@ast.Expr::Integer(1L)),
  )))) {
    Err(_) => ()
    Ok(t) => abort("expected error, got " + t.to_display_string())
  }
}
