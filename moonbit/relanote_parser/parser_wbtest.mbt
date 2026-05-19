// Smoke tests for the hand-rolled parser. Covers the foundational
// subset implemented in `parser.mbt`. The richer grammar (binary
// arithmetic, comparison, lambdas, match, sound-design declarations,
// etc.) is tracked in #4 and lands alongside the evaluator port.

test "empty source produces an empty program with no diagnostics" {
  let (prog, diags) = parse("")
  assert_eq(prog.items().length(), 0)
  assert_false(diags.has_errors())
}

test "literal integer expression at the top level" {
  let (prog, diags) = parse("42")
  assert_false(diags.has_errors())
  assert_eq(prog.items().length(), 1)
  match prog.items()[0].node() {
    @ast.ExprStmt(e) =>
      match e.node() {
        @ast.Integer(n) => assert_eq(n, 42L)
        _ => abort("expected Integer expression")
      }
    _ => abort("expected ExprStmt item")
  }
}

test "let binding with an integer right-hand side" {
  let (prog, diags) = parse("let answer = 42")
  assert_false(diags.has_errors())
  assert_eq(prog.items().length(), 1)
  match prog.items()[0].node() {
    @ast.LetBinding(b) => {
      match b.pattern().node() {
        @ast.Ident(id) => assert_eq(id.name(), "answer")
        _ => abort("expected Ident pattern")
      }
      match b.value().node() {
        @ast.Integer(n) => assert_eq(n, 42L)
        _ => abort("expected Integer value")
      }
    }
    _ => abort("expected LetBinding")
  }
}

test "set binding for tempo" {
  let (prog, _) = parse("set tempo = 120")
  assert_eq(prog.items().length(), 1)
  match prog.items()[0].node() {
    @ast.SetBinding(s) => {
      assert_eq(s.name().name(), "tempo")
      match s.value().node() {
        @ast.Integer(n) => assert_eq(n, 120L)
        _ => abort("expected Integer")
      }
    }
    _ => abort("expected SetBinding")
  }
}

test "scale declaration" {
  let (prog, diags) = parse("scale Major = { R, M2, M3 }")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.ScaleDef(s) => {
      assert_eq(s.name().name(), "Major")
      assert_eq(s.intervals().length(), 3)
    }
    _ => abort("expected ScaleDef")
  }
}

test "chord declaration" {
  let (prog, diags) = parse("chord MajorTriad = [ R, M3, P5 ]")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.ChordDef(c) => {
      assert_eq(c.name().name(), "MajorTriad")
      assert_eq(c.intervals().length(), 3)
    }
    _ => abort("expected ChordDef")
  }
}

test "block of scale-degree slots" {
  let (prog, diags) = parse("| <1> <3> <5> |")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.ExprStmt(e) =>
      match e.node() {
        @ast.Block(b) => assert_eq(b.slots().length(), 3)
        _ => abort("expected Block")
      }
    _ => abort("expected ExprStmt")
  }
}

test "block with explicit `:n` beats" {
  let (prog, _) = parse("| <1> <3> |:4")
  match prog.items()[0].node() {
    @ast.ExprStmt(e) =>
      match e.node() {
        @ast.Block(b) =>
          match b.beats() {
            Some(n) => assert_eq(n, 4.0)
            None => abort("expected explicit beats")
          }
        _ => abort("expected Block")
      }
    _ => abort("expected ExprStmt")
  }
}

test "block with a rest" {
  let (prog, _) = parse("| <1> - <3> |")
  match prog.items()[0].node() {
    @ast.ExprStmt(e) =>
      match e.node() {
        @ast.Block(b) => {
          assert_eq(b.slots().length(), 3)
          match b.slots()[1].node() {
            @ast.Rest(_) => ()
            _ => abort("middle slot should be a rest")
          }
        }
        _ => abort("expected Block")
      }
    _ => abort("expected ExprStmt")
  }
}

test "pipe expression" {
  let (prog, diags) = parse("melody |> transpose")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.ExprStmt(e) =>
      match e.node() {
        @ast.Pipe(_) => ()
        _ => abort("expected Pipe")
      }
    _ => abort("expected ExprStmt")
  }
}

test "missing `=` after let raises a diagnostic" {
  let (_, diags) = parse("let x 42")
  assert_true(diags.has_errors())
}

test "multiple items separated by newlines" {
  let src = "set tempo = 120\nscale Major = { R, M2, M3 }\nlet x = 1"
  let (prog, diags) = parse(src)
  assert_false(diags.has_errors())
  assert_eq(prog.items().length(), 3)
}

test "import single name from module" {
  let (prog, diags) = parse("import foo from \"bar\"")
  assert_false(diags.has_errors())
  assert_eq(prog.items().length(), 1)
  match prog.items()[0].node() {
    @ast.Import(decl) => {
      assert_eq(decl.from(), "bar")
      assert_eq(decl.items().length(), 1)
      match decl.items()[0] {
        @ast.Named(id) => assert_eq(id.name(), "foo")
        _ => abort("expected Named import item")
      }
    }
    _ => abort("expected Import")
  }
}

test "import aliased name from module" {
  let (prog, diags) = parse("import foo as f from \"bar\"")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.Import(decl) => {
      assert_eq(decl.from(), "bar")
      match decl.items()[0] {
        @ast.Aliased(name~, as_name~) => {
          assert_eq(name.name(), "foo")
          assert_eq(as_name.name(), "f")
        }
        _ => abort("expected Aliased import item")
      }
    }
    _ => abort("expected Import")
  }
}

test "import group from module" {
  let (prog, diags) = parse("import { a, b as bb } from \"x\"")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.Import(decl) => {
      assert_eq(decl.from(), "x")
      assert_eq(decl.items().length(), 2)
      match decl.items()[0] {
        @ast.Named(id) => assert_eq(id.name(), "a")
        _ => abort("expected Named for first item")
      }
      match decl.items()[1] {
        @ast.Aliased(name~, as_name~) => {
          assert_eq(name.name(), "b")
          assert_eq(as_name.name(), "bb")
        }
        _ => abort("expected Aliased for second item")
      }
    }
    _ => abort("expected Import")
  }
}

test "import wildcard from module" {
  let (prog, diags) = parse("import * from \"m\"")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.Import(decl) => {
      assert_eq(decl.from(), "m")
      match decl.items()[0] {
        @ast.All => ()
        _ => abort("expected All import item")
      }
    }
    _ => abort("expected Import")
  }
}

test "import wildcard with alias" {
  let (prog, diags) = parse("import * as M from \"m\"")
  assert_false(diags.has_errors())
  match prog.items()[0].node() {
    @ast.Import(decl) =>
      match decl.items()[0] {
        @ast.AllAliased(id) => assert_eq(id.name(), "M")
        _ => abort("expected AllAliased import item")
      }
    _ => abort("expected Import")
  }
}

test "missing from after import raises a diagnostic" {
  let (_, diags) = parse("import foo \"bar\"")
  assert_true(diags.has_errors())
}

test "lambda with one parameter parses to Lambda expr" {
  let (program, diags) = parse("let id = \\x -> x")
  assert_false(diags.has_errors())
  let items = program.items()
  assert_eq(items.length(), 1)
  match items[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Lambda(lambda) => {
          assert_eq(lambda.params().length(), 1)
          match lambda.body().node() {
            Ident(id) => assert_eq(id.name(), "x")
            _ => abort("expected lambda body to be an identifier")
          }
        }
        _ => abort("expected let value to be a Lambda")
      }
    _ => abort("expected the only item to be a LetBinding")
  }
}

test "lambda with two parameters parses to Lambda expr with 2 params" {
  let (program, diags) = parse("let k = \\x y -> x")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Lambda(lambda) => assert_eq(lambda.params().length(), 2)
        _ => abort("expected Lambda value")
      }
    _ => abort("expected LetBinding")
  }
}

test "lambda without an arrow surfaces a diagnostic" {
  let (_, diags) = parse("let bad = \\x x")
  assert_true(diags.has_errors())
}
