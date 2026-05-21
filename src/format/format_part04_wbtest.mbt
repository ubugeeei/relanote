///|
test "formatter covers part section and layer expressions" {
  let body = spanned(
    @ast.Expr::Block(
      @ast.Block::new([
        spanned(
          @ast.Slot::Note(
            pitch=spanned(@ast.Pitch::Root),
            articulations=[],
            duration=None,
          ),
        ),
      ]),
    ),
  )
  assert_eq(
    expr_source(
      @ast.Expr::Part(
        @ast.PartExpr::new(spanned(@ast.Expr::StringLit("pad")), Some(body)),
      ),
    ),
    "part \"pad\" { | R | }\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Part(
        @ast.PartExpr::new(spanned(@ast.Expr::StringLit("bass")), None),
      ),
    ),
    "part \"bass\"\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Section(
        @ast.SectionExpr::new(
          spanned(@ast.Expr::StringLit("A")),
          None,
          spanned(id_expr("melody")),
        ),
      ),
    ),
    "section \"A\" { melody }\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Layer(
        @ast.LayerExpr::new([spanned(id_expr("lead")), spanned(id_expr("bass"))]),
      ),
    ),
    "layer [lead, bass]\n",
  )
}
