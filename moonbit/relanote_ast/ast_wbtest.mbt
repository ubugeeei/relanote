// Black-box tests for the MoonBit AST port. The interesting bits of
// behavioural parity (mostly inside `music.mbt`) are mirrored from
// legacy source's `test_interval_semitones`.

// ============================================================
// IntervalLit::semitones
// ============================================================

///|
test "M3 = 4 semitones" {
  assert_eq(IntervalLit::new(@lexer.Major, 3).semitones(), 4)
}

///|
test "P5 = 7 semitones" {
  assert_eq(IntervalLit::new(@lexer.Perfect, 5).semitones(), 7)
}

///|
test "m7 = 10 semitones" {
  assert_eq(IntervalLit::new(@lexer.Minor, 7).semitones(), 10)
}

///|
test "A4 = 6 semitones" {
  assert_eq(IntervalLit::new(@lexer.Augmented, 4).semitones(), 6)
}

///|
test "P5+ = 8 semitones (one sharp)" {
  let iv = IntervalLit::new(@lexer.Perfect, 5).with_accidentals([@lexer.Sharp])
  assert_eq(iv.semitones(), 8)
}

///|
test "M3- = 3 semitones (one flat)" {
  let iv = IntervalLit::new(@lexer.Major, 3).with_accidentals([@lexer.Flat])
  assert_eq(iv.semitones(), 3)
}

///|
test "cents == semitones * 100" {
  let iv = IntervalLit::new(@lexer.Major, 3)
  assert_eq(iv.cents(), 400.0)
}

// ============================================================
// AbsolutePitchLit
// ============================================================

///|
test "C4 maps to MIDI 60" {
  assert_eq(AbsolutePitchLit::new('C', 0, 4).to_midi_note(), 60)
}

///|
test "A4 (the pitch, not the interval) maps to MIDI 69" {
  assert_eq(AbsolutePitchLit::new('A', 0, 4).to_midi_note(), 69)
}

///|
test "MIDI clamps below 0 to 0 and above 127 to 127" {
  // Octave -2 with C clamps to 0.
  assert_eq(AbsolutePitchLit::new('C', 0, -2).to_midi_note(), 0)
  // Octave 12 with B clamps to 127.
  assert_eq(AbsolutePitchLit::new('B', 0, 12).to_midi_note(), 127)
}

///|
test "AbsolutePitchLit::from_data lossless round-trips lexer payload" {
  let data = @lexer.AbsolutePitchData::new('F', 1, 5)
  let lit = AbsolutePitchLit::from_data(data)
  assert_eq(lit.note(), 'F')
  assert_eq(lit.accidental(), 1)
  assert_eq(lit.octave(), 5)
}

// ============================================================
// Dynamic::from_str
// ============================================================

///|
test "Dynamic::from_str parses every defined level" {
  assert_true(Dynamic::from_str("ppp") == Some(Pianississimo))
  assert_true(Dynamic::from_str("pp") == Some(Pianissimo))
  assert_true(Dynamic::from_str("p") == Some(Piano))
  assert_true(Dynamic::from_str("mp") == Some(MezzoPiano))
  assert_true(Dynamic::from_str("mf") == Some(MezzoForte))
  assert_true(Dynamic::from_str("f") == Some(Forte))
  assert_true(Dynamic::from_str("ff") == Some(Fortissimo))
  assert_true(Dynamic::from_str("fff") == Some(Fortississimo))
}

///|
test "Dynamic::from_str rejects unknown markings" {
  assert_true(Dynamic::from_str("mff") == None)
  assert_true(Dynamic::from_str("") == None)
}

// ============================================================
// DurationUnit::to_beats
// ============================================================

///|
test "Bars(2) at 4 beats per bar = 8.0 beats" {
  assert_eq(DurationUnit::Bars(2).to_beats(4), 8.0)
}

///|
test "Beats(3) = 3.0 beats regardless of time signature" {
  assert_eq(DurationUnit::Beats(3).to_beats(4), 3.0)
  assert_eq(DurationUnit::Beats(3).to_beats(7), 3.0)
}

// ============================================================
// Pattern::is_irrefutable
// ============================================================

///|
test "wildcard and ident are irrefutable" {
  let span = @core.Span::dummy()
  let id = Ident::new("x")
  assert_true(Pattern::Wildcard.is_irrefutable())
  assert_true(Pattern::Ident(id).is_irrefutable())
  let _ = span
}

///|
test "tuple of irrefutable patterns is irrefutable" {
  let span = @core.Span::dummy()
  let a : @core.Spanned[Pattern] = @core.Spanned::new(Pattern::Wildcard, span)
  let b : @core.Spanned[Pattern] = @core.Spanned::new(
    Pattern::Ident(Ident::new("y")),
    span,
  )
  assert_true(Pattern::Tuple([a, b]).is_irrefutable())
}

///|
test "literal patterns are refutable" {
  assert_true(!Pattern::Literal(LiteralPattern::Integer(42)).is_irrefutable())
}

// ============================================================
// TypeAnnotation::has_type_vars and ::function
// ============================================================

///|
test "Named is monomorphic; Var introduces a type variable" {
  let int_ann : TypeAnnotation = Named(Ident::new("Int"))
  let var_ann : TypeAnnotation = Var(Ident::new("a"))
  assert_false(int_ann.has_type_vars())
  assert_true(var_ann.has_type_vars())
}

///|
test "TypeAnnotation::function curries left-to-right" {
  let int_ann : TypeAnnotation = Named(Ident::new("Int"))
  let str_ann : TypeAnnotation = Named(Ident::new("String"))
  let bool_ann : TypeAnnotation = Named(Ident::new("Bool"))
  // (Int, String) -> Bool  becomes  Int -> (String -> Bool)
  let fn_ty = TypeAnnotation::function([int_ann, str_ann], bool_ann)
  match fn_ty {
    Function(_, rest) =>
      match rest {
        Function(_, _) => ()
        _ => abort("expected nested function type for the second parameter")
      }
    _ => abort("expected outer Function variant")
  }
}

// ============================================================
// Expr::is_simple / is_error
// ============================================================

///|
test "literal and ident expressions are simple" {
  assert_true(Expr::Integer(1L).is_simple())
  assert_true(Expr::Root.is_simple())
  assert_true(Expr::Ident(Ident::new("x")).is_simple())
}

///|
test "binary expressions are not simple" {
  let span = @core.Span::dummy()
  let one : @core.Spanned[Expr] = @core.Spanned::new(Expr::Integer(1L), span)
  let two : @core.Spanned[Expr] = @core.Spanned::new(Expr::Integer(2L), span)
  let bin = Expr::Binary(Binary::new(BinaryOp::Add, one, two))
  assert_false(bin.is_simple())
}

///|
test "Expr::Error is detected" {
  assert_true(Expr::Error.is_error())
  assert_false(Expr::Integer(0L).is_error())
}

// ============================================================
// Sound-design extensions
// ============================================================

///|
test "Pitch::Microtone carries a cents offset" {
  let p : Pitch = Microtone(12.5)
  match p {
    Microtone(c) => assert_eq(c, 12.5)
    _ => abort("expected Microtone variant")
  }
}

///|
test "Pitch::MicrotonalInterval pairs an interval with cents fine-tuning" {
  let iv = IntervalLit::new(@lexer.Major, 3)
  let p : Pitch = MicrotonalInterval(iv, -14.0)
  match p {
    MicrotonalInterval(_, c) => assert_eq(c, -14.0)
    _ => abort("expected MicrotonalInterval variant")
  }
}

///|
test "TuningDef::Equal preserves the step count" {
  let t = TuningDef::new(Ident::new("EDO24"), Equal(24))
  assert_eq(t.name().name(), "EDO24")
  match t.mode() {
    Equal(n) => assert_eq(n, 24)
    _ => abort("expected Equal mode")
  }
}

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
