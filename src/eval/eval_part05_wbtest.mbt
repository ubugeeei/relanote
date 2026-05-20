///|
test "Over expression returns the left value" {
  let ev = Evaluator::new()
  let three = @core.Spanned::new(@ast.Expr::Integer(3L), @core.Span::dummy())
  let four = @core.Spanned::new(@ast.Expr::Integer(4L), @core.Span::dummy())
  let expr = @core.Spanned::new(
    @ast.Expr::Over(three, four),
    @core.Span::dummy(),
  )
  match ev.eval_expr(expr) {
    Ok(IntV(3L)) => ()
    _ => abort("expected over to surface the left side")
  }
}

///|
test "Error expression evaluates to Placeholder" {
  let ev = Evaluator::new()
  let expr = @core.Spanned::new(@ast.Expr::Error, @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(Placeholder) => ()
    _ => abort("expected Placeholder for error-recovery node")
  }
}

///|
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

///|
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
      @ast.Application::new(lambda, [
        @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
        @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy()),
      ]),
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
