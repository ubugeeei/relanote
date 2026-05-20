///|
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
  let x_value = @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy())
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

///|
test "Calling a non-function reports NotAFunction" {
  let ev = Evaluator::new()
  let app = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(@ast.Expr::Integer(5L), @core.Span::dummy()),
        [@core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy())],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(app) {
    Ok(_) => abort("calling 5 should not succeed")
    Err(NotAFunction(_)) => ()
    Err(other) => abort("expected NotAFunction, got " + other.message())
  }
}

///|
test "Prelude binds reverse as a BuiltinV" {
  let ev = Evaluator::new()
  match ev.env().lookup("reverse") {
    Some(BuiltinV("reverse")) => ()
    _ => abort("expected reverse to be a BuiltinV")
  }
}

///|
test "Builtin reverse on a 3-note block reverses the slots" {
  let ev = Evaluator::new()
  let one = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(1), @core.Span::dummy()),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let two = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(2), @core.Span::dummy()),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let three = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(3), @core.Span::dummy()),
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

///|
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
  let two = @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy())
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

///|
test "Unknown builtin name surfaces a clear error" {
  let span = @core.Span::dummy()
  match call_builtin("not_a_builtin", [], span) {
    Ok(_) => abort("expected an error for an unknown builtin")
    Err(Custom(message~, ..)) =>
      assert_true(message.has_prefix("unknown builtin"))
    Err(other) => abort("expected Custom error, got " + other.message())
  }
}

///|
