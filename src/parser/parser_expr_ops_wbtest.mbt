///|
test "arithmetic operators parse with precedence" {
  let (program, diags) = parse("let r = 1 + 2 * 3")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Binary(outer) => {
          assert_true(outer.op() == Add)
          match outer.right().node() {
            Binary(inner) => assert_true(inner.op() == Mul)
            _ => abort("expected multiplication on the right")
          }
        }
        _ => abort("expected Binary")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "unary minus parses inside call arguments" {
  let (program, diags) = parse("let r = octave(-1)")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Application(app) =>
          match app.args()[0].node() {
            Unary(u) => assert_true(u.op() == Neg)
            _ => abort("expected Unary")
          }
        _ => abort("expected Application")
      }
    _ => abort("expected LetBinding")
  }
}

///|
test "space application parses pipe helper arguments" {
  let (program, diags) = parse("let r = Saw |> mix 0.3 |> octave 1")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    LetBinding(b) =>
      match b.value().node() {
        Pipe(_) => ()
        _ => abort("expected Pipe")
      }
    _ => abort("expected LetBinding")
  }
}
