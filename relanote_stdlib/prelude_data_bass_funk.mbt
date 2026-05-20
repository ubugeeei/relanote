// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/bass_funk.rela`.
pub const BASS_FUNK : String =
  #|; ===========================================
  #|; Funk / dub / hip-hop bass presets
  #|; ===========================================
  #|
  #|; Roundwound electric bass — short sustain, mid presence.
  #|synth BassRound = {
  #|  osc: Saw + Sine(level: 0.6, octave: -1),
  #|  env: { A: 0.002, D: 0.4, S: 0.55, R: 0.25 },
  #|  filter: LowPass(1400, 0.4),
  #|  saturate: 0.2
  #|}
  #|
  #|; Slap bass — quick attack, percussive envelope on filter.
  #|synth BassSlap = {
  #|  osc: Saw + Sine(level: 0.5, octave: -1),
  #|  env: { A: 0.001, D: 0.18, S: 0.45, R: 0.15 },
  #|  filter: LowPass(900, 0.55),
  #|  mod: [
  #|    env(target: filter.cutoff, attack: 0.0, depth: 3500)
  #|  ]
  #|}
  #|
  #|; Mwah Moog bass — resonant cutoff that opens on each note.
  #|synth BassMoog = {
  #|  osc: Saw,
  #|  env: { A: 0.003, D: 0.25, S: 0.55, R: 0.25 },
  #|  filter: LowPass(700, 0.7),
  #|  mod: [
  #|    env(target: filter.cutoff, attack: 0.0, depth: 3200)
  #|  ]
  #|}
  #|
  #|; Dub sub — pure sine, long release, no harmonic content above ~120 Hz.
  #|synth BassDubSub = {
  #|  osc: Sine,
  #|  env: { A: 0.005, D: 0.5, S: 0.85, R: 0.6 },
  #|  filter: LowPass(160, 0.1)
  #|}
  #|
  #|; Reese bass — two detuned saws, narrow band of low frequencies.
  #|synth BassReese = {
  #|  osc: Saw(voices: 2),
  #|  detune: 18,
  #|  env: { A: 0.002, D: 0.6, S: 0.85, R: 0.3 },
  #|  filter: BandPass(220, 0.7)
  #|}
  #|
  #|; FlyLo wobble bass — slow LFO sweeps the cutoff.
  #|synth BassWobble = {
  #|  osc: Saw + Square(level: 0.6, octave: -1),
  #|  env: { A: 0.001, D: 0.4, S: 0.7, R: 0.3 },
  #|  filter: LowPass(800, 0.7),
  #|  mod: [
  #|    lfo(target: filter.cutoff, rate: 2.0, depth: 1600, shape: Sine, sync: "1/2")
  #|  ]
  #|}
  #|
  #|; Upright bass impression — pluck attack, woody body.
  #|synth BassUpright = {
  #|  osc: Triangle + Sine(level: 0.4, octave: -1),
  #|  env: { A: 0.002, D: 0.7, S: 0.15, R: 0.4 },
  #|  filter: LowPass(900, 0.25)
  #|}
