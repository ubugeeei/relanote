// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash moonbit/scripts/gen_stdlib.sh
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

///|
/// Embedded source of `prelude/chords.rela`.
pub const CHORDS : String =
  #|; ===========================================
  #|; Chords
  #|; ===========================================
  #|
  #|; Basic triads
  #|chord MajorTriad = [ R, M3, P5 ]
  #|chord MinorTriad = [ R, m3, P5 ]
  #|chord Diminished = [ R, m3, d5 ]
  #|chord Augmented = [ R, M3, A5 ]
  #|
  #|; Seventh chords
  #|chord Major7 = [ R, M3, P5, M7 ]
  #|chord Minor7 = [ R, m3, P5, m7 ]
  #|chord Dominant7 = [ R, M3, P5, m7 ]
  #|chord MinorMajor7 = [ R, m3, P5, M7 ]
  #|chord HalfDiminished7 = [ R, m3, d5, m7 ]
  #|chord Diminished7 = [ R, m3, d5, M6 ]
  #|
  #|; Suspended chords
  #|chord Sus2 = [ R, M2, P5 ]
  #|chord Sus4 = [ R, P4, P5 ]
  #|chord Add9 = [ R, M3, P5, M9 ]

///|
/// Embedded source of `prelude/drums_lofi.rela`.
pub const DRUMS_LOFI : String =
  #|; ===========================================
  #|; Lo-fi / Flying Lotus-style drums
  #|; ===========================================
  #|;
  #|; Drum patches that sit slightly off-grid. Each one combines a short
  #|; transient layer with a noise body, and most include a small amount
  #|; of bit-crush or sample-rate reduction so they feel "broken".
  #|
  #|; Dusty kick — quick pitch envelope down, light bit-crush, soft tail.
  #|synth LofiKick = {
  #|  osc: Sine + Triangle(level: 0.35),
  #|  pitch_env: { from: 220, to: 55, time: 0.06 },
  #|  env: { A: 0.001, D: 0.18, S: 0.0, R: 0.18 },
  #|  filter: LowPass(2200, 0.2),
  #|  bitcrush: { bits: 9, rate: 0.7 }
  #|}
  #|
  #|; Tape-saturated snare — noise body, short transient, gentle drive.
  #|synth LofiSnare = {
  #|  osc: Noise(color: Pink) + Triangle(level: 0.25, octave: 1),
  #|  env: { A: 0.001, D: 0.12, S: 0.0, R: 0.15 },
  #|  filter: BandPass(1800, 0.55),
  #|  saturate: 0.35
  #|}
  #|
  #|; Dust hat — short noise burst, high cut, lo-fi bit reduction.
  #|synth LofiHat = {
  #|  osc: Noise(color: White),
  #|  env: { A: 0.001, D: 0.04, S: 0.0, R: 0.04 },
  #|  filter: HighPass(6500, 0.2),
  #|  bitcrush: { bits: 8, rate: 0.5 }
  #|}
  #|
  #|; Open hat / shaker — longer noise tail, low resonance.
  #|synth LofiOpenHat = {
  #|  osc: Noise(color: White),
  #|  env: { A: 0.001, D: 0.25, S: 0.1, R: 0.25 },
  #|  filter: HighPass(5500, 0.15),
  #|  bitcrush: { bits: 8, rate: 0.5 }
  #|}
  #|
  #|; Cardboard rim — short, woody, mid-focused.
  #|synth LofiRim = {
  #|  osc: Triangle + Noise(color: White, level: 0.3),
  #|  pitch_env: { from: 1400, to: 800, time: 0.01 },
  #|  env: { A: 0.001, D: 0.06, S: 0.0, R: 0.08 },
  #|  filter: BandPass(1500, 0.6)
  #|}
  #|
  #|; Sample-chopped break — granular-style stutter.
  #|synth LofiBreak = {
  #|  osc: Granular(source: "drum_break", grain_size: 0.04, density: 50, spray: 0.4, pitch_jitter: 12),
  #|  env: { A: 0.001, D: 0.3, S: 0.4, R: 0.3 },
  #|  filter: LowPass(5000, 0.25),
  #|  bitcrush: { bits: 10, rate: 0.75 }
  #|}
  #|
  #|; Sub thump — pure sub-sine kick layer.
  #|synth LofiSub = {
  #|  osc: Sine,
  #|  pitch_env: { from: 70, to: 40, time: 0.08 },
  #|  env: { A: 0.001, D: 0.25, S: 0.0, R: 0.25 },
  #|  filter: LowPass(180, 0.1)
  #|}

///|
/// Embedded source of `prelude/effects_delay.rela`.
pub const EFFECTS_DELAY : String =
  #|; ===========================================
  #|; Delay Effect Presets
  #|; ===========================================
  #|
  #|; Slapback delay - rockabilly/vintage style
  #|let slapback = \x -> x |> delay 80 0.2 0.4
  #|
  #|; Short delay - subtle doubling
  #|let short_delay = \x -> x |> delay 125 0.25 0.35
  #|
  #|; Stereo delay - classic stereo widening
  #|let stereo_delay = \x -> x |> delay 375 0.35 0.5
  #|
  #|; Dotted eighth delay - U2/Edge style
  #|let dotted_eighth_delay = \x -> x |> delay 562 0.4 0.45
  #|
  #|; Quarter note delay - rhythmic echo
  #|let quarter_delay = \x -> x |> delay 500 0.35 0.4
  #|
  #|; Ping pong delay - bouncing stereo
  #|let pingpong_delay = \x -> x |> delay 250 0.45 0.5
  #|
  #|; Tape delay - warm analog character
  #|let tape_delay = \x -> x |> delay 400 0.5 0.4
  #|
  #|; Ambient delay - long atmospheric
  #|let ambient_delay = \x -> x |> delay 800 0.6 0.35
  #|
  #|; Dub delay - heavy feedback reggae style
  #|let dub_delay = \x -> x |> delay 600 0.7 0.55
  #|
  #|; Shimmer delay - ethereal trails
  #|let shimmer_delay = \x -> x |> delay 700 0.55 0.45

///|
/// Embedded source of `prelude/effects_distortion.rela`.
pub const EFFECTS_DISTORTION : String =
  #|; ===========================================
  #|; Distortion Effect Presets
  #|; ===========================================
  #|
  #|; Subtle saturation - warm tube-like
  #|let saturation = \x -> x |> distortion 0.15 SoftClip 0.6
  #|
  #|; Light overdrive - slight breakup
  #|let light_overdrive = \x -> x |> distortion 0.25 SoftClip 0.65
  #|
  #|; Warm overdrive - classic tube tone
  #|let warm_overdrive = \x -> x |> distortion 0.35 SoftClip 0.7
  #|
  #|; Crunch - moderate distortion
  #|let crunch = \x -> x |> distortion 0.45 SoftClip 0.75
  #|
  #|; Classic distortion - rock/metal tone
  #|let classic_dist = \x -> x |> distortion 0.55 HardClip 0.8
  #|
  #|; Heavy distortion - aggressive sound
  #|let heavy_dist = \x -> x |> distortion 0.7 HardClip 0.85
  #|
  #|; Light fuzz - vintage fuzz tone
  #|let light_fuzz = \x -> x |> distortion 0.5 Fuzz 0.7
  #|
  #|; Heavy fuzz - thick, buzzy tone
  #|let heavy_fuzz = \x -> x |> distortion 0.8 Fuzz 0.9
  #|
  #|; Classic fuzz - 60s/70s character
  #|let classic_fuzz = \x -> x |> distortion 0.65 Fuzz 0.8
  #|
  #|; Lo-fi crush - bit reduction effect
  #|let lofi_crush = \x -> x |> distortion 0.6 BitCrush 0.7
  #|
  #|; 8-bit crush - retro game sound
  #|let bit8_crush = \x -> x |> distortion 0.75 BitCrush 0.8
  #|
  #|; Extreme crush - heavily degraded
  #|let extreme_crush = \x -> x |> distortion 0.9 BitCrush 0.9

///|
/// Embedded source of `prelude/effects_dub.rela`.
pub const EFFECTS_DUB : String =
  #|; ===========================================
  #|; Dub / spacey effect presets
  #|; ===========================================
  #|;
  #|; Effect presets, applied via the `effect` keyword:
  #|;
  #|;   track |> effect DubDelay
  #|;
  #|; Most of these chain inside themselves — a single named preset can
  #|; cover a long delay → filter → reverb path.
  #|
  #|; Quarter-note tape delay with feedback and high-cut.
  #|effect DubDelay = delay {
  #|  time: "1/4",
  #|  feedback: 0.55,
  #|  mix: 0.35,
  #|  filter: LowPass(3500, 0.2),
  #|  saturate: 0.15
  #|}
  #|
  #|; Dotted-eighth delay (the U2 / Edge sound).
  #|effect DottedDelay = delay {
  #|  time: "3/16",
  #|  feedback: 0.4,
  #|  mix: 0.3,
  #|  filter: LowPass(5500, 0.15)
  #|}
  #|
  #|; Tape echo with wow and flutter — pitch wobbles slowly.
  #|effect TapeEcho = delay {
  #|  time: "1/8.",
  #|  feedback: 0.55,
  #|  mix: 0.35,
  #|  filter: LowPass(2800, 0.3),
  #|  saturate: 0.25,
  #|  wow: 0.3,
  #|  flutter: 0.15
  #|}
  #|
  #|; Long plate-style reverb — large room, dark tail.
  #|effect PlateLarge = reverb {
  #|  size: 0.85,
  #|  decay: 4.5,
  #|  damping: 0.6,
  #|  mix: 0.35,
  #|  pre_delay: 0.04
  #|}
  #|
  #|; Bright spring reverb — short, metallic.
  #|effect SpringBright = reverb {
  #|  size: 0.25,
  #|  decay: 1.2,
  #|  damping: 0.15,
  #|  mix: 0.25,
  #|  pre_delay: 0.005
  #|}
  #|
  #|; "Dub room" — short delay into long reverb, ducked by sidechain.
  #|effect DubRoom = chain [
  #|  delay { time: "1/4", feedback: 0.45, mix: 0.3, filter: LowPass(3000, 0.2) },
  #|  reverb { size: 0.7, decay: 3.5, damping: 0.55, mix: 0.4 }
  #|]
  #|
  #|; Phaser sweep — slow, deep, classic.
  #|effect PhaserSlow = phaser {
  #|  rate: 0.15,
  #|  depth: 0.85,
  #|  feedback: 0.65,
  #|  stages: 6,
  #|  mix: 0.4
  #|}
  #|
  #|; Granular freeze — captures the last 0.5s and loops it.
  #|effect Freeze = granular {
  #|  buffer: "live",
  #|  grain_size: 0.04,
  #|  density: 80,
  #|  spray: 0.5,
  #|  mix: 0.6
  #|}

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

///|
/// Embedded source of `prelude/effects_phaser.rela`.
pub const EFFECTS_PHASER : String =
  #|; ===========================================
  #|; Phaser Effect Presets
  #|; ===========================================
  #|
  #|; Subtle phaser - gentle movement
  #|let subtle_phaser = \x -> x |> phaser 0.2 0.3 0.3
  #|
  #|; Slow phaser - sweeping motion
  #|let slow_phaser = \x -> x |> phaser 0.3 0.5 0.4
  #|
  #|; Classic phaser - vintage character
  #|let classic_phaser = \x -> x |> phaser 0.5 0.6 0.5
  #|
  #|; Fast phaser - quick modulation
  #|let fast_phaser = \x -> x |> phaser 2.0 0.5 0.45
  #|
  #|; Deep phaser - pronounced effect
  #|let deep_phaser = \x -> x |> phaser 0.4 0.8 0.6
  #|
  #|; Jet phaser - airplane-like sweep
  #|let jet_phaser = \x -> x |> phaser 0.15 0.9 0.7
  #|
  #|; Funk phaser - auto-wah like
  #|let funk_phaser = \x -> x |> phaser 1.5 0.6 0.55
  #|
  #|; Space phaser - sci-fi character
  #|let space_phaser = \x -> x |> phaser 0.1 0.85 0.65
  #|
  #|; Wobble phaser - tremolo-like
  #|let wobble_phaser = \x -> x |> phaser 3.0 0.4 0.4
  #|
  #|; Liquid phaser - smooth flowing
  #|let liquid_phaser = \x -> x |> phaser 0.25 0.7 0.5

///|
/// Embedded source of `prelude/effects_reverb.rela`.
pub const EFFECTS_REVERB : String =
  #|; ===========================================
  #|; Reverb Effect Presets
  #|; ===========================================
  #|
  #|; Small room reverb - intimate, close sound
  #|let room_reverb = \x -> x |> reverb 0.25
  #|
  #|; Studio room reverb - controlled ambience
  #|let studio_reverb = \x -> x |> reverb 0.35
  #|
  #|; Spring reverb - classic vintage character
  #|let spring_reverb = \x -> x |> reverb 0.45
  #|
  #|; Chamber reverb - medium space
  #|let chamber_reverb = \x -> x |> reverb 0.55
  #|
  #|; Hall reverb - concert hall ambience
  #|let hall_reverb = \x -> x |> reverb 0.65
  #|
  #|; Ambient reverb - lush, atmospheric
  #|let ambient_reverb = \x -> x |> reverb 0.75
  #|
  #|; Cathedral reverb - massive space
  #|let cathedral_reverb = \x -> x |> reverb 0.85
  #|
  #|; Infinite reverb - ethereal, endless
  #|let infinite_reverb = \x -> x |> reverb 0.95

///|
/// Embedded source of `prelude/grooves.rela`.
pub const GROOVES : String =
  #|; ===========================================
  #|; Groove presets
  #|; ===========================================
  #|;
  #|; A groove is a per-slot timing offset (in fractions of a slot) applied
  #|; on top of an otherwise perfectly equal block. Activate one with
  #|;
  #|;   set groove = Dilla
  #|;
  #|; or apply it to a specific block with the pipe:
  #|;
  #|;   track |> groove Dilla
  #|;
  #|; The pattern repeats every `length` slots. Positive numbers push the
  #|; slot *later*; negative numbers pull it earlier.
  #|
  #|; Straight — no swing, baseline.
  #|groove Straight = offsets {
  #|  length: 4,
  #|  steps: [0.0, 0.0, 0.0, 0.0]
  #|}
  #|
  #|; 8th-note swing 67% — classic jazz feel (a triplet feel against
  #|; eighths).
  #|groove Swing67 = offsets {
  #|  length: 2,
  #|  steps: [0.0, 0.17]
  #|}
  #|
  #|; Hard 16th swing 75% — pushes the offbeat sixteenths late.
  #|groove Swing75 = offsets {
  #|  length: 4,
  #|  steps: [0.0, 0.25, 0.0, 0.25]
  #|}
  #|
  #|; Dilla / hip-hop drunken feel — snare slightly behind, hat-hats
  #|; alternately rushing and dragging.
  #|groove Dilla = offsets {
  #|  length: 16,
  #|  steps: [
  #|     0.00,  0.04, -0.02,  0.05,
  #|    -0.03,  0.06,  0.02,  0.07,
  #|     0.00,  0.05, -0.02,  0.05,
  #|    -0.04,  0.07,  0.02,  0.08
  #|  ]
  #|}
  #|
  #|; Bossa nova — pushed downbeats, late ands.
  #|groove Bossa = offsets {
  #|  length: 8,
  #|  steps: [0.0, 0.03, 0.0, 0.08, -0.02, 0.04, 0.0, 0.06]
  #|}
  #|
  #|; Shuffle — hat-hat-snare boogie pattern.
  #|groove Shuffle = offsets {
  #|  length: 6,
  #|  steps: [0.0, 0.0, 0.12, 0.0, 0.0, 0.12]
  #|}
  #|
  #|; Half-time crawl — pulls beats 2 and 4 late, lazy hip-hop.
  #|groove HalfTimeLazy = offsets {
  #|  length: 8,
  #|  steps: [0.0, 0.0, 0.06, 0.0, 0.0, 0.0, 0.06, 0.0]
  #|}
  #|
  #|; Drunken — every step jitters a little.
  #|groove Drunken = offsets {
  #|  length: 8,
  #|  steps: [0.02, -0.03, 0.04, -0.02, 0.03, -0.04, 0.02, -0.03]
  #|}

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

///|
/// Embedded source of `prelude/scales.rela`.
pub const SCALES : String =
  #|; ===========================================
  #|; Scales
  #|; ===========================================
  #|
  #|; Basic Scales
  #|scale Major = { R, M2, M3, P4, P5, M6, M7 }
  #|scale Minor = { R, M2, m3, P4, P5, m6, m7 }
  #|scale Dorian = { R, M2, m3, P4, P5, M6, m7 }
  #|scale Phrygian = { R, m2, m3, P4, P5, m6, m7 }
  #|scale Lydian = { R, M2, M3, A4, P5, M6, M7 }
  #|scale Mixolydian = { R, M2, M3, P4, P5, M6, m7 }
  #|scale Locrian = { R, m2, m3, P4, d5, m6, m7 }
  #|
  #|; Pentatonic scales
  #|scale MajorPentatonic = { R, M2, M3, P5, M6 }
  #|scale MinorPentatonic = { R, m3, P4, P5, m7 }
  #|
  #|; Blues scale
  #|scale Blues = { R, m3, P4, A4, P5, m7 }
  #|
  #|; Harmonic and melodic minor
  #|scale HarmonicMinor = { R, M2, m3, P4, P5, m6, M7 }
  #|scale MelodicMinor = { R, M2, m3, P4, P5, M6, M7 }
  #|
  #|; Bebop scales
  #|scale BebopDominant = { R, M2, M3, P4, P5, M6, m7, M7 }
  #|scale BebopMajor = { R, M2, M3, P4, P5, A5, M6, M7 }

///|
/// Embedded source of `prelude/synths_basic.rela`.
pub const SYNTHS_BASIC : String =
  #|; ===========================================
  #|; Basic Synth Presets - 8-bit & Classic
  #|; ===========================================
  #|
  #|; 8-bit / Chiptune
  #|synth Chiptune = {
  #|  osc: Square,
  #|  env: envelope 0.01 0.1 0.8 0.1
  #|}
  #|
  #|synth Chip8bit = {
  #|  osc: Square,
  #|  env: envelope 0.001 0.05 0.0 0.05
  #|}
  #|
  #|synth NES = {
  #|  osc: Square,
  #|  env: envelope 0.01 0.1 0.7 0.15,
  #|  filter: LowPass 4000 0.2
  #|}
  #|
  #|synth GameBoy = {
  #|  osc: Pulse 0.125,
  #|  env: envelope 0.01 0.15 0.5 0.1
  #|}
  #|
  #|; Classic Synths
  #|synth Lead = {
  #|  osc: Saw,
  #|  env: envelope 0.02 0.15 0.7 0.2,
  #|  filter: LowPass 3000 0.3,
  #|  detune: 5
  #|}
  #|
  #|synth SoftPad = {
  #|  osc: Triangle,
  #|  env: envelope 0.5 0.3 0.8 1.0,
  #|  filter: LowPass 2000 0.2
  #|}
  #|
  #|synth FatBass = {
  #|  osc: Saw,
  #|  env: envelope 0.05 0.2 0.6 0.3,
  #|  filter: LowPass 200 0.4
  #|}
  #|
  #|synth Pluck = {
  #|  osc: Saw,
  #|  env: envelope 0.001 0.3 0.0 0.1,
  #|  filter: LowPass 1500 0.5
  #|}
  #|
  #|synth Strings = {
  #|  osc: Saw,
  #|  env: envelope 0.3 0.2 0.8 0.5,
  #|  filter: LowPass 4000 0.1,
  #|  detune: 5
  #|}
  #|
  #|synth Organ = {
  #|  osc: Sine,
  #|  env: envelope 0.01 0.0 1.0 0.1
  #|}
  #|
  #|; Basic Drums
  #|synth Kick = {
  #|  osc: Triangle,
  #|  env: envelope 0.001 0.12 0.0 0.08
  #|}
  #|
  #|synth Snare = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.08 0.0 0.1,
  #|  filter: BandPass 2500 0.6
  #|}
  #|
  #|synth HiHat = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.03 0.0 0.02,
  #|  filter: HighPass 6000 0.5
  #|}
  #|
  #|synth OpenHat = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.15 0.1 0.2,
  #|  filter: HighPass 5000 0.4
  #|}
  #|
  #|synth Tom = {
  #|  osc: Triangle,
  #|  env: envelope 0.001 0.15 0.0 0.1
  #|}
  #|
  #|synth Clap = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.06 0.0 0.12,
  #|  filter: BandPass 2000 0.7
  #|}
  #|
  #|; 8-bit Drums
  #|synth Kick8bit = {
  #|  osc: Square,
  #|  env: envelope 0.005 0.15 0.0 0.1
  #|}
  #|
  #|synth Snare8bit = {
  #|  osc: Noise,
  #|  env: envelope 0.005 0.1 0.0 0.15
  #|}
  #|
  #|synth HiHat8bit = {
  #|  osc: Noise,
  #|  env: envelope 0.005 0.05 0.0 0.05
  #|}

///|
/// Embedded source of `prelude/synths_bass.rela`.
pub const SYNTHS_BASS : String =
  #|; ===========================================
  #|; Bass Instrument Presets
  #|; ===========================================
  #|
  #|synth WoodBass = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.3) + (Saw |> mix 0.2 |> octave (-1)),
  #|  env: envelope 0.02 0.3 0.6 0.4,
  #|  filter: LowPass 800 0.3
  #|}
  #|
  #|synth ElectricBass = {
  #|  osc: (Saw |> mix 0.4) + (Sine |> mix 0.4) + (Triangle |> mix 0.2),
  #|  env: envelope 0.01 0.25 0.5 0.35,
  #|  filter: LowPass 1200 0.35
  #|}
  #|
  #|synth SynthBass = {
  #|  osc: (Saw |> mix 0.5) + (Square |> mix 0.3) + (Sine |> mix 0.2 |> octave (-1)),
  #|  env: envelope 0.01 0.2 0.7 0.3,
  #|  filter: LowPass 400 0.5,
  #|  detune: 8
  #|}
  #|
  #|synth SubBass = {
  #|  osc: (Sine |> mix 0.7) + (Sine |> mix 0.3 |> octave (-1)),
  #|  env: envelope 0.02 0.1 0.9 0.2,
  #|  filter: LowPass 200 0.2
  #|}
  #|
  #|synth AcidBass = {
  #|  osc: (Saw |> mix 0.6) + (Square |> mix 0.4),
  #|  env: envelope 0.005 0.15 0.4 0.2,
  #|  filter: LowPass 600 0.8
  #|}
  #|
  #|synth ReeseBass = {
  #|  osc: (Saw |> mix 0.35 |> osc_detune (-20)) + (Saw |> mix 0.35) + (Saw |> mix 0.3 |> osc_detune 20),
  #|  env: envelope 0.005 0.1 0.85 0.25,
  #|  filter: LowPass 800 0.5,
  #|  detune: 15
  #|}

///|
/// Embedded source of `prelude/synths_brass.rela`.
pub const SYNTHS_BRASS : String =
  #|; ===========================================
  #|; Brass Instrument Presets
  #|; ===========================================
  #|
  #|synth Trumpet = {
  #|  osc: (Saw |> mix 0.4) + (Square |> mix 0.3) + (Sine |> mix 0.3),
  #|  env: envelope 0.08 0.15 0.8 0.2,
  #|  filter: LowPass 4000 0.4,
  #|  detune: 3
  #|}
  #|
  #|synth MutedTrumpet = {
  #|  osc: (Saw |> mix 0.4) + (Triangle |> mix 0.4) + (Sine |> mix 0.2),
  #|  env: envelope 0.1 0.2 0.7 0.25,
  #|  filter: BandPass 1500 0.5,
  #|  detune: 2
  #|}
  #|
  #|synth Trombone = {
  #|  osc: (Saw |> mix 0.4) + (Triangle |> mix 0.4) + (Sine |> mix 0.2 |> octave (-1)),
  #|  env: envelope 0.06 0.2 0.7 0.3,
  #|  filter: LowPass 2000 0.4,
  #|  detune: 4
  #|}
  #|
  #|synth FrenchHorn = {
  #|  osc: (Sine |> mix 0.4) + (Triangle |> mix 0.35) + (Saw |> mix 0.25),
  #|  env: envelope 0.1 0.25 0.75 0.35,
  #|  filter: LowPass 2500 0.3,
  #|  detune: 3
  #|}
  #|
  #|synth Brass = {
  #|  osc: (Saw |> mix 0.5) + (Square |> mix 0.3) + (Triangle |> mix 0.2),
  #|  env: envelope 0.05 0.2 0.75 0.25,
  #|  filter: LowPass 3500 0.5,
  #|  detune: 5
  #|}
  #|
  #|synth BrassSection = {
  #|  osc: (Saw |> mix 0.35 |> osc_detune (-8)) + (Saw |> mix 0.35 |> osc_detune 8) + (Square |> mix 0.3),
  #|  env: envelope 0.06 0.2 0.8 0.3,
  #|  filter: LowPass 3000 0.4,
  #|  detune: 6
  #|}

///|
/// Embedded source of `prelude/synths_clap.rela`.
pub const SYNTHS_CLAP : String =
  #|; ===========================================
  #|; Clap & Hand Percussion Presets
  #|; ===========================================
  #|
  #|; Basic hand clap
  #|synth HandClap = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.02 0.0 0.15,
  #|  filter: BandPass 1800 0.7
  #|}
  #|
  #|; Tight snappy clap
  #|synth TightClap = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.015 0.0 0.1,
  #|  filter: BandPass 2500 0.75
  #|}
  #|
  #|; Room clap with ambience
  #|synth RoomClap = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.04 0.05 0.25,
  #|  filter: BandPass 1600 0.5
  #|}
  #|
  #|; 808-style clap
  #|synth Clap808 = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.025 0.0 0.18,
  #|  filter: BandPass 2200 0.65
  #|}
  #|
  #|; 909-style clap
  #|synth Clap909 = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.03 0.02 0.12,
  #|  filter: BandPass 1900 0.7
  #|}
  #|
  #|; Vintage analog clap
  #|synth VintageClap = {
  #|  osc: Noise,
  #|  env: envelope 0.002 0.035 0.0 0.2,
  #|  filter: BandPass 1500 0.6
  #|}
  #|
  #|; Sharp attack clap
  #|synth SharpClap = {
  #|  osc: Noise,
  #|  env: envelope 0.0005 0.01 0.0 0.08,
  #|  filter: BandPass 3000 0.8
  #|}
  #|
  #|; Soft clap
  #|synth SoftClap = {
  #|  osc: Noise,
  #|  env: envelope 0.005 0.05 0.05 0.3,
  #|  filter: BandPass 1400 0.45
  #|}
  #|
  #|; Stadium clap - big reverberant
  #|synth StadiumClap = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.06 0.1 0.4,
  #|  filter: BandPass 1700 0.55
  #|}
  #|
  #|; Finger snap
  #|synth FingerSnap = {
  #|  osc: Noise,
  #|  env: envelope 0.0005 0.008 0.0 0.05,
  #|  filter: BandPass 4000 0.85
  #|}

///|
/// Embedded source of `prelude/synths_drums.rela`.
pub const SYNTHS_DRUMS : String =
  #|; ===========================================
  #|; Drum Kit Presets (with pitch envelope)
  #|; ===========================================
  #|
  #|; -------------------------------------------
  #|; Kick Drums
  #|; -------------------------------------------
  #|synth DeepKick = {
  #|  osc: Sine,
  #|  env: envelope 0.001 0.15 0.0 0.1,
  #|  pitch_env: (150, 40, 0.08)
  #|}
  #|
  #|synth PunchyKick = {
  #|  osc: (Sine |> mix 0.7) + (Triangle |> mix 0.3),
  #|  env: envelope 0.001 0.12 0.0 0.08,
  #|  pitch_env: (200, 50, 0.05)
  #|}
  #|
  #|synth SubKick = {
  #|  osc: Sine,
  #|  env: envelope 0.002 0.2 0.0 0.15,
  #|  pitch_env: (100, 30, 0.1)
  #|}
  #|
  #|synth HardKick = {
  #|  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.4),
  #|  env: envelope 0.001 0.1 0.0 0.06,
  #|  pitch_env: (250, 60, 0.04)
  #|}
  #|
  #|synth SoftKick = {
  #|  osc: (Sine |> mix 0.8) + (Triangle |> mix 0.2),
  #|  env: envelope 0.003 0.18 0.0 0.12,
  #|  pitch_env: (120, 35, 0.1)
  #|}
  #|
  #|; -------------------------------------------
  #|; Snare Drums
  #|; -------------------------------------------
  #|synth TightSnare = {
  #|  osc: (Noise |> mix 0.6) + (Triangle |> mix 0.4),
  #|  env: envelope 0.001 0.1 0.0 0.12,
  #|  filter: BandPass 2000 0.5
  #|}
  #|
  #|synth FatSnare = {
  #|  osc: (Noise |> mix 0.5) + (Triangle |> mix 0.3) + (Sine |> mix 0.2),
  #|  env: envelope 0.001 0.15 0.0 0.18,
  #|  filter: BandPass 1800 0.6,
  #|  pitch_env: (300, 150, 0.02)
  #|}
  #|
  #|synth CrispSnare = {
  #|  osc: (Noise |> mix 0.7) + (Triangle |> mix 0.3),
  #|  env: envelope 0.001 0.08 0.0 0.1,
  #|  filter: BandPass 2500 0.55
  #|}
  #|
  #|synth RimShot = {
  #|  osc: (Noise |> mix 0.4) + (Square |> mix 0.6),
  #|  env: envelope 0.001 0.05 0.0 0.08,
  #|  filter: HighPass 3000 0.5
  #|}
  #|
  #|synth SideStick = {
  #|  osc: (Noise |> mix 0.3) + (Triangle |> mix 0.7),
  #|  env: envelope 0.001 0.04 0.0 0.06,
  #|  filter: BandPass 3000 0.6
  #|}
  #|
  #|; -------------------------------------------
  #|; Hi-Hats
  #|; -------------------------------------------
  #|synth ClosedHat = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.04 0.0 0.03,
  #|  filter: HighPass 8000 0.6
  #|}
  #|
  #|synth OpenHiHat = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.2 0.1 0.25,
  #|  filter: HighPass 6000 0.5
  #|}
  #|
  #|synth PedalHat = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.08 0.0 0.1,
  #|  filter: HighPass 7000 0.4
  #|}
  #|
  #|synth TightHat = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.025 0.0 0.02,
  #|  filter: HighPass 9000 0.65
  #|}
  #|
  #|; -------------------------------------------
  #|; Toms
  #|; -------------------------------------------
  #|synth HighTom = {
  #|  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.4),
  #|  env: envelope 0.001 0.2 0.0 0.15,
  #|  pitch_env: (400, 200, 0.06)
  #|}
  #|
  #|synth MidTom = {
  #|  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.4),
  #|  env: envelope 0.001 0.25 0.0 0.18,
  #|  pitch_env: (300, 120, 0.08)
  #|}
  #|
  #|synth FloorTom = {
  #|  osc: (Sine |> mix 0.7) + (Triangle |> mix 0.3),
  #|  env: envelope 0.001 0.3 0.0 0.2,
  #|  pitch_env: (200, 80, 0.1)
  #|}
  #|
  #|synth LowTom = {
  #|  osc: (Sine |> mix 0.75) + (Triangle |> mix 0.25),
  #|  env: envelope 0.001 0.35 0.0 0.22,
  #|  pitch_env: (150, 60, 0.12)
  #|}
  #|
  #|; -------------------------------------------
  #|; Cymbals
  #|; -------------------------------------------
  #|synth CrashCymbal = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.4 0.2 1.5,
  #|  filter: HighPass 4000 0.3
  #|}
  #|
  #|synth RideCymbal = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.3 0.15 0.8,
  #|  filter: HighPass 5000 0.4
  #|}
  #|
  #|synth RideBell = {
  #|  osc: (Noise |> mix 0.3) + (Sine |> mix 0.7),
  #|  env: envelope 0.001 0.2 0.1 0.6,
  #|  filter: BandPass 4000 0.5
  #|}
  #|
  #|synth SplashCymbal = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.25 0.1 0.5,
  #|  filter: HighPass 6000 0.35
  #|}
  #|
  #|synth ChinaCymbal = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.35 0.15 1.0,
  #|  filter: BandPass 5000 0.4
  #|}

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

///|
/// Embedded source of `prelude/synths_leads.rela`.
pub const SYNTHS_LEADS : String =
  #|; ===========================================
  #|; Synth Lead Presets
  #|; ===========================================
  #|
  #|synth SuperSaw = {
  #|  osc: Saw,
  #|  env: envelope 0.01 0.2 0.8 0.3,
  #|  filter: LowPass 6000 0.3,
  #|  detune: 15
  #|}
  #|
  #|synth HyperSaw = {
  #|  osc: (Saw |> mix 0.25 |> osc_detune (-20)) + (Saw |> mix 0.25 |> osc_detune (-7)) + (Saw |> mix 0.25 |> osc_detune 7) + (Saw |> mix 0.25 |> osc_detune 20),
  #|  env: envelope 0.02 0.15 0.85 0.25,
  #|  filter: LowPass 5000 0.35,
  #|  detune: 10
  #|}
  #|
  #|synth SquareLead = {
  #|  osc: (Square |> mix 0.5) + (Pulse 0.25 |> mix 0.3) + (Sine |> mix 0.2 |> octave 1),
  #|  env: envelope 0.01 0.15 0.75 0.2,
  #|  filter: LowPass 4000 0.4
  #|}
  #|
  #|synth ResoLead = {
  #|  osc: (Saw |> mix 0.6) + (Square |> mix 0.4),
  #|  env: envelope 0.005 0.1 0.6 0.15,
  #|  filter: LowPass 2000 0.8
  #|}
  #|
  #|synth SoftLead = {
  #|  osc: (Triangle |> mix 0.5) + (Sine |> mix 0.3) + (Saw |> mix 0.2),
  #|  env: envelope 0.03 0.2 0.7 0.25,
  #|  filter: LowPass 3000 0.25
  #|}
  #|
  #|synth OctaveLead = {
  #|  osc: (Saw |> mix 0.4) + (Saw |> mix 0.35 |> octave 1) + (Square |> mix 0.25),
  #|  env: envelope 0.01 0.15 0.7 0.2,
  #|  filter: LowPass 4500 0.35,
  #|  detune: 5
  #|}

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

///|
/// Embedded source of `prelude/synths_pads.rela`.
pub const SYNTHS_PADS : String =
  #|; ===========================================
  #|; Synth Pad Presets
  #|; ===========================================
  #|
  #|synth WarmPad = {
  #|  osc: (Saw |> mix 0.3) + (Triangle |> mix 0.4) + (Sine |> mix 0.3 |> octave (-1)),
  #|  env: envelope 0.8 0.5 0.7 1.5,
  #|  filter: LowPass 2500 0.2,
  #|  detune: 10
  #|}
  #|
  #|synth StringPad = {
  #|  osc: (Saw |> mix 0.4 |> osc_detune (-7)) + (Saw |> mix 0.4 |> osc_detune 7) + (Triangle |> mix 0.2),
  #|  env: envelope 0.6 0.4 0.8 1.2,
  #|  filter: LowPass 4000 0.15,
  #|  detune: 5
  #|}
  #|
  #|synth ChoirPad = {
  #|  osc: (Sine |> mix 0.4) + (Triangle |> mix 0.3) + (Sine |> mix 0.3 |> octave 1),
  #|  env: envelope 0.7 0.3 0.75 1.0,
  #|  filter: BandPass 1500 0.3
  #|}
  #|
  #|synth GlassPad = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.3 |> octave 1) + (Sine |> mix 0.2 |> octave 2),
  #|  env: envelope 0.5 0.4 0.6 1.3,
  #|  filter: LowPass 5000 0.2
  #|}
  #|
  #|synth DarkPad = {
  #|  osc: (Saw |> mix 0.4 |> octave (-1)) + (Triangle |> mix 0.35) + (Sine |> mix 0.25),
  #|  env: envelope 1.0 0.5 0.75 1.8,
  #|  filter: LowPass 1500 0.25,
  #|  detune: 8
  #|}
  #|
  #|synth SweepPad = {
  #|  osc: (Saw |> mix 0.45 |> osc_detune (-10)) + (Saw |> mix 0.45 |> osc_detune 10) + (Triangle |> mix 0.1),
  #|  env: envelope 0.9 0.6 0.7 1.4,
  #|  filter: LowPass 3000 0.4,
  #|  detune: 12
  #|}

///|
/// Embedded source of `prelude/synths_percussion.rela`.
pub const SYNTHS_PERCUSSION : String =
  #|; ===========================================
  #|; Percussion Instrument Presets
  #|; ===========================================
  #|
  #|synth HandClap = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.08 0.0 0.15,
  #|  filter: BandPass 1500 0.7
  #|}
  #|
  #|synth Cowbell = {
  #|  osc: (Square |> mix 0.5) + (Sine |> mix 0.5 |> octave 1),
  #|  env: envelope 0.001 0.15 0.0 0.1,
  #|  filter: BandPass 800 0.6
  #|}
  #|
  #|synth Shaker = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.06 0.0 0.04,
  #|  filter: HighPass 6000 0.3
  #|}
  #|
  #|synth Tambourine = {
  #|  osc: Noise,
  #|  env: envelope 0.001 0.1 0.05 0.15,
  #|  filter: HighPass 5000 0.4
  #|}
  #|
  #|synth Conga = {
  #|  osc: (Sine |> mix 0.7) + (Triangle |> mix 0.3),
  #|  env: envelope 0.001 0.2 0.0 0.15,
  #|  pitch_env: (350, 180, 0.05)
  #|}
  #|
  #|synth Bongo = {
  #|  osc: (Sine |> mix 0.65) + (Triangle |> mix 0.35),
  #|  env: envelope 0.001 0.15 0.0 0.1,
  #|  pitch_env: (500, 280, 0.04)
  #|}
  #|
  #|synth Timbale = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.3) + (Noise |> mix 0.2),
  #|  env: envelope 0.001 0.12 0.0 0.1,
  #|  filter: BandPass 2000 0.5,
  #|  pitch_env: (600, 400, 0.03)
  #|}
  #|
  #|synth WoodBlock = {
  #|  osc: (Triangle |> mix 0.6) + (Sine |> mix 0.4 |> octave 1),
  #|  env: envelope 0.001 0.08 0.0 0.06,
  #|  filter: BandPass 1500 0.4
  #|}
  #|
  #|synth Claves = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.5 |> octave 1),
  #|  env: envelope 0.001 0.05 0.0 0.04,
  #|  filter: HighPass 2000 0.3
  #|}

///|
/// Embedded source of `prelude/synths_piano.rela`.
pub const SYNTHS_PIANO : String =
  #|; ===========================================
  #|; Piano & Electric Piano Presets
  #|; ===========================================
  #|
  #|; Acoustic Piano
  #|synth AcousticPiano = {
  #|  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.25 |> octave 1) + (Sine |> mix 0.15 |> octave 2),
  #|  env: envelope 0.005 0.4 0.3 0.8,
  #|  filter: LowPass 5000 0.2
  #|}
  #|
  #|synth BrightPiano = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.3 |> octave 1) + (Saw |> mix 0.2 |> octave 2),
  #|  env: envelope 0.003 0.35 0.35 0.7,
  #|  filter: LowPass 6000 0.25
  #|}
  #|
  #|synth MellowPiano = {
  #|  osc: (Sine |> mix 0.7) + (Triangle |> mix 0.2) + (Sine |> mix 0.1 |> octave 1),
  #|  env: envelope 0.008 0.5 0.25 0.9,
  #|  filter: LowPass 3000 0.15
  #|}
  #|
  #|; Electric Piano
  #|synth Rhodes = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.3 |> octave 1) + (Sine |> mix 0.2 |> octave 2 |> osc_detune 3),
  #|  env: envelope 0.002 0.8 0.4 0.5,
  #|  filter: LowPass 3000 0.3
  #|}
  #|
  #|synth Wurlitzer = {
  #|  osc: (Square |> mix 0.4) + (Sine |> mix 0.4) + (Triangle |> mix 0.2 |> octave 1),
  #|  env: envelope 0.003 0.5 0.35 0.4,
  #|  filter: LowPass 2500 0.4,
  #|  detune: 2
  #|}
  #|
  #|synth DXPiano = {
  #|  osc: (Sine |> mix 0.4) + (Sine |> mix 0.35 |> octave 1 |> osc_detune 5) + (Sine |> mix 0.25 |> octave 2),
  #|  env: envelope 0.001 0.6 0.3 0.45,
  #|  filter: LowPass 4500 0.2
  #|}
  #|
  #|synth Clavinet = {
  #|  osc: (Saw |> mix 0.5) + (Square |> mix 0.3) + (Pulse 0.25 |> mix 0.2),
  #|  env: envelope 0.001 0.2 0.0 0.1,
  #|  filter: BandPass 2000 0.6
  #|}

///|
/// Embedded source of `prelude/synths_pluck.rela`.
pub const SYNTHS_PLUCK : String =
  #|; ===========================================
  #|; Pluck & Percussive Synth Presets
  #|; ===========================================
  #|
  #|synth PluckBass = {
  #|  osc: (Saw |> mix 0.5) + (Square |> mix 0.3) + (Sine |> mix 0.2),
  #|  env: envelope 0.002 0.4 0.0 0.15,
  #|  filter: LowPass 1200 0.6
  #|}
  #|
  #|synth PluckLead = {
  #|  osc: (Saw |> mix 0.4) + (Square |> mix 0.35) + (Saw |> mix 0.25 |> octave 1),
  #|  env: envelope 0.001 0.3 0.0 0.15,
  #|  filter: LowPass 5000 0.4,
  #|  detune: 8
  #|}
  #|
  #|synth Marimba = {
  #|  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.3) + (Sine |> mix 0.1 |> octave 2),
  #|  env: envelope 0.001 0.5 0.0 0.3,
  #|  filter: LowPass 3000 0.2
  #|}
  #|
  #|synth Vibraphone = {
  #|  osc: (Sine |> mix 0.5) + (Sine |> mix 0.3 |> octave 1) + (Triangle |> mix 0.2),
  #|  env: envelope 0.001 0.6 0.2 0.8,
  #|  filter: LowPass 4000 0.15
  #|}
  #|
  #|synth Xylophone = {
  #|  osc: (Sine |> mix 0.5) + (Triangle |> mix 0.3 |> octave 1) + (Sine |> mix 0.2 |> octave 2),
  #|  env: envelope 0.001 0.3 0.0 0.2,
  #|  filter: LowPass 5000 0.2
  #|}
  #|
  #|synth Kalimba = {
  #|  osc: (Sine |> mix 0.6) + (Triangle |> mix 0.25) + (Sine |> mix 0.15 |> octave 1),
  #|  env: envelope 0.001 0.4 0.1 0.5,
  #|  filter: LowPass 3500 0.2
  #|}
  #|
  #|synth Harp = {
  #|  osc: (Triangle |> mix 0.5) + (Sine |> mix 0.35) + (Saw |> mix 0.15),
  #|  env: envelope 0.003 0.6 0.1 0.8,
  #|  filter: LowPass 4000 0.25
  #|}

///|
/// Embedded source of `prelude/synths_retro.rela`.
pub const SYNTHS_RETRO : String =
  #|; ===========================================
  #|; Retro / Lo-Fi Sound Presets
  #|; ===========================================
  #|
  #|synth LoFiPiano = {
  #|  osc: (Triangle |> mix 0.5) + (Square |> mix 0.3) + (Sine |> mix 0.2),
  #|  env: envelope 0.01 0.3 0.4 0.5,
  #|  filter: LowPass 2000 0.2
  #|}
  #|
  #|synth VintageOrgan = {
  #|  osc: (Sine |> mix 0.4) + (Sine |> mix 0.3 |> octave 1) + (Sine |> mix 0.2 |> octave 2) + (Sine |> mix 0.1 |> octave (-1)),
  #|  env: envelope 0.01 0.0 1.0 0.15
  #|}
  #|
  #|synth RetroSynth = {
  #|  osc: (Pulse 0.25 |> mix 0.5) + (Saw |> mix 0.3) + (Square |> mix 0.2),
  #|  env: envelope 0.02 0.15 0.7 0.2,
  #|  filter: LowPass 3000 0.5,
  #|  detune: 6
  #|}
  #|
  #|synth TapeBass = {
  #|  osc: (Saw |> mix 0.5) + (Sine |> mix 0.35) + (Triangle |> mix 0.15),
  #|  env: envelope 0.015 0.2 0.55 0.3,
  #|  filter: LowPass 1000 0.3,
  #|  detune: 4
  #|}
  #|
  #|synth VHSPad = {
  #|  osc: (Saw |> mix 0.35 |> osc_detune (-15)) + (Triangle |> mix 0.35) + (Saw |> mix 0.3 |> osc_detune 15),
  #|  env: envelope 0.6 0.4 0.65 1.0,
  #|  filter: LowPass 2200 0.25,
  #|  detune: 12
  #|}

///|
/// Embedded source of `prelude/synths_wavetable.rela`.
pub const SYNTHS_WAVETABLE : String =
  #|; ===========================================
  #|; Wavetable synth presets
  #|; ===========================================
  #|;
  #|; A wavetable is a sequence of single-cycle waves the oscillator scans
  #|; through. `wave_pos` is the static index into the table (0.0 → 1.0);
  #|; modulate it with an LFO or envelope for movement. The wavetable
  #|; names below are conceptual presets — the evaluator picks the actual
  #|; sample bank.
  #|
  #|; Classic vapor lead — bright at high wave_pos, mellow at low.
  #|synth WaveVapor = {
  #|  osc: Wavetable(table: "vapor"),
  #|  wave_pos: 0.5,
  #|  env: { A: 0.04, D: 0.25, S: 0.7, R: 0.3 },
  #|  filter: LowPass(2800, 0.3)
  #|}
  #|
  #|; Slow-evolving pad — wave_pos slowly drifts via LFO.
  #|synth WaveDriftPad = {
  #|  osc: Wavetable(table: "drift"),
  #|  wave_pos: 0.3,
  #|  env: { A: 1.5, D: 0.5, S: 1.0, R: 2.5 },
  #|  filter: LowPass(3500, 0.2),
  #|  mod: [ lfo(target: wave_pos, rate: 0.12, depth: 0.7, shape: Sine) ]
  #|}
  #|
  #|; Talking / formant wavetable.
  #|synth WaveFormant = {
  #|  osc: Wavetable(table: "vowels"),
  #|  wave_pos: 0.4,
  #|  env: { A: 0.02, D: 0.4, S: 0.6, R: 0.6 },
  #|  filter: BandPass(1800, 0.7),
  #|  mod: [ lfo(target: wave_pos, rate: 4.0, depth: 0.2, shape: Triangle) ]
  #|}
  #|
  #|; Bell-meets-pad — long sustain, swept brightness.
  #|synth WaveBellPad = {
  #|  osc: Wavetable(table: "metallic"),
  #|  wave_pos: 0.6,
  #|  env: { A: 0.05, D: 0.8, S: 0.9, R: 2.0 },
  #|  filter: LowPass(5500, 0.25),
  #|  mod: [ env(target: filter.cutoff, attack: 1.2, depth: 3500) ]
  #|}
  #|
  #|; Acid lead — single cycle scanning fast for that resonant-square vibe.
  #|synth WaveAcid = {
  #|  osc: Wavetable(table: "acid"),
  #|  wave_pos: 0.5,
  #|  env: { A: 0.001, D: 0.15, S: 0.3, R: 0.2 },
  #|  filter: LowPass(1800, 0.9),
  #|  mod: [ env(target: filter.cutoff, attack: 0.0, depth: 4000) ]
  #|}
  #|
  #|; Wide unison wavetable — seven detuned voices, ultra-thick.
  #|synth WaveSupersaw = {
  #|  osc: Wavetable(table: "supersaw", voices: 7),
  #|  detune: 22,
  #|  wave_pos: 0.5,
  #|  env: { A: 0.02, D: 0.2, S: 0.7, R: 0.5 },
  #|  filter: LowPass(6000, 0.25)
  #|}

///|
/// Embedded source of `prelude/tunings.rela`.
pub const TUNINGS : String =
  #|; ===========================================
  #|; Tuning presets
  #|; ===========================================
  #|;
  #|; A tuning describes how a *step* in the scale maps to a frequency
  #|; ratio (or cents offset from 12-EDO). Activate one with
  #|;
  #|;   set tuning = JustIntonation
  #|;
  #|; and every scale-degree reference resolves against it. The default
  #|; tuning is 12-EDO.
  #|
  #|; 24-tone equal temperament (quarter-tone steps). Standard for a lot
  #|; of Middle Eastern and contemporary microtonal work.
  #|tuning EDO24 = equal { steps: 24 }
  #|
  #|; 31-tone equal temperament — Fokker's tuning, good meantone
  #|; approximation with usable septimal ratios.
  #|tuning EDO31 = equal { steps: 31 }
  #|
  #|; 53-tone equal temperament — near-pure Pythagorean.
  #|tuning EDO53 = equal { steps: 53 }
  #|
  #|; 5-limit Just Intonation in C major.
  #|; Ratios are written `numerator/denominator`.
  #|tuning JustIntonation = ratios [
  #|  1/1,   ; root
  #|  9/8,   ; major 2nd
  #|  5/4,   ; major 3rd
  #|  4/3,   ; perfect 4th
  #|  3/2,   ; perfect 5th
  #|  5/3,   ; major 6th
  #|  15/8   ; major 7th
  #|]
  #|
  #|; Pythagorean tuning — every interval is a stack of perfect fifths.
  #|tuning Pythagorean = ratios [
  #|  1/1,
  #|  9/8,
  #|  81/64,
  #|  4/3,
  #|  3/2,
  #|  27/16,
  #|  243/128
  #|]
  #|
  #|; Werckmeister III — Bach-era well temperament. Cents offsets from
  #|; 12-EDO for each chromatic step.
  #|tuning WerckmeisterIII = cents [
  #|   0.0,   ;  C
  #|  -3.91,  ;  C#
  #|  -7.82,  ;  D
  #|  -5.86,  ;  D#
  #|  -9.77,  ;  E
  #|  -1.96,  ;  F
  #|  -5.86,  ;  F#
  #|  -3.91,  ;  G
  #|  -5.86,  ;  G#
  #|  -7.82,  ;  A
  #|  -3.91,  ;  A#
  #|  -7.82   ;  B
  #|]
  #|
  #|; Bohlen-Pierce — equal division of a 3:1 "tritave" into 13 steps.
  #|tuning BohlenPierce = ratios_per_period {
  #|  period: 3/1,
  #|  steps: 13
  #|}

