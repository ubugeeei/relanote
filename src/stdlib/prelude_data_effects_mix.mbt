// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/effects_mix.rela`.
pub const EFFECTS_MIX : String =
  #|; ===========================================
  #|; Mix-stage effects (compression, EQ, saturation)
  #|; ===========================================
  #|
  #|; Bus glue compression — slow attack, slow release, light ratio.
  #|; Use on a subgroup to "stick" the parts together.
  #|effect BusGlue = compressor {
  #|  threshold: -16,
  #|  ratio: 2.5,
  #|  attack: 0.030,
  #|  release: 0.250,
  #|  knee: 4,
  #|  makeup: 2
  #|}
  #|
  #|; Drum bus compressor — fast attack, ratio 4:1, brings out transients.
  #|effect DrumBus = compressor {
  #|  threshold: -14,
  #|  ratio: 4.0,
  #|  attack: 0.005,
  #|  release: 0.120,
  #|  knee: 2,
  #|  makeup: 3
  #|}
  #|
  #|; Parallel "New York" drum compression — heavy compression mixed back
  #|; in parallel with the dry signal.
  #|effect ParallelSmash = chain [
  #|  compressor {
  #|    threshold: -32,
  #|    ratio: 8.0,
  #|    attack: 0.001,
  #|    release: 0.060,
  #|    knee: 0,
  #|    makeup: 6,
  #|    mix: 0.5
  #|  }
  #|]
  #|
  #|; Master bus chain — gentle compression, broad EQ tilt, soft limiter.
  #|effect MasterChain = chain [
  #|  compressor { threshold: -10, ratio: 1.8, attack: 0.020, release: 0.300, knee: 6, makeup: 1 },
  #|  eq { lo: { freq: 60, gain: 1 }, hi: { freq: 12000, gain: 1.5 } },
  #|  saturate: 0.10,
  #|  limiter { ceiling: -1, lookahead: 0.005 }
  #|]
  #|
  #|; Sidechain-able vocal de-esser.
  #|effect DeEss = compressor {
  #|  threshold: -22,
  #|  ratio: 5.0,
  #|  attack: 0.001,
  #|  release: 0.080,
  #|  knee: 1,
  #|  makeup: 0,
  #|  sidechain_filter: HighPass(5000, 0.3)
  #|}
  #|
  #|; Console tape saturation — gentle harmonic warmth.
  #|effect Tape = saturate {
  #|  amount: 0.18,
  #|  bias: 0.05,
  #|  hi_cut: LowPass(14000, 0.1),
  #|  lo_bump: { freq: 80, gain: 1.5 }
  #|}
  #|
  #|; Distortion driver — bigger than `Tape`, gritty.
  #|effect Drive = saturate {
  #|  amount: 0.55,
  #|  bias: 0.1,
  #|  hi_cut: LowPass(8500, 0.15)
  #|}
  #|
  #|; Vinyl ambience — pink-noise crackle plus light wow & flutter.
  #|effect Vinyl = chain [
  #|  noise { color: Pink, level: 0.05 },
  #|  saturate { amount: 0.08 },
  #|  wow_flutter { wow: 0.2, flutter: 0.1 }
  #|]
