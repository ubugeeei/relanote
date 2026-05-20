// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/synths_keys.rela`.
pub const SYNTHS_KEYS : String =
  #|; ===========================================
  #|; Electric piano / vintage keys presets
  #|; ===========================================
  #|
  #|; Rhodes Mark I — soft, woody, classic.
  #|synth KeysRhodes = {
  #|  osc: FM(op1: Sine, op2: Sine, op2_ratio: 1.0, op2_level: 0.45, feedback: 0.12),
  #|  env: { A: 0.005, D: 0.8, S: 0.3, R: 0.7 },
  #|  filter: LowPass(5500, 0.15),
  #|  tremolo: { rate: 5.5, depth: 0.2 }
  #|}
  #|
  #|; Wurlitzer 200A — barky mid, slightly metallic.
  #|synth KeysWurly = {
  #|  osc: FM(op1: Sine, op2: Triangle, op2_ratio: 1.0, op2_level: 0.55, feedback: 0.2),
  #|  env: { A: 0.003, D: 0.55, S: 0.35, R: 0.45 },
  #|  filter: BandPass(1800, 0.4),
  #|  tremolo: { rate: 6.5, depth: 0.4 }
  #|}
  #|
  #|; Clavinet — short, percussive, midrange-forward.
  #|synth KeysClav = {
  #|  osc: Square,
  #|  env: { A: 0.001, D: 0.2, S: 0.4, R: 0.2 },
  #|  filter: BandPass(1400, 0.55),
  #|  saturate: 0.25
  #|}
  #|
  #|; CP-70 electric grand — bright, biting hammers.
  #|synth KeysCP70 = {
  #|  osc: Triangle + Sine(level: 0.6, octave: 1),
  #|  env: { A: 0.002, D: 1.2, S: 0.25, R: 0.8 },
  #|  filter: LowPass(6500, 0.15)
  #|}
  #|
  #|; Soft analog organ pad — dual sine harmonics.
  #|synth KeysOrgan = {
  #|  osc: Sine + Sine(level: 0.7, octave: 1) + Sine(level: 0.4, octave: 2),
  #|  env: { A: 0.02, D: 0.1, S: 0.95, R: 0.4 },
  #|  filter: LowPass(5000, 0.15)
  #|}
  #|
  #|; Detuned upright piano impression.
  #|synth KeysUpright = {
  #|  osc: Triangle(voices: 3) + Sine(level: 0.3, octave: -1),
  #|  detune: 8,
  #|  env: { A: 0.002, D: 1.0, S: 0.3, R: 0.9 },
  #|  filter: LowPass(5500, 0.18)
  #|}
