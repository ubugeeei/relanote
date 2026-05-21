///|
test "formatter covers music pitch and slot variants" {
  let modified : @ast.Slot = @ast.Note(
    pitch=spanned(@ast.Pitch::ScaleIndexMod(4, [@lexer.Sharp, @lexer.Flat])),
    articulations=[@ast.Accent],
    duration=Some(2),
  )
  let chord : @ast.Slot = @ast.Chord(
    pitches=[
      spanned(@ast.Pitch::Root),
      spanned(
        @ast.Pitch::MicrotonalInterval(
          @ast.IntervalLit::new(@lexer.Major, 3),
          -5.0,
        ),
      ),
      spanned(@ast.Pitch::ScaleIndexCents(3, 12.5)),
    ],
    articulations=[@ast.Portamento],
    duration=Some(4),
  )
  assert_eq(
    expr_source(
      @ast.Expr::Block(
        @ast.Block::new([
          spanned(modified),
          spanned(chord),
          spanned(@ast.Slot::Rest(duration=Some(3))),
        ]),
      ),
    ),
    "| <4+->^:2 [R M3 -5c <3 +12.5c>]~:4 -:3 |\n",
  )
  let tuplet = @ast.Tuplet::new(
    [
      spanned(
        @ast.Slot::Note(
          pitch=spanned(@ast.Pitch::Microtone(-12.5)),
          articulations=[],
          duration=None,
        ),
      ),
      spanned(@ast.Slot::Rest(duration=None)),
    ],
    spanned(int_expr(3L)),
  )
  assert_eq(expr_source(@ast.Expr::Tuplet(tuplet)), "{ -12.5c - }:3\n")
  assert_eq(
    expr_source(
      @ast.Expr::Envelope(
        @ast.EnvelopeLit::new(
          spanned(int_expr(0L)),
          spanned(int_expr(1L)),
          spanned(@ast.Expr::Float(0.25)),
        ),
      ),
    ),
    "env(0, 1, 0.25)\n",
  )
}
