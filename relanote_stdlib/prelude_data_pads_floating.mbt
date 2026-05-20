// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/pads_floating.rela`.
pub const PADS_FLOATING : String =
  #|; ===========================================
  #|; Floating Points / Caribou-style pads
  #|; ===========================================
  #|;
  #|; Long, evolving, lush. Modulation is the star: every patch breathes
  #|; via an LFO on cutoff and/or pitch, and most use slow envelopes that
  #|; give the pad time to "bloom" before settling.
  #|
  #|; Slow-bloom string pad — 4-second attack, LFO drifts the formant.
  #|synth FloatingBloom = {
  #|  osc: Saw(voices: 7),
  #|  detune: 22,
  #|  env: { A: 4.0, D: 2.0, S: 1.0, R: 6.0 },
  #|  filter: LowPass(4200, 0.25),
  #|  mod: [
  #|    lfo(target: filter.cutoff, rate: 0.10, depth: 1800, shape: Sine),
  #|    env(target: filter.cutoff, attack: 3.5, depth: 2800)
  #|  ]
  #|}
  #|
  #|; "Crush" pad — light bit-crushing on a saw stack for vinyl crackle.
  #|synth FloatingCrush = {
  #|  osc: Saw(voices: 5),
  #|  detune: 16,
  #|  env: { A: 2.0, D: 1.0, S: 0.95, R: 3.0 },
  #|  filter: LowPass(3800, 0.2),
  #|  bitcrush: { bits: 10, rate: 0.85 },
  #|  mod: [
  #|    lfo(target: filter.cutoff, rate: 0.07, depth: 1500, shape: Sine)
  #|  ]
  #|}
  #|
  #|; Choral aaaah — three formants, slow vibrato.
  #|synth FloatingChoir = {
  #|  osc: Wavetable(table: "vowels", voices: 5),
  #|  wave_pos: 0.45,
  #|  detune: 18,
  #|  env: { A: 2.5, D: 0.8, S: 1.0, R: 4.5 },
  #|  filter: BandPass(1400, 0.55),
  #|  mod: [
  #|    lfo(target: pitch, rate: 4.5, depth: 10, shape: Sine, delay: 0.6),
  #|    lfo(target: wave_pos, rate: 0.09, depth: 0.18, shape: Sine)
  #|  ]
  #|}
  #|
  #|; Glass shimmer — sine layered with metallic wavetable, sparse high air.
  #|synth FloatingGlass = {
  #|  osc: Sine + Wavetable(table: "metallic", level: 0.45),
  #|  env: { A: 1.5, D: 0.6, S: 0.9, R: 3.5 },
  #|  filter: HighPass(800, 0.3),
  #|  mod: [
  #|    lfo(target: filter.cutoff, rate: 0.14, depth: 600, shape: Triangle)
  #|  ]
  #|}
  #|
  #|; Ambient drone — single sub-sine with a slow tremolo on amplitude.
  #|synth FloatingDrone = {
  #|  osc: Sine,
  #|  env: { A: 5.0, D: 1.0, S: 1.0, R: 8.0 },
  #|  filter: LowPass(900, 0.1),
  #|  mod: [
  #|    lfo(target: amp, rate: 0.05, depth: 0.25, shape: Sine)
  #|  ]
  #|}
  #|
  #|; "Late-night" granular drift — a granular cloud anchored to the chord.
  #|synth FloatingDrift = {
  #|  osc: Granular(source: "ensemble", grain_size: 0.07, density: 32, spray: 0.45, pitch_jitter: 25),
  #|  env: { A: 2.0, D: 1.0, S: 1.0, R: 4.0 },
  #|  filter: LowPass(4000, 0.2),
  #|  mod: [
  #|    lfo(target: filter.cutoff, rate: 0.11, depth: 1400, shape: Sine)
  #|  ]
  #|}
