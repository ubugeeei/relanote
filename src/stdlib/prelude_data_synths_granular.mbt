// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/synths_granular.rela`.
pub const SYNTHS_GRANULAR : String =
  #|; ===========================================
  #|; Granular synth presets
  #|; ===========================================
  #|;
  #|; Granular synthesis chops a source buffer into tiny grains (5–100 ms)
  #|; and rearranges them. `grain_size` is the grain length in seconds,
  #|; `density` is grains per second, `spray` randomises position within
  #|; the buffer (0 = locked, 1 = scattered), `pitch_jitter` randomises
  #|; each grain's playback rate in cents. The source string picks the
  #|; sample bank.
  #|
  #|; Floating, slowly-blooming pad — long grains, dense, low spray.
  #|synth GrainDrift = {
  #|  osc: Granular(source: "drone", grain_size: 0.08, density: 28, spray: 0.4, pitch_jitter: 0),
  #|  env: { A: 1.5, D: 0.5, S: 1.0, R: 2.5 },
  #|  filter: LowPass(4500, 0.2)
  #|}
  #|
  #|; Chopped vocal texture — Flying Lotus / Hiatus Kaiyote sleeve.
  #|synth GrainVocal = {
  #|  osc: Granular(source: "vocal", grain_size: 0.03, density: 60, spray: 0.7, pitch_jitter: 40),
  #|  env: { A: 0.05, D: 0.4, S: 0.7, R: 0.6 },
  #|  filter: BandPass(1500, 0.6)
  #|}
  #|
  #|; Rain-of-glass shimmer — micro grains, very dense, fully scattered.
  #|synth GrainShimmer = {
  #|  osc: Granular(source: "metallic", grain_size: 0.015, density: 120, spray: 1.0, pitch_jitter: 200),
  #|  env: { A: 0.1, D: 0.6, S: 0.85, R: 1.8 },
  #|  filter: HighPass(2500, 0.3)
  #|}
  #|
  #|; Slow-motion grain pad — large grains, light density, locked position.
  #|synth GrainSlowmo = {
  #|  osc: Granular(source: "ensemble", grain_size: 0.12, density: 14, spray: 0.1, pitch_jitter: 0),
  #|  env: { A: 2.0, D: 0.8, S: 1.0, R: 3.5 },
  #|  filter: LowPass(3200, 0.15)
  #|}
  #|
  #|; Tape-stuck stutter — short grains looping a tiny window, sounds like
  #|; tape head jitter.
  #|synth GrainStutter = {
  #|  osc: Granular(source: "drum_break", grain_size: 0.025, density: 80, spray: 0.05, pitch_jitter: 10),
  #|  env: { A: 0.002, D: 0.15, S: 0.4, R: 0.25 },
  #|  filter: LowPass(5500, 0.2)
  #|}
  #|
  #|; Reverse-grain cloud — every grain plays backwards.
  #|synth GrainReverse = {
  #|  osc: Granular(source: "vocal", grain_size: 0.06, density: 45, spray: 0.6, pitch_jitter: 0, reverse: true),
  #|  env: { A: 0.3, D: 0.7, S: 0.8, R: 1.5 },
  #|  filter: LowPass(4200, 0.25)
  #|}
