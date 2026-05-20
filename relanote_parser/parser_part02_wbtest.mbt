///|
test "missing `=` after let raises a diagnostic" {
  let (_, diags) = parse("let x 42")
  assert_true(diags.has_errors())
}

///|
test "multiple items separated by newlines" {
  let src = "set tempo = 120\nscale Major = { R, M2, M3 }\nlet x = 1"
  let (prog, diags) = parse(src)
  assert_false(diags.has_errors())
  assert_eq(prog.items().length(), 3)
}

///|
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

///|
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

///|
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

///|
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

///|
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

///|
test "missing from after import raises a diagnostic" {
  let (_, diags) = parse("import foo \"bar\"")
  assert_true(diags.has_errors())
}

///|
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

///|
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

///|
test "lambda without an arrow surfaces a diagnostic" {
  let (_, diags) = parse("let bad = \\x x")
  assert_true(diags.has_errors())
}

///|
test "function call f(x) parses to Application" {
  let (program, diags) = parse("let r = f(x)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Application(app) => {
          match app.func().node() {
            Ident(id) => assert_eq(id.name(), "f")
            _ => abort("expected callee to be f")
          }
          assert_eq(app.args().length(), 1)
        }
        _ => abort("expected Application")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "function call with multiple args parses correctly" {
  let (program, diags) = parse("let r = f(1, 2, 3)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Application(app) => assert_eq(app.args().length(), 3)
        _ => abort("expected Application")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "function call with no args parses to Application of 0 args" {
  let (program, diags) = parse("let r = f()")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Application(app) => assert_eq(app.args().length(), 0)
        _ => abort("expected Application")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "chained calls f(x)(y) parse left-associatively" {
  let (program, diags) = parse("let r = f(x)(y)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Application(outer) =>
          match outer.func().node() {
            Application(inner) => {
              assert_eq(inner.args().length(), 1)
              assert_eq(outer.args().length(), 1)
            }
            _ => abort("outer callee should itself be an Application")
          }
        _ => abort("expected outer Application")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "pipe operates on a call result" {
  let (program, diags) = parse("let r = x |> f(2)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Pipe(pipe) =>
          match pipe.right().node() {
            Application(_) => ()
            _ => abort("pipe's RHS should be the Application f(2)")
          }
        _ => abort("expected Pipe")
      }
    _ => abort("expected LetBinding")
  }
}
