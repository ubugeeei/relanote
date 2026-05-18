// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

///|
/// Embedded source of `prelude/chords.rela`.
pub let CHORDS : String =
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
/// Embedded source of `prelude/effects_delay.rela`.
pub let EFFECTS_DELAY : String =
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
pub let EFFECTS_DISTORTION : String =
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
/// Embedded source of `prelude/effects_phaser.rela`.
pub let EFFECTS_PHASER : String =
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
pub let EFFECTS_REVERB : String =
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
/// Embedded source of `prelude/scales.rela`.
pub let SCALES : String =
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
pub let SYNTHS_BASIC : String =
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
pub let SYNTHS_BASS : String =
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
pub let SYNTHS_BRASS : String =
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
pub let SYNTHS_CLAP : String =
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
pub let SYNTHS_DRUMS : String =
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
/// Embedded source of `prelude/synths_leads.rela`.
pub let SYNTHS_LEADS : String =
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
/// Embedded source of `prelude/synths_pads.rela`.
pub let SYNTHS_PADS : String =
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
pub let SYNTHS_PERCUSSION : String =
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
pub let SYNTHS_PIANO : String =
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
pub let SYNTHS_PLUCK : String =
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
pub let SYNTHS_RETRO : String =
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

