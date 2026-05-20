// Black-box tests for the MoonBit lexer port. These mirror the assertions
// in the tokenizer and token definitions so any behavioural
// drift between the two implementations should fail one of these tests.

///|
fn lex(input : String) -> Array[TokenKind] {
  let source = @core.Source::from_string("test", input)
  let tokens = Lexer::new(source).tokenize()
  let kinds : Array[TokenKind] = []
  for t in tokens {
    kinds.push(t.kind())
  }
  kinds
}

// ============================================================
// Augmented interval vs absolute pitch disambiguation
// ============================================================

///|
test "A4 is Augmented 4th, not an absolute pitch" {
  let toks = lex("A4")
  assert_true(toks[0] == Interval(IntervalData::new(Augmented, 4, [])))
}

///|
test "A5 is Augmented 5th" {
  let toks = lex("A5")
  assert_true(toks[0] == Interval(IntervalData::new(Augmented, 5, [])))
}

///|
test "A#4 is the absolute pitch A sharp octave 4" {
  let toks = lex("A#4")
  assert_true(toks[0] == AbsolutePitch(AbsolutePitchData::new('A', 1, 4)))
}

///|
test "Ab4 is the absolute pitch A flat octave 4" {
  let toks = lex("Ab4")
  assert_true(toks[0] == AbsolutePitch(AbsolutePitchData::new('A', -1, 4)))
}

///|
test "C4 is the absolute pitch C octave 4" {
  let toks = lex("C4")
  assert_true(toks[0] == AbsolutePitch(AbsolutePitchData::new('C', 0, 4)))
}

// ============================================================
// Interval payload parsing
// ============================================================

///|
test "interval M3 has Major quality, degree 3" {
  let toks = lex("M3")
  assert_true(toks[0] == Interval(IntervalData::new(Major, 3, [])))
}

///|
test "interval P5+ has one Sharp accidental" {
  let toks = lex("P5+")
  assert_true(toks[0] == Interval(IntervalData::new(Perfect, 5, [Sharp])))
}

///|
test "interval m7- has one Flat accidental" {
  let toks = lex("m7-")
  assert_true(toks[0] == Interval(IntervalData::new(Minor, 7, [Flat])))
}

///|
test "interval A4++ has two Sharp accidentals" {
  let toks = lex("A4++")
  assert_true(
    toks[0] == Interval(IntervalData::new(Augmented, 4, [Sharp, Sharp])),
  )
}

// ============================================================
// Basic token stream tests
// ============================================================

///|
test "let binding lexes to Let Ident Equals Interval" {
  let toks = lex("let x = M3")
  assert_true(toks[0] == Let)
  assert_true(toks[1] == Ident("x"))
  assert_true(toks[2] == Equals)
  match toks[3] {
    Interval(_) => ()
    _ => abort("expected Interval token")
  }
}

///|
test "pipe block lexes correctly" {
  let toks = lex("| R M3 P5 |")
  assert_true(toks[0] == Pipe)
  assert_true(toks[1] == Root)
  match toks[2] {
    Interval(_) => ()
    _ => abort("expected Interval token at index 2")
  }
  match toks[3] {
    Interval(_) => ()
    _ => abort("expected Interval token at index 3")
  }
  assert_true(toks[4] == Pipe)
}

///|
test "lambda + arrow + pipe operator" {
  let toks = lex("\\x -> x |> reverse")
  assert_true(toks[0] == Lambda)
  assert_true(toks[1] == Ident("x"))
  assert_true(toks[2] == Arrow)
  assert_true(toks[3] == Ident("x"))
  assert_true(toks[4] == PipeOp)
  assert_true(toks[5] == Ident("reverse"))
}

///|
test "dynamics are plain identifiers" {
  let toks = lex("pp mf ff")
  assert_true(toks[0] == Ident("pp"))
  assert_true(toks[1] == Ident("mf"))
  assert_true(toks[2] == Ident("ff"))
}

///|
test "string literals" {
  let toks = lex("\"Piano\" \"Hello World\"")
  assert_true(toks[0] == StringLit("Piano"))
  assert_true(toks[1] == StringLit("Hello World"))
}

///|
test "line comment is preserved including the leading semicolon" {
  let toks = lex("let x = 1 ; this is a comment\nlet y = 2")
  assert_true(toks[0] == Let)
  assert_true(toks[1] == Ident("x"))
  assert_true(toks[2] == Equals)
  assert_true(toks[3] == Integer(1))
  assert_true(toks[4] == LineComment("; this is a comment"))
  assert_true(toks[5] == Newline)
  assert_true(toks[6] == Let)
}

// ============================================================
// Misc keyword / operator coverage
// ============================================================

///|
test "scale definition opening tokens" {
  let toks = lex("scale Major = { R, M2, M3, P4, P5, M6, M7 }")
  assert_true(toks[0] == Scale)
  assert_true(toks[1] == Ident("Major"))
  assert_true(toks[2] == Equals)
  assert_true(toks[3] == LBrace)
  assert_true(toks[4] == Root)
}

///|
test "articulation markers attach to notes" {
  let toks = lex("| R* M3^ P5~ |")
  assert_true(toks[0] == Pipe)
  assert_true(toks[1] == Root)
  assert_true(toks[2] == Staccato)
  match toks[3] {
    Interval(_) => ()
    _ => abort("expected Interval at index 3")
  }
  assert_true(toks[4] == Accent)
}

///|
test "function application with pipe operator" {
  let toks = lex("melody_motif |> repeat(2)")
  assert_true(toks[0] == Ident("melody_motif"))
  assert_true(toks[1] == PipeOp)
  assert_true(toks[2] == Ident("repeat"))
  assert_true(toks[3] == LParen)
  assert_true(toks[4] == Integer(2))
  assert_true(toks[5] == RParen)
}

///|
test "set / Key keywords" {
  let toks = lex("set Key = C4")
  assert_true(toks[0] == Set)
  assert_true(toks[1] == Key)
  assert_true(toks[2] == Equals)
}

///|
test "set tempo treats tempo as identifier" {
  let toks = lex("set tempo = 120")
  assert_true(toks[0] == Set)
  assert_true(toks[1] == Ident("tempo"))
}

///|
test "concat operator ++" {
  let toks = lex("a ++ b")
  assert_true(toks[0] == Ident("a"))
  assert_true(toks[1] == PlusPlus)
  assert_true(toks[2] == Ident("b"))
}

///|
test "arithmetic operators" {
  let toks = lex("* / %")
  assert_true(toks[0] == Star)
  assert_true(toks[1] == Slash)
  assert_true(toks[2] == Percent)
}

///|
test "comparison operators" {
  let toks = lex("a == b != c <= d >= e < f > g")
  assert_true(toks[1] == EqEq)
  assert_true(toks[3] == NotEq)
  assert_true(toks[5] == LtEq)
  assert_true(toks[7] == GtEq)
  assert_true(toks[9] == LAngle)
  assert_true(toks[11] == RAngle)
}

///|
test "logical operators" {
  let toks = lex("!a && b || c")
  assert_true(toks[0] == Bang)
  assert_true(toks[2] == AndAnd)
  assert_true(toks[4] == OrOr)
}

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
