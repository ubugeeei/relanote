///|
/// Dynamic marking — `ppp` through `fff`.
pub(all) enum Dynamic {
  Pianississimo // ppp
  Pianissimo    // pp
  Piano         // p
  MezzoPiano    // mp
  MezzoForte    // mf
  Forte         // f
  Fortissimo    // ff
  Fortississimo // fff
} derive(Eq)

///|
/// Parse a dynamic marking. Mirrors `Dynamic::from_str` in the Rust crate;
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
pub fn IntervalLit::accidentals(
  self : IntervalLit,
) -> Array[@lexer.Accidental] {
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
/// the Rust `impl From<AbsolutePitchData> for AbsolutePitchLit`.
pub fn AbsolutePitchLit::from_data(
  data : @lexer.AbsolutePitchData,
) -> AbsolutePitchLit {
  {
    note: data.note(),
    accidental: data.accidental(),
    octave: data.octave(),
  }
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
  Staccato   // *
  Accent     // ^
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
/// Rust struct-variant shape one-to-one.
pub(all) enum Slot {
  /// A single note with optional articulations and explicit slot
  /// duration.
  Note(
    pitch~ : @core.Spanned[Pitch],
    articulations~ : Array[Articulation],
    duration~ : Int?,
  )
  /// A rest with optional slot duration.
  Rest(duration~ : Int?)
  /// Simultaneous pitches (chord).
  Chord(
    pitches~ : Array[@core.Spanned[Pitch]],
    articulations~ : Array[Articulation],
    duration~ : Int?,
  )
  /// Nested tuplet.
  Tuplet(Tuplet)
}

///|
/// Block: `| slot slot slot |` or `| slot slot slot |:n`.
pub struct Block {
  slots : Array[@core.Spanned[Slot]]
  beats : Double?
}

///|
pub fn Block::new(slots : Array[@core.Spanned[Slot]]) -> Block {
  { slots, beats: None }
}

///|
pub fn Block::with_beats(
  slots : Array[@core.Spanned[Slot]],
  beats : Double,
) -> Block {
  { slots, beats: Some(beats) }
}

///|
pub fn Block::empty() -> Block {
  { slots: [], beats: None }
}

///|
pub fn Block::slots(self : Block) -> Array[@core.Spanned[Slot]] {
  self.slots
}

///|
pub fn Block::beats(self : Block) -> Double? {
  self.beats
}

///|
pub fn Block::slot_count(self : Block) -> Int {
  self.slots.length()
}

///|
/// Duration in beats; defaults to `1.0` when unspecified.
pub fn Block::duration_beats(self : Block) -> Double {
  match self.beats {
    Some(b) => b
    None => 1.0
  }
}

///|
/// Tuplet: `{ ... }:n`.
pub struct Tuplet {
  contents : Array[@core.Spanned[Slot]]
  target_beats : @core.Spanned[Expr]
}

///|
pub fn Tuplet::new(
  contents : Array[@core.Spanned[Slot]],
  target_beats : @core.Spanned[Expr],
) -> Tuplet {
  { contents, target_beats }
}

///|
pub fn Tuplet::contents(self : Tuplet) -> Array[@core.Spanned[Slot]] {
  self.contents
}

///|
pub fn Tuplet::target_beats(self : Tuplet) -> @core.Spanned[Expr] {
  self.target_beats
}

///|
/// Envelope literal: `env(from, to, duration)`.
pub struct EnvelopeLit {
  from : @core.Spanned[Expr]
  to : @core.Spanned[Expr]
  duration : @core.Spanned[Expr]
}

///|
pub fn EnvelopeLit::new(
  from : @core.Spanned[Expr],
  to : @core.Spanned[Expr],
  duration : @core.Spanned[Expr],
) -> EnvelopeLit {
  { from, to, duration }
}

///|
pub fn EnvelopeLit::from(self : EnvelopeLit) -> @core.Spanned[Expr] {
  self.from
}

///|
pub fn EnvelopeLit::to(self : EnvelopeLit) -> @core.Spanned[Expr] {
  self.to
}

///|
pub fn EnvelopeLit::duration(self : EnvelopeLit) -> @core.Spanned[Expr] {
  self.duration
}

///|
/// Scale definition: `scale Major = { R, M2, ... }`.
pub struct ScaleDef {
  name : Ident
  base : (@core.Spanned[Expr])?
  intervals : Array[@core.Spanned[IntervalLit]]
}

///|
pub fn ScaleDef::new(
  name : Ident,
  base : (@core.Spanned[Expr])?,
  intervals : Array[@core.Spanned[IntervalLit]],
) -> ScaleDef {
  { name, base, intervals }
}

///|
pub fn ScaleDef::name(self : ScaleDef) -> Ident {
  self.name
}

///|
pub fn ScaleDef::base(self : ScaleDef) -> (@core.Spanned[Expr])? {
  self.base
}

///|
pub fn ScaleDef::intervals(
  self : ScaleDef,
) -> Array[@core.Spanned[IntervalLit]] {
  self.intervals
}

///|
/// Chord definition: `chord Tonic7 = [ R, M3, P5, M7 ]`.
pub struct ChordDef {
  name : Ident
  intervals : Array[@core.Spanned[IntervalLit]]
}

///|
pub fn ChordDef::new(
  name : Ident,
  intervals : Array[@core.Spanned[IntervalLit]],
) -> ChordDef {
  { name, intervals }
}

///|
pub fn ChordDef::name(self : ChordDef) -> Ident {
  self.name
}

///|
pub fn ChordDef::intervals(
  self : ChordDef,
) -> Array[@core.Spanned[IntervalLit]] {
  self.intervals
}

///|
/// Synth definition: `synth Lead = { osc: ..., env: { ... }, ... }`.
pub struct SynthDef {
  name : Ident
  properties : Array[@core.Spanned[SynthProperty]]
}

///|
pub fn SynthDef::new(
  name : Ident,
  properties : Array[@core.Spanned[SynthProperty]],
) -> SynthDef {
  { name, properties }
}

///|
pub fn SynthDef::name(self : SynthDef) -> Ident {
  self.name
}

///|
pub fn SynthDef::properties(
  self : SynthDef,
) -> Array[@core.Spanned[SynthProperty]] {
  self.properties
}

///|
/// One property line inside a `SynthDef`. Variants are renamed away from
/// their builtin/keyword-adjacent Rust forms only where necessary.
pub(all) enum SynthProperty {
  Oscillator(@core.Spanned[Expr])
  Envelope(@core.Spanned[Expr])
  Filter(@core.Spanned[Expr])
  Detune(@core.Spanned[Expr])
  PitchEnvelope(@core.Spanned[Expr])
}

///|
/// Part expression: `part "instrument" { body }`.
pub struct PartExpr {
  instrument : @core.Spanned[Expr]
  body : (@core.Spanned[Expr])?
}

///|
pub fn PartExpr::new(
  instrument : @core.Spanned[Expr],
  body : (@core.Spanned[Expr])?,
) -> PartExpr {
  { instrument, body }
}

///|
pub fn PartExpr::instrument(self : PartExpr) -> @core.Spanned[Expr] {
  self.instrument
}

///|
pub fn PartExpr::body(self : PartExpr) -> (@core.Spanned[Expr])? {
  self.body
}

///|
/// Section expression: `section "name" { ... }`.
pub struct SectionExpr {
  name : @core.Spanned[Expr]
  context : SectionContext?
  body : @core.Spanned[Expr]
}

///|
pub fn SectionExpr::new(
  name : @core.Spanned[Expr],
  context : SectionContext?,
  body : @core.Spanned[Expr],
) -> SectionExpr {
  { name, context, body }
}

///|
pub fn SectionExpr::name(self : SectionExpr) -> @core.Spanned[Expr] {
  self.name
}

///|
pub fn SectionExpr::context(self : SectionExpr) -> SectionContext? {
  self.context
}

///|
pub fn SectionExpr::body(self : SectionExpr) -> @core.Spanned[Expr] {
  self.body
}

///|
/// Section context: `with key:G, scale:Lydian { ... }`.
pub struct SectionContext {
  key : (@core.Spanned[Expr])?
  scale : (@core.Spanned[Expr])?
  tempo : (@core.Spanned[Expr])?
}

///|
pub fn SectionContext::new(
  key : (@core.Spanned[Expr])?,
  scale : (@core.Spanned[Expr])?,
  tempo : (@core.Spanned[Expr])?,
) -> SectionContext {
  { key, scale, tempo }
}

///|
pub fn SectionContext::key(self : SectionContext) -> (@core.Spanned[Expr])? {
  self.key
}

///|
pub fn SectionContext::scale(
  self : SectionContext,
) -> (@core.Spanned[Expr])? {
  self.scale
}

///|
pub fn SectionContext::tempo(
  self : SectionContext,
) -> (@core.Spanned[Expr])? {
  self.tempo
}

///|
/// Layer expression: `layer [ part1, part2, ... ]`.
pub struct LayerExpr {
  parts : Array[@core.Spanned[Expr]]
}

///|
pub fn LayerExpr::new(
  parts : Array[@core.Spanned[Expr]],
) -> LayerExpr {
  { parts, }
}

///|
pub fn LayerExpr::parts(self : LayerExpr) -> Array[@core.Spanned[Expr]] {
  self.parts
}

///|
/// Duration unit — bars or beats — as parsed from `1bar`, `4bars`,
/// `2beats`, etc.
pub(all) enum DurationUnit {
  Bars(Int)
  Beats(Int)
} derive(Eq)

///|
/// Convert to total beats given a time-signature numerator.
pub fn DurationUnit::to_beats(
  self : DurationUnit,
  beats_per_bar : Int,
) -> Double {
  match self {
    Bars(n) => n.to_double() * beats_per_bar.to_double()
    Beats(n) => n.to_double()
  }
}

///|
/// Dynamic literal — a `Dynamic` wrapped so it can carry a span elsewhere.
pub struct DynamicLit {
  dynamic : Dynamic
}

///|
pub fn DynamicLit::new(dynamic : Dynamic) -> DynamicLit {
  { dynamic, }
}

///|
pub fn DynamicLit::dynamic(self : DynamicLit) -> Dynamic {
  self.dynamic
}
