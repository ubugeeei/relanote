// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/synths_fm.rela`.
pub const SYNTHS_FM : String =
  #|; ===========================================
  #|; FM synth presets
  #|; ===========================================
  #|;
  #|; Two-operator FM. `op1` is the carrier the listener hears; `op2`
  #|; modulates `op1`'s frequency. `op2_ratio` is the modulator's
  #|; frequency ratio against the carrier; `op2_level` is the modulator's
  #|; amplitude (a.k.a. the "modulation index"); `feedback` loops `op1`
  #|; back into itself for harder edges.
  #|
  #|; Soft, glassy bell — classic Yamaha DX7 vibe.
  #|synth FMBell = {
  #|  osc: FM(op1: Sine, op2: Sine, op2_ratio: 3.5, op2_level: 0.6, feedback: 0.0),
  #|  env: { A: 0.001, D: 1.6, S: 0.0, R: 1.2 },
  #|  filter: LowPass(9000, 0.1)
  #|}
  #|
  #|; Mark-1 electric piano impression. Low ratio, plenty of envelope decay.
  #|synth FMRhodes = {
  #|  osc: FM(op1: Sine, op2: Sine, op2_ratio: 1.0, op2_level: 0.4, feedback: 0.1),
  #|  env: { A: 0.005, D: 0.7, S: 0.25, R: 0.6 },
  #|  filter: LowPass(5500, 0.15)
  #|}
  #|
  #|; Wood-pick / kalimba — short attack, fast decay, no sustain.
  #|synth FMKalimba = {
  #|  osc: FM(op1: Sine, op2: Triangle, op2_ratio: 5.0, op2_level: 0.55, feedback: 0.0),
  #|  env: { A: 0.001, D: 0.45, S: 0.0, R: 0.5 },
  #|  filter: LowPass(7500, 0.1)
  #|}
  #|
  #|; Brassy stack — high ratio + feedback gives the characteristic snarl.
  #|synth FMBrass = {
  #|  osc: FM(op1: Saw, op2: Sine, op2_ratio: 2.0, op2_level: 0.7, feedback: 0.25),
  #|  env: { A: 0.05, D: 0.3, S: 0.65, R: 0.4 },
  #|  filter: LowPass(4500, 0.3)
  #|}
  #|
  #|; Detuned FM bass — fat, with a slow filter sweep on the modulator.
  #|synth FMBass = {
  #|  osc: FM(op1: Sine, op2: Triangle, op2_ratio: 0.5, op2_level: 0.8, feedback: 0.15),
  #|  detune: 6,
  #|  env: { A: 0.002, D: 0.2, S: 0.55, R: 0.3 },
  #|  filter: LowPass(1800, 0.45)
  #|}
  #|
  #|; Plucked plastic — high op2_ratio, very short decay.
  #|synth FMPluck = {
  #|  osc: FM(op1: Sine, op2: Sine, op2_ratio: 7.0, op2_level: 0.5, feedback: 0.0),
  #|  env: { A: 0.001, D: 0.25, S: 0.0, R: 0.35 },
  #|  filter: LowPass(8500, 0.1)
  #|}
