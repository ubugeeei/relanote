///|
/// Interval quality prefix — Major / Minor / Perfect / Diminished /
/// Augmented.
pub(all) enum IntervalQuality {
  Major
  Minor
  Perfect
  Diminished
  Augmented
} derive(Eq)

///|
/// Accidental modifier attached to an interval or pitch.
pub(all) enum Accidental {
  Sharp // +
  Flat // -
} derive(Eq)

///|
/// Parsed interval payload (e.g. `M3`, `P5+`, `m7-`, `A4++`).
pub struct IntervalData {
  quality : IntervalQuality
  degree : Int
  accidentals : Array[Accidental]
} derive(Eq)

///|
pub fn IntervalData::new(
  quality : IntervalQuality,
  degree : Int,
  accidentals : Array[Accidental],
) -> IntervalData {
  { quality, degree, accidentals }
}

///|
pub fn IntervalData::quality(self : IntervalData) -> IntervalQuality {
  self.quality
}

///|
pub fn IntervalData::degree(self : IntervalData) -> Int {
  self.degree
}

///|
pub fn IntervalData::accidentals(self : IntervalData) -> Array[Accidental] {
  self.accidentals
}

///|
/// Absolute pitch payload (e.g. `C4`, `D#3`, `Bb5`).
///
/// `accidental` is -1 (flat), 0 (natural) or +1 (sharp), matching the legacy
/// representation byte-for-byte.
pub struct AbsolutePitchData {
  note : Char
  accidental : Int
  octave : Int
} derive(Eq)

///|
pub fn AbsolutePitchData::new(
  note : Char,
  accidental : Int,
  octave : Int,
) -> AbsolutePitchData {
  { note, accidental, octave }
}

///|
pub fn AbsolutePitchData::note(self : AbsolutePitchData) -> Char {
  self.note
}

///|
pub fn AbsolutePitchData::accidental(self : AbsolutePitchData) -> Int {
  self.accidental
}

///|
pub fn AbsolutePitchData::octave(self : AbsolutePitchData) -> Int {
  self.octave
}

///|
/// Convert this absolute pitch to a MIDI note number (`C4 == 60`).
pub fn AbsolutePitchData::to_midi_note(self : AbsolutePitchData) -> Int {
  let base = match self.note {
    'C' => 0
    'D' => 2
    'E' => 4
    'F' => 5
    'G' => 7
    'A' => 9
    'B' => 11
    _ => 0
  }
  let midi = 12 * (self.octave + 1) + base + self.accidental
  if midi < 0 {
    0
  } else if midi > 127 {
    127
  } else {
    midi
  }
}

///|
/// All token kinds produced by the lexer. Variant names mirror the legacy
/// `TokenKind` enum, except that:
///
/// * `Eq` (the `=` sign) is renamed to `Equals` to avoid shadowing the `Eq`
///   trait when pattern matching.
/// * `String` becomes `StringLit` to avoid shadowing the builtin string
///   type.
pub(all) enum TokenKind {
  // Keywords
  Let
  Set
  In
  If
  Then
  Else
  Match
  With
  Scale
  Chord
  Section
  Layer
  Part
  Synth
  Osc
  Filter
  Env
  Import
  Export
  From
  As
  Mod
  Use
  True
  False
  Render
  Context
  Key

  // Music primitives
  Root
  Interval(IntervalData)
  AbsolutePitch(AbsolutePitchData)
  Bars
  Beats

  // Articulations
  Staccato
  Accent
  Portamento

  // Delimiters
  Pipe
  LBrace
  RBrace
  LBracket
  RBracket
  LParen
  RParen
  LAngle
  RAngle

  // Operators
  PipeOp
  Compose
  Arrow
  Lambda
  Equals
  EqEq
  NotEq
  LtEq
  GtEq
  AndAnd
  OrOr
  Bang
  ColonColon
  Colon
  Comma
  Dot
  Minus
  PlusPlus
  Plus
  Star
  Slash
  Percent

  // Literals
  Integer(Int)
  Float(Double)
  StringLit(String)

  // Identifiers
  Ident(String)

  // Comments
  LineComment(String)

  // Newline
  Newline

  // End of file
  Eof
} derive(Eq)

///|
/// `true` if `self` is a reserved keyword token.
