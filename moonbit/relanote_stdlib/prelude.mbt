///|
/// Header banner that the Rust crate prepends to the combined `PRELUDE`
/// string.
const PRELUDE_HEADER : String =
  #|; ===========================================
  #|; Relanote Standard Prelude
  #|; Automatically imported into every program
  #|; ===========================================

///|
/// Combined prelude source — every module concatenated with single
/// newline separators. Ordering matters:
///
/// 1. Theory primitives (tunings, scales, chords, grooves) come first
///    so synth and effect definitions can reference them.
/// 2. Synth presets, bottom-up from the simplest sources.
/// 3. Effects, with insert-style first and mix-stage last.
pub const PRELUDE : String =
  PRELUDE_HEADER +
  "\n\n" +
  // Theory primitives.
  TUNINGS + "\n" +
  SCALES + "\n" +
  CHORDS + "\n" +
  GROOVES + "\n" +
  // Synthesis layer.
  SYNTHS_BASIC + "\n" +
  SYNTHS_FM + "\n" +
  SYNTHS_WAVETABLE + "\n" +
  SYNTHS_GRANULAR + "\n" +
  SYNTHS_MODULAR + "\n" +
  SYNTHS_PIANO + "\n" +
  SYNTHS_KEYS + "\n" +
  SYNTHS_BASS + "\n" +
  BASS_FUNK + "\n" +
  SYNTHS_BRASS + "\n" +
  SYNTHS_LEADS + "\n" +
  SYNTHS_PADS + "\n" +
  PADS_FLOATING + "\n" +
  SYNTHS_PLUCK + "\n" +
  SYNTHS_DRUMS + "\n" +
  DRUMS_LOFI + "\n" +
  SYNTHS_PERCUSSION + "\n" +
  SYNTHS_RETRO + "\n" +
  SYNTHS_CLAP + "\n" +
  // Effects: insert-style first, then mix-stage.
  EFFECTS_REVERB + "\n" +
  EFFECTS_DELAY + "\n" +
  EFFECTS_PHASER + "\n" +
  EFFECTS_DISTORTION + "\n" +
  EFFECTS_DUB + "\n" +
  EFFECTS_MIX
