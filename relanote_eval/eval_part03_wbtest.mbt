///|
test "Builtin rotate(1) shifts a 3-slot block left by one" {
  let ev = Evaluator::new()
  let a = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(1), @core.Span::dummy()),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let b = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(2), @core.Span::dummy()),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let c = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(3), @core.Span::dummy()),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let block = @ast.Block::new([a, b, c])
  let call = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("rotate")),
          @core.Span::dummy(),
        ),
        [
          @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
          @core.Spanned::new(@ast.Expr::Block(block), @core.Span::dummy()),
        ],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(call) {
    Ok(BlockV(b)) =>
      match b.slots()[0].node() {
        Note(pitch~, ..) =>
          match pitch.node() {
            ScaleIndex(2) => ()
            _ => abort("expected ScaleIndex(2) at slot 0 after rotate(1)")
          }
        _ => abort("expected a Note at slot 0")
      }
    _ => abort("expected rotate to return BlockV")
  }
}

///|
test "Builtin double_time halves the block beats" {
  let ev = Evaluator::new()
  let block = @ast.Block::with_beats([], 4.0)
  let call = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("double_time")),
          @core.Span::dummy(),
        ),
        [@core.Spanned::new(@ast.Expr::Block(block), @core.Span::dummy())],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(call) {
    Ok(BlockV(b)) =>
      match b.beats() {
        Some(2.0) => ()
        _ => abort("expected beats halved to 2.0")
      }
    _ => abort("expected double_time to return BlockV")
  }
}

///|
test "Prelude binds rotate and double_time as BuiltinV" {
  let ev = Evaluator::new()
  match ev.env().lookup("rotate") {
    Some(BuiltinV("rotate")) => ()
    _ => abort("expected rotate BuiltinV")
  }
  match ev.env().lookup("double_time") {
    Some(BuiltinV("double_time")) => ()
    _ => abort("expected double_time BuiltinV")
  }
}

///|
test "Builtin octave_up shifts every ScaleIndex by 7" {
  let ev = Evaluator::new()
  let one = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(@ast.Pitch::ScaleIndex(1), @core.Span::dummy()),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let block = @ast.Block::new([one])
  let call = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("octave_up")),
          @core.Span::dummy(),
        ),
        [@core.Spanned::new(@ast.Expr::Block(block), @core.Span::dummy())],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(call) {
    Ok(BlockV(b)) =>
      match b.slots()[0].node() {
        Note(pitch~, ..) =>
          match pitch.node() {
            ScaleIndex(8) => ()
            ScaleIndex(n) =>
              abort("expected ScaleIndex(8), got " + n.to_string())
            _ => abort("expected ScaleIndex pitch")
          }
        _ => abort("expected Note slot")
      }
    _ => abort("expected octave_up to return BlockV")
  }
}

///|
test "Builtin octave_down shifts Microtone by -1200 cents" {
  let ev = Evaluator::new()
  let slot = @core.Spanned::new(
    @ast.Slot::Note(
      pitch=@core.Spanned::new(
        @ast.Pitch::Microtone(550.0),
        @core.Span::dummy(),
      ),
      articulations=[],
      duration=None,
    ),
    @core.Span::dummy(),
  )
  let block = @ast.Block::new([slot])
  let call = @core.Spanned::new(
    @ast.Expr::Application(
      @ast.Application::new(
        @core.Spanned::new(
          @ast.Expr::Ident(@ast.Ident::new("octave_down")),
          @core.Span::dummy(),
        ),
        [@core.Spanned::new(@ast.Expr::Block(block), @core.Span::dummy())],
      ),
    ),
    @core.Span::dummy(),
  )
  match ev.eval_expr(call) {
    Ok(BlockV(b)) =>
      match b.slots()[0].node() {
        Note(pitch~, ..) =>
          match pitch.node() {
            Microtone(-650.0) => ()
            Microtone(c) => abort("expected -650.0 cents, got " + c.to_string())
            _ => abort("expected Microtone pitch")
          }
        _ => abort("expected Note slot")
      }
    _ => abort("expected octave_down to return BlockV")
  }
}

///|
test "Array literal evaluates element-wise" {
  let ev = Evaluator::new()
  let elements : Array[@core.Spanned[@ast.Expr]] = [
    @core.Spanned::new(@ast.Expr::Integer(1L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(2L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::Integer(3L), @core.Span::dummy()),
  ]
  let expr = @core.Spanned::new(@ast.Expr::Array(elements), @core.Span::dummy())
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

///|
test "Tuple literal evaluates element-wise" {
  let ev = Evaluator::new()
  let elements : Array[@core.Spanned[@ast.Expr]] = [
    @core.Spanned::new(@ast.Expr::Integer(7L), @core.Span::dummy()),
    @core.Spanned::new(@ast.Expr::BoolLit(true), @core.Span::dummy()),
  ]
  let expr = @core.Spanned::new(@ast.Expr::Tuple(elements), @core.Span::dummy())
  match ev.eval_expr(expr) {
    Ok(TupleV(vs)) => assert_eq(vs.length(), 2)
    _ => abort("expected TupleV")
  }
}

///|
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

///|
