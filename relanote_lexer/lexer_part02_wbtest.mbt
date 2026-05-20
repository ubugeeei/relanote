///|
test "star keeps staccato suffix behaviour" {
  let toks = lex("| R* <3>* |")
  assert_true(toks[0] == Pipe)
  assert_true(toks[2] == Staccato)
  assert_true(toks[6] == Staccato)
}

///|
test "angle brackets around scale degree" {
  let toks = lex("| <1> <3> <5> |")
  assert_true(toks[0] == Pipe)
  assert_true(toks[1] == LAngle)
  assert_true(toks[2] == Integer(1))
  assert_true(toks[3] == RAngle)
}

///|
test "rest dash inside a pipe block" {
  let toks = lex("| R - M3 |")
  assert_true(toks[0] == Pipe)
  assert_true(toks[1] == Root)
  assert_true(toks[2] == Minus)
}

///|
test "duration via colon" {
  let toks = lex("| R:2 M3:4 |")
  assert_true(toks[0] == Pipe)
  assert_true(toks[1] == Root)
  assert_true(toks[2] == Colon)
  assert_true(toks[3] == Integer(2))
}

///|
test "control flow keywords" {
  let toks = lex("if true then a else b")
  assert_true(toks[0] == If)
  assert_true(toks[1] == True)
  assert_true(toks[2] == Then)
  assert_true(toks[4] == Else)
}

///|
test "match expression header" {
  let toks = lex("match x with | a -> b")
  assert_true(toks[0] == Match)
  assert_true(toks[2] == With)
  assert_true(toks[3] == Pipe)
  assert_true(toks[5] == Arrow)
}

///|
test "integer literals" {
  let toks = lex("0 42 123")
  assert_true(toks[0] == Integer(0))
  assert_true(toks[1] == Integer(42))
  assert_true(toks[2] == Integer(123))
}

///|
test "float literals" {
  let toks = lex("0.0 3.14 0.5")
  assert_true(toks[0] == Float(0.0))
  assert_true(toks[1] == Float(3.14))
  assert_true(toks[2] == Float(0.5))
}

///|
test "bracket family" {
  let toks = lex("( ) [ ] { }")
  assert_true(toks[0] == LParen)
  assert_true(toks[1] == RParen)
  assert_true(toks[2] == LBracket)
  assert_true(toks[3] == RBracket)
  assert_true(toks[4] == LBrace)
  assert_true(toks[5] == RBrace)
}

///|
test "newlines are preserved between tokens" {
  let toks = lex("let x = 42\nx")
  assert_true(toks[0] == Let)
  assert_true(toks[1] == Ident("x"))
  assert_true(toks[2] == Equals)
  assert_true(toks[3] == Integer(42))
  assert_true(toks[4] == Newline)
  assert_true(toks[5] == Ident("x"))
}

///|
test "consecutive newlines are kept as separate tokens" {
  let toks = lex("a\n\nb")
  assert_true(toks[0] == Ident("a"))
  assert_true(toks[1] == Newline)
  assert_true(toks[2] == Newline)
  assert_true(toks[3] == Ident("b"))
}

///|
test "let ... in" {
  let toks = lex("let x = 42 in x")
  assert_true(toks[0] == Let)
  assert_true(toks[1] == Ident("x"))
  assert_true(toks[2] == Equals)
  assert_true(toks[3] == Integer(42))
  assert_true(toks[4] == In)
  assert_true(toks[5] == Ident("x"))
  assert_true(toks[6] == Eof)
}

///|
test "logical keywords lex as identifiers" {
  let toks = lex("a and b or not c")
  assert_true(toks[0] == Ident("a"))
  assert_true(toks[1] == Ident("and"))
  assert_true(toks[2] == Ident("b"))
  assert_true(toks[3] == Ident("or"))
  assert_true(toks[4] == Ident("not"))
  assert_true(toks[5] == Ident("c"))
}

///|
test "absolute pitches around the staff" {
  let toks = lex("C4 D4 Bb3 F#5")
  match toks[0] {
    AbsolutePitch(_) => ()
    _ => abort("expected AbsolutePitch at index 0")
  }
  match toks[1] {
    AbsolutePitch(_) => ()
    _ => abort("expected AbsolutePitch at index 1")
  }
  match toks[2] {
    AbsolutePitch(_) => ()
    _ => abort("expected AbsolutePitch at index 2")
  }
  match toks[3] {
    AbsolutePitch(_) => ()
    _ => abort("expected AbsolutePitch at index 3")
  }
}

///|
test "interval list with modifiers" {
  let toks = lex("P5+ M3- P8++")
  match toks[0] {
    Interval(_) => ()
    _ => abort("expected Interval at index 0")
  }
  match toks[1] {
    Interval(_) => ()
    _ => abort("expected Interval at index 1")
  }
  match toks[2] {
    Interval(_) => ()
    _ => abort("expected Interval at index 2")
  }
}

///|
test "section header" {
  let toks = lex("section \"Intro\" { layer [ ] }")
  assert_true(toks[0] == Section)
  assert_true(toks[1] == StringLit("Intro"))
  assert_true(toks[2] == LBrace)
  assert_true(toks[3] == Layer)
}

///|
test "with keyword after a Capitalised identifier" {
  let toks = lex("Major with { P4+ }")
  assert_true(toks[0] == Ident("Major"))
  assert_true(toks[1] == With)
  assert_true(toks[2] == LBrace)
}

///|
test "env(pp, mf, 4bars)" {
  let toks = lex("env(pp, mf, 4bars)")
  assert_true(toks[0] == Env)
  assert_true(toks[1] == LParen)
  assert_true(toks[2] == Ident("pp"))
}

// ============================================================
// MIDI conversion sanity check
// ============================================================

///|
test "C4 maps to MIDI note 60" {
  let p = AbsolutePitchData::new('C', 0, 4)
  assert_eq(p.to_midi_note(), 60)
}

///|
test "A4 absolute pitch maps to MIDI note 69" {
  let p = AbsolutePitchData::new('A', 0, 4)
  assert_eq(p.to_midi_note(), 69)
}

// ============================================================
// Source / Span smoke tests
// ============================================================

///|
test "Source::location maps offsets to 1-based line and column" {
  let s = @core.Source::from_string("test", "hello\nworld\n")
  assert_true(s.location(0) == @core.Location::new(1, 1))
  assert_true(s.location(5) == @core.Location::new(1, 6))
  assert_true(s.location(6) == @core.Location::new(2, 1))
  assert_true(s.location(11) == @core.Location::new(2, 6))
}

///|
test "Source::line returns each line trimmed of its newline" {
  let s = @core.Source::from_string("test", "hello\nworld\nfoo")
  assert_true(s.line(1) == Some("hello"))
  assert_true(s.line(2) == Some("world"))
  assert_true(s.line(3) == Some("foo"))
  assert_true(s.line(4) == None)
  assert_true(s.line(0) == None)
}

///|
test "Span merge combines two ranges" {
  let a = @core.Span::new(@core.SourceId::dummy(), 5, 10)
  let b = @core.Span::new(@core.SourceId::dummy(), 8, 15)
  let m = a.merge(b)
  assert_eq(m.start(), 5)
  assert_eq(m.end(), 15)
}
