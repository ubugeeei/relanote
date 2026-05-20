///|
test "check_program reports undefined variable" {
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::ExprStmt(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("undefined_xyz")),
          @core.Span::dummy(),
        ),
      ),
      @core.Span::dummy(),
    ),
  ])
  let checker = TypeChecker::new()
  let errors = checker.check_program(program)
  assert_eq(errors.length(), 1)
  match errors[0] {
    UndefinedVariable(name~, ..) => assert_eq(name, "undefined_xyz")
    other => abort("expected UndefinedVariable, got " + other.message())
  }
}

///|
test "check_program accepts integer literal as no-op item" {
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::ExprStmt(
        @core.Spanned::new(@ast.Expr::Integer(42L), @core.Span::dummy()),
      ),
      @core.Span::dummy(),
    ),
  ])
  let checker = TypeChecker::new()
  let errors = checker.check_program(program)
  assert_eq(errors.length(), 0)
}

///|
test "check_program binds let value type for downstream lookups" {
  let pattern = @core.Spanned::new(
    @ast.Pattern::Ident(@ast.Ident::new("x")),
    @core.Span::dummy(),
  )
  let value = @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy())
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::LetBinding(@ast.LetBinding::new(pattern, None, value)),
      @core.Span::dummy(),
    ),
  ])
  let checker = TypeChecker::new()
  let _ = checker.check_program(program)
  match checker.lookup_type("x") {
    Some(IntTy) => ()
    Some(other) => abort("x should be Int, got " + other.to_display_string())
    None => abort("x should be bound after check_program")
  }
}

///|
test "infer_expr flags type mismatch in if branches" {
  let condition = @core.Spanned::new(
    @ast.Expr::BoolLit(true),
    @core.Span::dummy(),
  )
  let then_branch = @core.Spanned::new(
    @ast.Expr::Integer(1L),
    @core.Span::dummy(),
  )
  let else_branch = @core.Spanned::new(
    @ast.Expr::BoolLit(false),
    @core.Span::dummy(),
  )
  let if_expr = @core.Spanned::new(
    @ast.Expr::If(@ast.IfExpr::new(condition, then_branch, Some(else_branch))),
    @core.Span::dummy(),
  )
  let ctx = TypeContext::new()
  match ctx.infer_expr(if_expr) {
    Ok(t) => abort("expected mismatch, inferred " + t.to_display_string())
    Err(UnificationError(_, _, _)) => ()
    Err(Mismatch(..)) => ()
    Err(other) => abort("expected unification error, got " + other.message())
  }
}

///|
test "install_prelude seeds compose : [Section] -> Song" {
  let checker = TypeChecker::new()
  match checker.context().lookup("compose") {
    Some(scheme) =>
      match scheme.ty() {
        Function(ArrayTy(Section), Song) => ()
        other =>
          abort("expected [Section] -> Song, got " + other.to_display_string())
      }
    None => abort("expected compose to be in scope")
  }
}
