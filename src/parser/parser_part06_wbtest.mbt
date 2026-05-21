///|
test "synth declaration parses supported properties" {
  let src =
    #|synth DeepSub = {
    #|  osc: Sine,
    #|  env: envelope(0.01, 0.2, 0.95, 0.3),
    #|  filter: LowPass(54, 0.0),
    #|  detune: 12,
    #|  pitch_env: PitchDrop
    #|}
  let (program, diags) = parse(src)
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    @ast.SynthDef(def) => {
      assert_eq(def.name().name(), "DeepSub")
      let props = def.properties()
      assert_eq(props.length(), 5)
      match props[0].node() {
        @ast.Oscillator(_) => ()
        _ => abort("expected oscillator property")
      }
      match props[1].node() {
        @ast.Envelope(_) => ()
        _ => abort("expected envelope property")
      }
      match props[2].node() {
        @ast.Filter(_) => ()
        _ => abort("expected filter property")
      }
      match props[3].node() {
        @ast.Detune(_) => ()
        _ => abort("expected detune property")
      }
      match props[4].node() {
        @ast.PitchEnvelope(_) => ()
        _ => abort("expected pitch envelope property")
      }
    }
    _ => abort("expected synth definition")
  }
}

///|
test "unknown synth property reports a diagnostic" {
  let (_, diags) = parse("synth Bad = { shimmer: 1 }")
  assert_true(diags.has_errors())
}

///|
test "layered synth oscillator expressions parse" {
  let src =
    #|synth DetailedKeys = {
    #|  osc: (FM(Sine, 2.98, 0.32) |> mix 0.44) +
    #|       (Sine |> mix 0.2) +
    #|       (Triangle |> mix 0.2 |> octave 1) +
    #|       (Sine |> mix 0.16 |> octave (-1)),
    #|  env: envelope(0.006, 0.72, 0.28, 1.15),
    #|  filter: LowPass(6400, 0.18),
    #|  detune: -3
    #|}
  let (program, diags) = parse(src)
  assert_false(diags.has_errors())
  match program.items()[0].node() {
    @ast.SynthDef(def) => assert_eq(def.properties().length(), 4)
    _ => abort("expected synth definition")
  }
}
