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
