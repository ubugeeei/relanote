// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/synths_modular.rela`.
pub const SYNTHS_MODULAR : String =
  #|; ===========================================
  #|; Modular-style analog synth presets
  #|; ===========================================
  #|;
  #|; Patches inspired by the lush analog / modular palette common to
  #|; Floating Points, Caribou, Bicep and similar. Each one has at least
  #|; one LFO modulating a filter or pitch parameter so the sound *moves*.
  #|
  #|; Lush ensemble pad — three detuned saws, slow LFO on cutoff.
  #|synth ModularEnsemble = {
  #|  osc: Saw(voices: 3),
  #|  detune: 14,
  #|  env: { A: 1.2, D: 0.5, S: 1.0, R: 2.0 },
  #|  filter: LowPass(3500, 0.3),
  #|  mod: [
  #|    lfo(target: filter.cutoff, rate: 0.18, depth: 2000, shape: Sine),
  #|    lfo(target: pitch, rate: 5.5, depth: 8, shape: Sine)
  #|  ]
  #|}
  #|
  #|; Long, breathing pad with chorus-like detune. Faster filter envelope
  #|; than the ensemble so the top end blooms over a longer A/D.
  #|synth ModularBreath = {
  #|  osc: Saw(voices: 5),
  #|  detune: 20,
  #|  env: { A: 2.5, D: 1.0, S: 0.95, R: 4.0 },
  #|  filter: LowPass(4500, 0.25),
  #|  mod: [
  #|    env(target: filter.cutoff, attack: 2.0, depth: 3500),
  #|    lfo(target: filter.cutoff, rate: 0.08, depth: 1200, shape: Sine)
  #|  ]
  #|}
  #|
  #|; Resonant analog lead — single saw, fast envelope, biting cutoff.
  #|synth ModularLead = {
  #|  osc: Saw,
  #|  env: { A: 0.01, D: 0.2, S: 0.7, R: 0.4 },
  #|  filter: LowPass(2500, 0.65),
  #|  mod: [
  #|    env(target: filter.cutoff, attack: 0.05, depth: 2500),
  #|    lfo(target: pitch, rate: 5.0, depth: 10, shape: Sine, delay: 0.2)
  #|  ]
  #|}
  #|
  #|; Sub-heavy modular bass — sine sub layered with filtered saw.
  #|synth ModularBass = {
  #|  osc: Saw + Sine(level: 0.8, octave: -1),
  #|  env: { A: 0.005, D: 0.4, S: 0.6, R: 0.3 },
  #|  filter: LowPass(900, 0.55),
  #|  mod: [
  #|    env(target: filter.cutoff, attack: 0.0, depth: 1800)
  #|  ]
  #|}
  #|
  #|; Sample-and-hold modular bleeps — random pitches at LFO rate.
  #|synth ModularSH = {
  #|  osc: Square,
  #|  env: { A: 0.001, D: 0.1, S: 0.0, R: 0.1 },
  #|  filter: LowPass(3500, 0.5),
  #|  mod: [
  #|    lfo(target: pitch, rate: 4.0, depth: 700, shape: SampleHold)
  #|  ]
  #|}
  #|
  #|; Slow-attack analog string — orchestral string pad without the cliché.
  #|synth ModularString = {
  #|  osc: Saw(voices: 6) + Triangle(level: 0.4),
  #|  detune: 12,
  #|  env: { A: 0.8, D: 0.6, S: 0.9, R: 1.5 },
  #|  filter: LowPass(5500, 0.2)
  #|}
