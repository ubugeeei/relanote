// Round-trip tests: build a fragment of AST by hand, format it, compare
// against the expected canonical source. These cover the constructs
// that ship through `format_item` and `format_expr` today; the parser
// integration tests (parse → format → parse → format) land alongside
// the real parser.

let cfg : FormatConfig = FormatConfig::default()

fn spanned[T](node : T) -> @core.Spanned[T] {
  @core.Spanned::dummy(node)
}

test "default config matches Rust crate" {
  assert_eq(cfg.indent_size(), 4)
  assert_eq(cfg.max_line_width(), 80)
  assert_true(cfg.trailing_commas())
  assert_false(cfg.block_multiline())
}

test "format on an empty program is the empty string" {
  let prog = @ast.Program::empty()
  assert_eq(format(prog, cfg), "")
}

test "scale definition round-trips" {
  let intervals : Array[@core.Spanned[@ast.IntervalLit]] = [
    spanned(@ast.IntervalLit::new(@lexer.Major, 1)),
    spanned(@ast.IntervalLit::new(@lexer.Major, 2)),
    spanned(@ast.IntervalLit::new(@lexer.Major, 3)),
  ]
  let s = @ast.ScaleDef::new(@ast.Ident::new("Major"), None, intervals)
  let item : @ast.Item = @ast.ScaleDef(s)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "scale Major = { M1, M2, M3 }\n")
}

test "chord definition round-trips" {
  let intervals : Array[@core.Spanned[@ast.IntervalLit]] = [
    spanned(@ast.IntervalLit::new(@lexer.Perfect, 1)),
    spanned(@ast.IntervalLit::new(@lexer.Major, 3)),
    spanned(@ast.IntervalLit::new(@lexer.Perfect, 5)),
  ]
  let c = @ast.ChordDef::new(@ast.Ident::new("MajorTriad"), intervals)
  let item : @ast.Item = @ast.ChordDef(c)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "chord MajorTriad = [ P1, M3, P5 ]\n")
}

test "let binding with integer value" {
  let pat : @ast.Pattern = @ast.Ident(@ast.Ident::new("x"))
  let value : @ast.Expr = @ast.Integer(42L)
  let b = @ast.LetBinding::new(spanned(pat), None, spanned(value))
  let item : @ast.Item = @ast.LetBinding(b)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "let x = 42\n")
}

test "set binding" {
  let s = @ast.SetBinding::new(
    @ast.Ident::new("tempo"),
    spanned(@ast.Expr::Integer(120L)),
  )
  let item : @ast.Item = @ast.SetBinding(s)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "set tempo = 120\n")
}

test "interval with accidentals" {
  let iv = @ast.IntervalLit::new(@lexer.Perfect, 5).with_accidentals([
    @lexer.Sharp,
  ])
  let item : @ast.Item = @ast.ExprStmt(spanned(@ast.Interval(iv)))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "P5+\n")
}

test "block with scale-degree slots" {
  let one : @ast.Slot = @ast.Note(
    pitch=spanned(@ast.ScaleIndex(1)),
    articulations=[],
    duration=None,
  )
  let three : @ast.Slot = @ast.Note(
    pitch=spanned(@ast.ScaleIndex(3)),
    articulations=[],
    duration=None,
  )
  let five : @ast.Slot = @ast.Note(
    pitch=spanned(@ast.ScaleIndex(5)),
    articulations=[],
    duration=None,
  )
  let block = @ast.Block::new([spanned(one), spanned(three), spanned(five)])
  let item : @ast.Item = @ast.ExprStmt(spanned(@ast.Block(block)))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "| <1> <3> <5> |\n")
}

test "block with rest and explicit duration on a note" {
  let one : @ast.Slot = @ast.Note(
    pitch=spanned(@ast.ScaleIndex(1)),
    articulations=[],
    duration=Some(2),
  )
  let rest : @ast.Slot = @ast.Rest(duration=None)
  let block = @ast.Block::with_beats(
    [spanned(one), spanned(rest)],
    4.0,
  )
  let item : @ast.Item = @ast.ExprStmt(spanned(@ast.Block(block)))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "| <1>:2 - |:4\n")
}

test "articulations on a note" {
  let pitch_node : @ast.Pitch = @ast.Interval(
    @ast.IntervalLit::new(@lexer.Major, 3),
  )
  let slot : @ast.Slot = @ast.Note(
    pitch=spanned(pitch_node),
    articulations=[@ast.Accent, @ast.Staccato],
    duration=None,
  )
  let block = @ast.Block::new([spanned(slot)])
  let item : @ast.Item = @ast.ExprStmt(spanned(@ast.Block(block)))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "| M3^* |\n")
}

test "pipe expression" {
  let melody : @ast.Expr = @ast.Ident(@ast.Ident::new("melody"))
  let transpose_call : @ast.Expr = @ast.Application(
    @ast.Application::new(
      spanned(@ast.Ident(@ast.Ident::new("transpose"))),
      [spanned(@ast.Interval(@ast.IntervalLit::new(@lexer.Perfect, 5)))],
    ),
  )
  let pipe = @ast.Pipe(
    @ast.Pipe::new(spanned(melody), spanned(transpose_call)),
  )
  let item : @ast.Item = @ast.ExprStmt(spanned(pipe))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "melody |> transpose(P5)\n")
}

test "Microtone pitch carries a cents offset" {
  let pitch_node : @ast.Pitch = @ast.Microtone(12.5)
  let slot : @ast.Slot = @ast.Note(
    pitch=spanned(pitch_node),
    articulations=[],
    duration=None,
  )
  let block = @ast.Block::new([spanned(slot)])
  let item : @ast.Item = @ast.ExprStmt(spanned(@ast.Block(block)))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "| +12.5c |\n")
}

test "Over expression renders as `a over b`" {
  let three : @ast.Expr = @ast.Integer(3L)
  let four : @ast.Expr = @ast.Integer(4L)
  let over = @ast.Over(spanned(three), spanned(four))
  let item : @ast.Item = @ast.ExprStmt(spanned(over))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "3 over 4\n")
}

test "Binary expressions space around the operator" {
  let bin = @ast.Binary(
    @ast.Binary::new(
      @ast.Add,
      spanned(@ast.Interval(@ast.IntervalLit::new(@lexer.Major, 3))),
      spanned(@ast.Interval(@ast.IntervalLit::new(@lexer.Minor, 3))),
    ),
  )
  let item : @ast.Item = @ast.ExprStmt(spanned(bin))
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "M3 + m3\n")
}

test "Multi-item program separates with a blank line" {
  let scale_def : @ast.Item = @ast.ScaleDef(
    @ast.ScaleDef::new(
      @ast.Ident::new("Major"),
      None,
      [spanned(@ast.IntervalLit::new(@lexer.Major, 3))],
    ),
  )
  let melody : @ast.Expr = @ast.Ident(@ast.Ident::new("melody"))
  let melody_stmt : @ast.Item = @ast.ExprStmt(spanned(melody))
  let prog = @ast.Program::new([spanned(scale_def), spanned(melody_stmt)])
  assert_eq(format(prog, cfg), "scale Major = { M3 }\n\nmelody\n")
}

test "import single name" {
  let decl = @ast.ImportDecl::new([@ast.Named(@ast.Ident::new("foo"))], "bar")
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import foo from \"bar\"\n")
}

test "import single aliased name" {
  let decl = @ast.ImportDecl::new(
    [
      @ast.Aliased(name=@ast.Ident::new("foo"), as_name=@ast.Ident::new("f")),
    ],
    "bar",
  )
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import foo as f from \"bar\"\n")
}

test "import group renders with braces" {
  let decl = @ast.ImportDecl::new(
    [
      @ast.Named(@ast.Ident::new("a")),
      @ast.Aliased(name=@ast.Ident::new("b"), as_name=@ast.Ident::new("bb")),
    ],
    "x",
  )
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import { a, b as bb } from \"x\"\n")
}

test "import wildcard" {
  let decl = @ast.ImportDecl::new([@ast.All], "m")
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import * from \"m\"\n")
}

test "import wildcard with alias" {
  let decl = @ast.ImportDecl::new(
    [@ast.AllAliased(@ast.Ident::new("M"))],
    "m",
  )
  let item : @ast.Item = @ast.Import(decl)
  let prog = @ast.Program::new([spanned(item)])
  assert_eq(format(prog, cfg), "import * as M from \"m\"\n")
}
