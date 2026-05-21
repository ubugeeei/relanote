///|
fn builtin_repeat(
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != 2 {
    return Err(WrongArity(expected=2, got=args.length(), span~))
  }
  // Support both argument orders: (Int, Block) and (Block, Int) so
  // pipe and direct application both feel natural.
  let (n, block) = match (args[0], args[1]) {
    (IntV(n), BlockV(b)) => (n.to_int(), b)
    (BlockV(b), IntV(n)) => (n.to_int(), b)
    _ => return Err(TypeError(expected="Int and Block", found="other", span~))
  }
  let new_slots : Array[@core.Spanned[@ast.Slot]] = []
  let mut k = 0
  while k < n {
    for slot in block.slots() {
      new_slots.push(slot)
    }
    k += 1
  }
  let new_block = match block.beats() {
    Some(b) => @ast.Block::with_beats(new_slots, b * n.to_double())
    None => @ast.Block::with_beats(new_slots, n.to_double())
  }
  Ok(BlockV(new_block))
}

///|
/// Bind `args` against `params` inside a fresh child of `captured`,
/// then evaluate `body`. Currently supports plain identifier
/// parameters — destructuring patterns land alongside the inference
/// walker's full pattern story.
fn Evaluator::run_function(
  self : Evaluator,
  params : Array[@core.Spanned[@ast.Pattern]],
  body : @core.Spanned[@ast.Expr],
  captured : Env,
  args : Array[Value],
  span : @core.Span,
) -> Result[Value, EvalError] {
  if args.length() != params.length() {
    return Err(WrongArity(expected=params.length(), got=args.length(), span~))
  }
  let call_env = Env::with_parent(captured)
  let mut i = 0
  while i < params.length() {
    match params[i].node() {
      Ident(ident) => call_env.bind(ident.name(), args[i])
      _ => () // wildcards / tuples land with the pattern matcher
    }
    i += 1
  }
  // Swap the active env so the body sees the call frame.
  let outer = self.env
  self.set_env(call_env)
  let result = self.eval_expr(body)
  self.set_env(outer)
  result
}

///|
/// Convert an `AbsolutePitchLit` into a MIDI note number. Middle C is
/// 60; A4 is 69. Letters are A..G, accidentals are signed semitone
/// offsets (sharps positive, flats negative).
fn absolute_pitch_to_midi(lit : @ast.AbsolutePitchLit) -> Int {
  let letter = match lit.note() {
    'C' => 0
    'D' => 2
    'E' => 4
    'F' => 5
    'G' => 7
    'A' => 9
    'B' => 11
    _ => 0
  }
  // Octave 0 is MIDI 12 (so C4 = 60).
  (lit.octave() + 1) * 12 + letter + lit.accidental()
}

///|
/// Seed builtin bindings into the runtime environment. The legacy implementation
/// evaluates the relanote-source prelude (`@stdlib.PRELUDE`) for scale
/// / chord / synth definitions; this port seeds the host-implemented
/// combinators directly as `BuiltinV` values. Future sub-PRs will
/// expand the set; the long-tail scale / chord / synth presets land
/// once the parser / evaluator can drive the stdlib text.
fn install_prelude(env : Env) -> Unit {
  env.bind("reverse", BuiltinV("reverse"))
  env.bind("repeat", BuiltinV("repeat"))
  env.bind("rotate", BuiltinV("rotate"))
  env.bind("double_time", BuiltinV("double_time"))
  env.bind("octave_up", BuiltinV("octave_up"))
  env.bind("octave_down", BuiltinV("octave_down"))
  env.bind("voice", BuiltinV("voice"))
  env.bind("layer", BuiltinV("layer"))
  for
    name in [
      "Lead", "Pluck", "SoftPad", "FatBass", "FMBell", "FMRhodes", "FMKalimba", "WaveVapor",
      "WaveDriftPad", "WaveFormant", "WaveAcid", "WaveSupersaw", "GrainDrift", "GrainVocal",
      "GrainShimmer", "ModularLead", "BassMoog", "AcidBass", "SubBass", "Chiptune",
      "NES", "GameBoy", "FloatingBloom", "FloatingGlass", "LofiKick", "LofiSnare",
      "LofiHat",
    ] {
    env.bind(name, SynthV(@ast.SynthDef::new(@ast.Ident::new(name), [])))
  }
  // TODO(#8): parse + evaluate `@stdlib.PRELUDE` once block resolution
  // is in place, to bind the scale / chord / synth presets.
  let _ = @stdlib.PRELUDE
}
