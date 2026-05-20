///|
test "TuningDef::Ratios round-trips ratio pairs" {
  let ratios : Array[(Int, Int)] = [(1, 1), (9, 8), (5, 4), (4, 3)]
  let t = TuningDef::new(Ident::new("JustIntonation"), Ratios(ratios))
  match t.mode() {
    Ratios(rs) => assert_eq(rs.length(), 4)
    _ => abort("expected Ratios mode")
  }
}

///|
test "GrooveDef captures per-slot offsets" {
  let g = GrooveDef::new(Ident::new("Swing67"), 2, [0.0, 0.17])
  assert_eq(g.length(), 2)
  assert_eq(g.steps().length(), 2)
  assert_eq(g.steps()[1], 0.17)
}

///|
test "MixDef::empty has no tracks or buses" {
  let m = MixDef::empty()
  assert_eq(m.tracks().length(), 0)
  assert_eq(m.buses().length(), 0)
  // `Spanned[T]` doesn't derive `Eq`, so `Option[Spanned[Expr]] == None`
  // needs an explicit match instead of a `==` comparison.
  match m.master() {
    None => ()
    Some(_) => abort("expected MixDef::empty to have no master")
  }
}

///|
test "MixDef::new threads tracks / buses / sends / sidechains" {
  let span = @core.Span::dummy()
  let track : @core.Spanned[Expr] = @core.Spanned::new(
    Ident(Ident::new("lead")),
    span,
  )
  let chain : @core.Spanned[Expr] = @core.Spanned::new(
    Ident(Ident::new("DubDelay")),
    span,
  )
  let bus = BusDef::new(Ident::new("Verb"), chain)
  let amount : @core.Spanned[Expr] = @core.Spanned::new(Expr::Float(0.3), span)
  let send = SendDef::new(Ident::new("Verb"), amount)
  let sc_amt : @core.Spanned[Expr] = @core.Spanned::new(Expr::Float(0.5), span)
  let sc = SidechainDef::new(Ident::new("kick"), Ident::new("bass"), sc_amt)
  let m = MixDef::new([track], [bus], [send], [sc], None)
  assert_eq(m.tracks().length(), 1)
  assert_eq(m.buses().length(), 1)
  assert_eq(m.sends().length(), 1)
  assert_eq(m.sidechains().length(), 1)
}

///|
test "Expr::Over constructs a polyrhythm node" {
  let span = @core.Span::dummy()
  let three : @core.Spanned[Expr] = @core.Spanned::new(Expr::Integer(3L), span)
  let four : @core.Spanned[Expr] = @core.Spanned::new(Expr::Integer(4L), span)
  let poly = Expr::Over(three, four)
  match poly {
    Over(_, _) => ()
    _ => abort("expected Over variant")
  }
}
