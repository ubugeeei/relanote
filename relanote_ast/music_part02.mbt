///|
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
  base : @core.Spanned[Expr]?
  intervals : Array[@core.Spanned[IntervalLit]]
}

///|
pub fn ScaleDef::new(
  name : Ident,
  base : @core.Spanned[Expr]?,
  intervals : Array[@core.Spanned[IntervalLit]],
) -> ScaleDef {
  { name, base, intervals }
}

///|
pub fn ScaleDef::name(self : ScaleDef) -> Ident {
  self.name
}

///|
pub fn ScaleDef::base(self : ScaleDef) -> @core.Spanned[Expr]? {
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
/// their builtin/keyword-adjacent legacy forms only where necessary.
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
  body : @core.Spanned[Expr]?
}

///|
pub fn PartExpr::new(
  instrument : @core.Spanned[Expr],
  body : @core.Spanned[Expr]?,
) -> PartExpr {
  { instrument, body }
}

///|
pub fn PartExpr::instrument(self : PartExpr) -> @core.Spanned[Expr] {
  self.instrument
}

///|
pub fn PartExpr::body(self : PartExpr) -> @core.Spanned[Expr]? {
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
