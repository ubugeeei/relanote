///|
test "block concat parses as a binary expression" {
  let (program, diags) = parse("| <1> | ++ | <5> |")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    @ast.ExprStmt(expr) =>
      match expr.node() {
        @ast.Binary(binary) => assert_true(binary.op() == @ast.Concat)
        _ => abort("expected Binary concat")
      }
    _ => abort("expected expression statement")
  }
}

///|
test "chord slots parse inside blocks" {
  let (program, diags) = parse("| [R, M3, P5]^:2 |")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    @ast.ExprStmt(expr) =>
      match expr.node() {
        @ast.Block(block) =>
          match block.slots()[0].node() {
            @ast.Chord(pitches~, articulations~, duration~) => {
              assert_eq(pitches.length(), 3)
              assert_eq(articulations.length(), 1)
              assert_true(duration == Some(2))
            }
            _ => abort("expected chord slot")
          }
        _ => abort("expected block")
      }
    _ => abort("expected expression statement")
  }
}

///|
test "tuplet slots parse inside blocks" {
  let (program, diags) = parse("| { <1> <2> <3> }:2 |")
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    @ast.ExprStmt(expr) =>
      match expr.node() {
        @ast.Block(block) =>
          match block.slots()[0].node() {
            @ast.Tuplet(tuplet) => {
              assert_eq(tuplet.contents().length(), 3)
              match tuplet.target_beats().node() {
                @ast.Integer(2L) => ()
                _ => abort("expected integer target beats")
              }
            }
            _ => abort("expected tuplet slot")
          }
        _ => abort("expected block")
      }
    _ => abort("expected expression statement")
  }
}
