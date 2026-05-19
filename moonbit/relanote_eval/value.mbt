///|
/// Runtime value produced by the evaluator. The Rust crate carries many
/// specialised variants (closures, blocks, parts, sections, synth /
/// envelope state, …); the MoonBit port grows these incrementally as
/// each phase of the evaluator lands.
///
/// Tracked in #8.
pub(all) enum Value {
  UnitV
  BoolV(Bool)
  IntV(Int64)
  FloatV(Double)
  StringV(String)
  /// Scale definition value — keeps the AST around verbatim so later
  /// phases (block resolution, MIDI rendering) can look up the
  /// intervals.
  ScaleV(@ast.ScaleDef)
  /// Chord definition value — same shape as `ScaleV`.
  ChordV(@ast.ChordDef)
  /// Synth definition value.
  SynthV(@ast.SynthDef)
  /// User-defined function — kept as the AST + a captured environment.
  /// Sub-PRs in #56 will replace this with a real closure record.
  ClosureV(@ast.FunctionDef, Env)
  /// Placeholder retained for round-tripping through call sites that
  /// don't care about the variant yet; new code should produce a more
  /// specific variant instead of returning this.
  Placeholder
}
