// Smoke tests for the embedded prelude. Confirms every prelude file
// is actually embedded and the combined string contains the markers
// downstream parsers expect.

test "every prelude module is non-empty" {
  // Theory primitives.
  assert_true(TUNINGS.length() > 0)
  assert_true(SCALES.length() > 0)
  assert_true(CHORDS.length() > 0)
  assert_true(GROOVES.length() > 0)
  // Synthesis layer.
  assert_true(SYNTHS_BASIC.length() > 0)
  assert_true(SYNTHS_FM.length() > 0)
  assert_true(SYNTHS_WAVETABLE.length() > 0)
  assert_true(SYNTHS_GRANULAR.length() > 0)
  assert_true(SYNTHS_MODULAR.length() > 0)
  assert_true(SYNTHS_PIANO.length() > 0)
  assert_true(SYNTHS_KEYS.length() > 0)
  assert_true(SYNTHS_BASS.length() > 0)
  assert_true(BASS_FUNK.length() > 0)
  assert_true(SYNTHS_BRASS.length() > 0)
  assert_true(SYNTHS_LEADS.length() > 0)
  assert_true(SYNTHS_PADS.length() > 0)
  assert_true(PADS_FLOATING.length() > 0)
  assert_true(SYNTHS_PLUCK.length() > 0)
  assert_true(SYNTHS_DRUMS.length() > 0)
  assert_true(DRUMS_LOFI.length() > 0)
  assert_true(SYNTHS_PERCUSSION.length() > 0)
  assert_true(SYNTHS_RETRO.length() > 0)
  assert_true(SYNTHS_CLAP.length() > 0)
  // Effects.
  assert_true(EFFECTS_REVERB.length() > 0)
  assert_true(EFFECTS_DELAY.length() > 0)
  assert_true(EFFECTS_PHASER.length() > 0)
  assert_true(EFFECTS_DISTORTION.length() > 0)
  assert_true(EFFECTS_DUB.length() > 0)
  assert_true(EFFECTS_MIX.length() > 0)
}

test "theory primitives carry their headline definitions" {
  assert_true(SCALES.contains("scale Major"))
  assert_true(CHORDS.contains("chord MajorTriad"))
  assert_true(TUNINGS.contains("tuning EDO24"))
  assert_true(TUNINGS.contains("tuning JustIntonation"))
  assert_true(GROOVES.contains("groove Swing67"))
  assert_true(GROOVES.contains("groove Dilla"))
}

test "synth presets carry their flagship patches" {
  assert_true(SYNTHS_FM.contains("synth FMBell"))
  assert_true(SYNTHS_WAVETABLE.contains("synth WaveVapor"))
  assert_true(SYNTHS_GRANULAR.contains("synth GrainDrift"))
  assert_true(SYNTHS_MODULAR.contains("synth ModularEnsemble"))
  assert_true(PADS_FLOATING.contains("synth FloatingBloom"))
  assert_true(SYNTHS_KEYS.contains("synth KeysRhodes"))
  assert_true(BASS_FUNK.contains("synth BassReese"))
  assert_true(DRUMS_LOFI.contains("synth LofiKick"))
}

test "effects carry their dub and mix patches" {
  assert_true(EFFECTS_DUB.contains("effect DubDelay"))
  assert_true(EFFECTS_DUB.contains("effect TapeEcho"))
  assert_true(EFFECTS_MIX.contains("effect BusGlue"))
  assert_true(EFFECTS_MIX.contains("effect MasterChain"))
}

test "PRELUDE concatenates every module" {
  // Theory.
  assert_true(PRELUDE.contains("tuning JustIntonation"))
  assert_true(PRELUDE.contains("scale Major"))
  assert_true(PRELUDE.contains("chord MajorTriad"))
  assert_true(PRELUDE.contains("groove Dilla"))
  // Synth presets.
  assert_true(PRELUDE.contains("synth FMBell"))
  assert_true(PRELUDE.contains("synth FloatingBloom"))
  assert_true(PRELUDE.contains("synth GrainDrift"))
  // Mix-stage effects.
  assert_true(PRELUDE.contains("effect BusGlue"))
  assert_true(PRELUDE.contains("effect MasterChain"))
  // Header banner present.
  assert_true(PRELUDE.contains("Relanote Standard Prelude"))
}
