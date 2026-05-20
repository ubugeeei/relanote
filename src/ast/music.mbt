///|
/// Dynamic marking — `ppp` through `fff`.
pub(all) enum Dynamic {
  Pianississimo // ppp
  Pianissimo // pp
  Piano // p
  MezzoPiano // mp
  MezzoForte // mf
  Forte // f
  Fortissimo // ff
  Fortississimo // fff
} derive(Eq)

///|
/// Parse a dynamic marking. Mirrors `Dynamic::from_str` in the legacy implementation;
/// invalid input yields `None`.
pub fn Dynamic::from_str(s : String) -> Dynamic? {
  match s {
    "ppp" => Some(Pianississimo)
    "pp" => Some(Pianissimo)
    "p" => Some(Piano)
    "mp" => Some(MezzoPiano)
    "mf" => Some(MezzoForte)
    "f" => Some(Forte)
    "ff" => Some(Fortissimo)
    "fff" => Some(Fortississimo)
    _ => None
  }
}

///|
/// Interval literal, paired with optional accidentals.
pub struct IntervalLit {
  quality : @lexer.IntervalQuality
  degree : Int
  accidentals : Array[@lexer.Accidental]
} derive(Eq)

///|
pub fn IntervalLit::new(
  quality : @lexer.IntervalQuality,
  degree : Int,
) -> IntervalLit {
  { quality, degree, accidentals: [] }
}

///|
pub fn IntervalLit::with_accidentals(
  self : IntervalLit,
  accidentals : Array[@lexer.Accidental],
) -> IntervalLit {
  { quality: self.quality, degree: self.degree, accidentals }
}

///|
pub fn IntervalLit::quality(self : IntervalLit) -> @lexer.IntervalQuality {
  self.quality
}

///|
pub fn IntervalLit::degree(self : IntervalLit) -> Int {
  self.degree
}

///|
pub fn IntervalLit::accidentals(self : IntervalLit) -> Array[@lexer.Accidental] {
  self.accidentals
}

///|
/// Semitone offset from the root, including accidental adjustments.
pub fn IntervalLit::semitones(self : IntervalLit) -> Int {
  let base = match (self.quality, self.degree) {
    // Unison
    (_, 1) => 0
    // Second
    (Major, 2) => 2
    (Minor, 2) => 1
    // Third
    (Major, 3) => 4
    (Minor, 3) => 3
    // Fourth
    (Perfect, 4) => 5
    (Augmented, 4) => 6
    // Fifth
    (Perfect, 5) => 7
    (Diminished, 5) => 6
    // Sixth
    (Major, 6) => 9
    (Minor, 6) => 8
    // Seventh
    (Major, 7) => 11
    (Minor, 7) => 10
    // Octave and beyond — recurse into 1..=7 degree and add 12 per octave.
    (q, n) =>
      if n > 7 {
        let octaves = (n - 1) / 7
        let remainder = (n - 1) % 7 + 1
        IntervalLit::new(q, remainder).semitones() + octaves * 12
      } else {
        0
      }
  }
  let mut acc = 0
  for a in self.accidentals {
    match a {
      Sharp => acc += 1
      Flat => acc -= 1
    }
  }
  base + acc
}

///|
/// Cents offset from the root (100 cents = 1 semitone).
pub fn IntervalLit::cents(self : IntervalLit) -> Double {
  self.semitones().to_double() * 100.0
}

///|
/// Absolute pitch literal (e.g. `C4`, `D#3`, `Bb5`).
pub struct AbsolutePitchLit {
  note : Char
  accidental : Int
  octave : Int
} derive(Eq)

///|
pub fn AbsolutePitchLit::new(
  note : Char,
  accidental : Int,
  octave : Int,
) -> AbsolutePitchLit {
  { note, accidental, octave }
}

///|
/// Build an `AbsolutePitchLit` from the lexer's payload type — replaces
/// the legacy `impl From<AbsolutePitchData> for AbsolutePitchLit`.
pub fn AbsolutePitchLit::from_data(
  data : @lexer.AbsolutePitchData,
) -> AbsolutePitchLit {
  { note: data.note(), accidental: data.accidental(), octave: data.octave() }
}

///|
pub fn AbsolutePitchLit::note(self : AbsolutePitchLit) -> Char {
  self.note
}

///|
pub fn AbsolutePitchLit::accidental(self : AbsolutePitchLit) -> Int {
  self.accidental
}

///|
pub fn AbsolutePitchLit::octave(self : AbsolutePitchLit) -> Int {
  self.octave
}

///|
/// MIDI note number — `C4` is 60.
pub fn AbsolutePitchLit::to_midi_note(self : AbsolutePitchLit) -> Int {
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
/// Articulation marker on a note (or chord).
pub(all) enum Articulation {
  Staccato // *
  Accent // ^
  Portamento // ~
} derive(Eq)

///|
/// A pitch occurring inside a `Block` — can be an interval, a scale-index
/// reference, or the root marker.
pub(all) enum Pitch {
  /// Direct interval (`M3`, `P5`).
  Interval(IntervalLit)
  /// Scale-index reference (`<1>`, `<3>`).
  ScaleIndex(Int)
  /// Scale-index with one or more accidentals (`<4+>`).
  ScaleIndexMod(Int, Array[@lexer.Accidental])
  /// Microtonal pitch — explicit cents offset from C (`+150c` syntax,
  /// or a raw cents literal). Lets every microtonal feature land
  /// without committing to a single tuning system.
  Microtone(Double)
  /// Interval with a cents fine-tuning offset — `M3 +12.5c` lands a
  /// just-major third on top of the conventional major-third interval.
  MicrotonalInterval(IntervalLit, Double)
  /// Scale-index with a cents offset (`<3 +5c>`).
  ScaleIndexCents(Int, Double)
  /// Root reference (`R`).
  Root
}

///|
/// A slot in a `Block`. Slots use named-field enum variants to match the
/// record variant shape one-to-one.
pub(all) enum Slot {
  /// A single note with optional articulations and explicit slot
  /// duration.
  Note(
    pitch~ : @core.Spanned[Pitch],
    articulations~ : Array[Articulation],
    duration~ : Int?
  )
  /// A rest with optional slot duration.
  Rest(duration~ : Int?)
  /// Simultaneous pitches (chord).
  Chord(
    pitches~ : Array[@core.Spanned[Pitch]],
    articulations~ : Array[Articulation],
    duration~ : Int?
  )
  /// Nested tuplet.
  Tuplet(Tuplet)
}

///|
/// Block: `| slot slot slot |` or `| slot slot slot |:n`.
