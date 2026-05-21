///|
fn expr_program(expr : @ast.Expr) -> @ast.Program {
  @ast.Program::new([spanned(@ast.Item::ExprStmt(spanned(expr)))])
}

///|
fn expr_source(expr : @ast.Expr) -> String {
  format(expr_program(expr), cfg)
}

///|
fn id_expr(name : @core.InternedStr) -> @ast.Expr {
  @ast.Expr::Ident(@ast.Ident::new(name))
}

///|
fn int_expr(n : Int64) -> @ast.Expr {
  @ast.Expr::Integer(n)
}

///|
fn bin_source(op : @ast.BinaryOp) -> String {
  expr_source(
    @ast.Expr::Binary(
      @ast.Binary::new(op, spanned(int_expr(8L)), spanned(int_expr(2L))),
    ),
  )
}

///|
test "formatter covers collection and access expressions" {
  assert_eq(
    expr_source(
      @ast.Expr::Array([
        spanned(int_expr(1L)),
        spanned(@ast.Expr::StringLit("hi")),
        spanned(@ast.Expr::BoolLit(false)),
      ]),
    ),
    "[1, \"hi\", false]\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Tuple([spanned(int_expr(1L)), spanned(int_expr(2L))]),
    ),
    "(1, 2)\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Index(
        @ast.Index::new(spanned(id_expr("seq")), spanned(int_expr(0L))),
      ),
    ),
    "seq[0]\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Field(
        @ast.Field::new(spanned(id_expr("track")), @ast.Ident::new("pan")),
      ),
    ),
    "track.pan\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::AbsolutePitch(@ast.AbsolutePitchLit::new('D', -1, 3)),
    ),
    "Db3\n",
  )
  assert_eq(expr_source(@ast.Expr::Root), "R\n")
  assert_eq(expr_source(@ast.Expr::Articulation(@ast.Portamento)), "~\n")
}

///|
test "formatter covers function operator and control expressions" {
  let lam = @ast.Expr::Lambda(
    @ast.Lambda::new(
      [
        spanned(@ast.Pattern::Ident(@ast.Ident::new("x"))),
        spanned(@ast.Pattern::Wildcard),
      ],
      spanned(id_expr("x")),
    ),
  )
  assert_eq(expr_source(lam), "\\x _ -> x\n")
  let call = @ast.Expr::Application(
    @ast.Application::new(spanned(id_expr("transpose")), [
      spanned(@ast.Expr::Interval(@ast.IntervalLit::new(@lexer.Perfect, 5))),
      spanned(id_expr("melody")),
    ]),
  )
  assert_eq(expr_source(call), "transpose(P5, melody)\n")
  assert_eq(bin_source(@ast.Sub), "8 - 2\n")
  assert_eq(bin_source(@ast.Mul), "8 * 2\n")
  assert_eq(bin_source(@ast.Div), "8 / 2\n")
  assert_eq(bin_source(@ast.Mod), "8 % 2\n")
  assert_eq(bin_source(@ast.EqOp), "8 == 2\n")
  assert_eq(bin_source(@ast.NeOp), "8 != 2\n")
  assert_eq(bin_source(@ast.Lt), "8 < 2\n")
  assert_eq(bin_source(@ast.Le), "8 <= 2\n")
  assert_eq(bin_source(@ast.Gt), "8 > 2\n")
  assert_eq(bin_source(@ast.Ge), "8 >= 2\n")
  assert_eq(bin_source(@ast.And), "8 and 2\n")
  assert_eq(bin_source(@ast.Or), "8 or 2\n")
  assert_eq(bin_source(@ast.Concat), "8 ++ 2\n")
  assert_eq(bin_source(@ast.Compose), "8 >> 2\n")
  assert_eq(
    expr_source(
      @ast.Expr::Unary(
        @ast.Unary::new(@ast.Not, spanned(@ast.Expr::BoolLit(false))),
      ),
    ),
    "not false\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Unary(@ast.Unary::new(@ast.Neg, spanned(int_expr(4L)))),
    ),
    "-4\n",
  )
}

///|
test "formatter covers branches guards and special expressions" {
  let if_expr = @ast.Expr::If(
    @ast.IfExpr::new(
      spanned(@ast.Expr::BoolLit(true)),
      spanned(int_expr(1L)),
      Some(spanned(int_expr(0L))),
    ),
  )
  assert_eq(expr_source(if_expr), "if true then 1 else 0\n")
  let arms : Array[@ast.MatchArm] = [
    @ast.MatchArm::new(
      spanned(@ast.Pattern::Wildcard),
      None,
      spanned(@ast.Expr::StringLit("fallback")),
    ),
    @ast.MatchArm::new(
      spanned(@ast.Pattern::Ident(@ast.Ident::new("n"))),
      Some(
        spanned(
          @ast.Expr::Binary(
            @ast.Binary::new(
              @ast.Gt,
              spanned(id_expr("n")),
              spanned(int_expr(0L)),
            ),
          ),
        ),
      ),
      spanned(id_expr("n")),
    ),
  ]
  assert_eq(
    expr_source(
      @ast.Expr::Match(@ast.MatchExpr::new(spanned(id_expr("x")), arms)),
    ),
    "match x {\n    _ => \"fallback\"\n    n if n > 0 => n\n}\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Let(
        @ast.LetExpr::new(
          spanned(@ast.Pattern::Ident(@ast.Ident::new("x"))),
          None,
          spanned(int_expr(1L)),
          spanned(id_expr("x")),
        ),
      ),
    ),
    "let x = 1 in x\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::With(
        @ast.WithExpr::new(spanned(id_expr("lead")), [
          spanned(id_expr("bright")),
        ]),
      ),
    ),
    "lead with { bright }\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::InScale(@ast.InScaleExpr::new(spanned(id_expr("Dorian")))),
    ),
    "in Dorian\n",
  )
  assert_eq(
    expr_source(
      @ast.Expr::Annotated(
        spanned(id_expr("root")),
        @ast.TypeAnnotation::Named(@ast.Ident::new("Pitch")),
      ),
    ),
    "root : Pitch\n",
  )
  assert_eq(expr_source(@ast.Expr::Paren(spanned(int_expr(7L)))), "(7)\n")
  assert_eq(expr_source(@ast.Expr::Error), "<error>\n")
}

///|
