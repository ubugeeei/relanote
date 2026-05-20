// Whitebox tests for the CLI glue. The subcommand entry points print to
// stdout and aren't directly observable; the type-check helper returns
// its error list so we can exercise the wiring.

///|
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

// End-to-end pipeline tests — parse → type-check → evaluate against
// real source strings. These exercise the same code path the CLI's
// `run` subcommand drives, so they're the closest thing to a smoke
// test we have today.

///|
test "pipeline: integer literal evaluates to itself" {
  match pipeline_for_test("42") {
    Ok(@eval.IntV(42L)) => ()
    Ok(_) => abort("expected IntV(42)")
    Err(e) => abort("pipeline should not fail: " + e)
  }
}

///|
test "pipeline: let binding threads through the env" {
  match pipeline_for_test("let x = 7\nx") {
    Ok(@eval.IntV(7L)) => ()
    Ok(_) => abort("expected IntV(7)")
    Err(e) => abort("pipeline should not fail: " + e)
  }
}

///|
test "pipeline: pipe operator with reverse builtin returns a block" {
  // `reverse` is a Block-only builtin; calling it on a literal block
  // exercises the prelude binding through to the renderer's input.
  match pipeline_for_test("| <1> <3> <5> | |> reverse") {
    Ok(@eval.BlockV(_)) => ()
    Ok(_) => abort("expected a BlockV from the pipe")
    Err(e) => abort("pipe pipeline should not fail: " + e)
  }
}

///|
test "pipeline: undefined identifier surfaces a type error" {
  match pipeline_for_test("totally_undefined") {
    Err("type error") => ()
    Err(other) => abort("expected `type error`, got " + other)
    Ok(_) => abort("expected the pipeline to reject an unbound identifier")
  }
}

///|
test "pipeline: malformed source surfaces a parse error" {
  match pipeline_for_test("let x 1") {
    Err("parse error") => ()
    Err(other) => abort("expected `parse error`, got " + other)
    Ok(_) => abort("expected the pipeline to reject malformed source")
  }
}

///|
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
    @core.Spanned::new(@ast.Item::ExprStmt(reverse_call), @core.Span::dummy()),
  ])
  let errors = run_type_check_for_test(program)
  assert_eq(errors.length(), 0)
}
