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
  /// Interval value, stored as a signed semitone offset from the root.
  /// Mirrors the Rust crate's `IntervalValue` flattening.
  IntervalV(Int)
  /// Absolute pitch literal as a MIDI note number (0..127, middle C =
  /// 60). The AST carries letter / accidental / octave; the evaluator
  /// reduces to MIDI eagerly.
  AbsolutePitchV(Int)
  /// Root pitch — `<R>`. Semantically equivalent to `IntervalV(0)` but
  /// kept distinct so later phases can distinguish a written root from
  /// an explicit P1.
  RootV
  /// Block of slots. The AST is carried verbatim because resolution
  /// against the current scale / chord / tuplet context happens at
  /// render time.
  BlockV(@ast.Block)
  /// Tuplet of slots — like `BlockV` but with an explicit target-beat
  /// expression that has already been evaluated to a number.
  TupletV(@ast.Tuplet)
  /// Placeholder retained for round-tripping through call sites that
  /// don't care about the variant yet; new code should produce a more
  /// specific variant instead of returning this.
  Placeholder
}
