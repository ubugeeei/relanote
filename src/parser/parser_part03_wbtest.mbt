///|
test "if expression parses with then and else" {
  let (program, diags) = parse("let r = if cond then 1 else 2")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        If(if_expr) =>
          match if_expr.else_branch() {
            Some(_) => ()
            None => abort("expected an else branch")
          }
        _ => abort("expected If")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "if expression without else is allowed" {
  let (program, diags) = parse("let r = if cond then 1")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        If(if_expr) =>
          match if_expr.else_branch() {
            None => ()
            Some(_) => abort("expected no else branch")
          }
        _ => abort("expected If")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "if missing `then` raises a diagnostic" {
  let (_, diags) = parse("let r = if cond 1")
  assert_true(diags.has_errors())
}

///|
test "let-in expression parses to a Let expr" {
  let (program, diags) = parse("let r = let x = 1 in x")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Let(let_expr) =>
          match let_expr.body().node() {
            Ident(id) => assert_eq(id.name(), "x")
            _ => abort("expected ident body")
          }
        _ => abort("expected Let")
      }
    _ => abort("expected outer LetBinding")
  }
}

///|
test "let-in missing `in` raises a diagnostic" {
  let (_, diags) = parse("let r = let x = 1 x")
  assert_true(diags.has_errors())
}

///|
test "match expression with two arms parses correctly" {
  let (program, diags) = parse("let r = match x { 1 -> a, 2 -> b }")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Match(m) => assert_eq(m.arms().length(), 2)
        _ => abort("expected Match")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "match arm with guard parses with guard_expr" {
  let (program, diags) = parse("let r = match x { y if y -> a }")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Match(m) => {
          assert_eq(m.arms().length(), 1)
          match m.arms()[0].guard_expr() {
            Some(_) => ()
            None => abort("expected guard expression")
          }
        }
        _ => abort("expected Match")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "match missing `->` raises a diagnostic" {
  let (_, diags) = parse("let r = match x { 1 a }")
  assert_true(diags.has_errors())
}

///|
test "array literal parses to Array" {
  let (program, diags) = parse("let r = [1, 2, 3]")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Array(elems) => assert_eq(elems.length(), 3)
        _ => abort("expected Array")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "empty array literal parses to Array of 0 elements" {
  let (program, diags) = parse("let r = []")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Array(elems) => assert_eq(elems.length(), 0)
        _ => abort("expected Array")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "tuple with two elements parses to Tuple" {
  let (program, diags) = parse("let r = (1, 2)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Tuple(elems) => assert_eq(elems.length(), 2)
        _ => abort("expected Tuple")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "parenthesised single expression stays Paren, not Tuple" {
  let (program, diags) = parse("let r = (1)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Paren(_) => ()
        _ => abort("expected Paren")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "field access x.y parses to Field" {
  let (program, diags) = parse("let r = x.y")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Field(f) => assert_eq(f.field().name(), "y")
        _ => abort("expected Field")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "chained field access x.y.z parses left-associatively" {
  let (program, diags) = parse("let r = x.y.z")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Field(outer) => {
          assert_eq(outer.field().name(), "z")
          match outer.base().node() {
            Field(inner) => assert_eq(inner.field().name(), "y")
            _ => abort("inner should also be a Field")
          }
        }
        _ => abort("expected outer Field")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "indexing arr[0] parses to Index" {
  let (program, diags) = parse("let r = arr[0]")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Index(idx) =>
          match idx.index().node() {
            Integer(0L) => ()
            _ => abort("expected Integer(0) index")
          }
        _ => abort("expected Index")
      }
    _ => abort("expected LetBinding")
  }
}
