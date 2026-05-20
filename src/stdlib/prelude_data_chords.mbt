// AUTO-GENERATED from prelude/*.rela by scripts/gen_stdlib.sh.
// To regenerate after editing the .rela sources, run:
//   bash scripts/gen_stdlib.sh
// Manual edits will be lost.

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
