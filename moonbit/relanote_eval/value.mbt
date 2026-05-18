///|
/// Runtime value produced by the evaluator. The Rust crate carries many
/// specialised variants (closures, blocks, parts, sections, synth /
/// envelope state, …); this skeleton keeps the public surface stable
/// with a `Placeholder` variant so call sites can be wired up before the
/// full value ADT is ported.
///
/// Tracked in #8.
pub(all) enum Value {
  UnitV
  BoolV(Bool)
  IntV(Int64)
  FloatV(Double)
  StringV(String)
  Placeholder
} derive(Eq)
