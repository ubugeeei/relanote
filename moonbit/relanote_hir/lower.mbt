///|
/// Lower an AST `Program` to HIR. The Rust crate's `lower_program` is
/// itself a placeholder returning an empty `TypedProgram`; this port keeps
/// the same signature so downstream consumers can be wired up before the
/// real lowering arrives.
pub fn lower_program(program : @ast.Program) -> TypedProgram {
  let _ = program
  TypedProgram::empty()
}
