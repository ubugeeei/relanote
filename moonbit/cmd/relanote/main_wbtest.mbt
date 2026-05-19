// Whitebox tests for the CLI glue. The subcommand entry points print to
// stdout and aren't directly observable; the type-check helper returns
// its error list so we can exercise the wiring.

test "run_type_check reports undefined identifier" {
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::ExprStmt(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("totally_undefined")),
          @core.Span::dummy(),
        ),
      ),
      @core.Span::dummy(),
    ),
  ])
  let errors = run_type_check_for_test(program)
  assert_eq(errors.length(), 1)
}

test "run_type_check is silent on a well-typed builtin call" {
  // `reverse` is bound by `install_prelude` (#54) as `Block -> Block`.
  // Calling it on a literal block should type-check cleanly.
  let block_expr = @core.Spanned::new(
    @ast.Expr::Block(@ast.Block::new([])),
    @core.Span::dummy(),
  )
  let reverse_call = @core.Spanned::new(
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
  let program = @ast.Program::new([
    @core.Spanned::new(
      @ast.Item::ExprStmt(reverse_call),
      @core.Span::dummy(),
    ),
  ])
  let errors = run_type_check_for_test(program)
  assert_eq(errors.length(), 0)
}
