// Smoke tests. The Rust crate is still a placeholder so behavioural
// parity here is "can we construct the data types and call
// `lower_program` without crashing".

test "TypedProgram::empty has zero items" {
  let p = TypedProgram::empty()
  assert_eq(p.items().length(), 0)
}

test "TypedExpr::new keeps its kind and type" {
  let e = TypedExpr::new(Placeholder, @types.Unit)
  match e.kind() {
    Placeholder => ()
  }
  match e.ty() {
    @types.Unit => ()
    _ => abort("expected Unit type")
  }
}

test "lower_program returns an empty TypedProgram" {
  let prog = @ast.Program::empty()
  let lowered = lower_program(prog)
  assert_eq(lowered.items().length(), 0)
}
