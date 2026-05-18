///|
/// Header banner that the Rust crate prepends to the combined `PRELUDE`
/// string.
const PRELUDE_HEADER : String =
  #|; ===========================================
  #|; Relanote Standard Prelude
  #|; Automatically imported into every program
  #|; ===========================================

///|
/// Combined prelude source — every module concatenated with single newline
/// separators, in the same order the Rust crate stitches them together so
/// downstream parsers see byte-identical input.
pub const PRELUDE : String =
  PRELUDE_HEADER +
  "\n\n" +
  SCALES + "\n" +
  CHORDS + "\n" +
  SYNTHS_BASIC + "\n" +
  SYNTHS_PIANO + "\n" +
  SYNTHS_BASS + "\n" +
  SYNTHS_BRASS + "\n" +
  SYNTHS_LEADS + "\n" +
  SYNTHS_PADS + "\n" +
  SYNTHS_PLUCK + "\n" +
  SYNTHS_DRUMS + "\n" +
  SYNTHS_PERCUSSION + "\n" +
  SYNTHS_RETRO + "\n" +
  SYNTHS_CLAP + "\n" +
  EFFECTS_REVERB + "\n" +
  EFFECTS_DELAY + "\n" +
  EFFECTS_PHASER + "\n" +
  EFFECTS_DISTORTION
