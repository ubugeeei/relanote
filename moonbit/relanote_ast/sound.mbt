// Sound-design AST extensions: tunings, grooves, effects, mix routing.
//
// These declarations sit alongside `scale`, `chord`, `synth` and friends
// in `music.mbt`. They are kept in a separate file because they cluster
// around one concern — describing the *timbre and mix* surface — and
// because the existing AST file is already long.
//
// The parser / evaluator skeletons don't yet recognise these forms; the
// types here pin the shape so future ports can fill in the runtime
// without churning call sites.

///|
/// How a tuning declaration computes its pitch table.
pub(all) enum TuningMode {
  /// `equal { steps: N }` — N-EDO equal temperament across one octave.
  Equal(Int)
  /// `ratios [ a/b, c/d, ... ]` — explicit frequency ratios (one per
  /// scale step) inside a 2/1 octave.
  Ratios(Array[(Int, Int)])
  /// `ratios_per_period { period: p/q, steps: N }` — equal divisions
  /// of an arbitrary period (Bohlen-Pierce uses 3/1, for example).
  RatiosPerPeriod(period_num~ : Int, period_den~ : Int, steps~ : Int)
  /// `cents [ x1, x2, ... ]` — cents offsets relative to 12-EDO for
  /// each of the 12 chromatic steps.
  Cents(Array[Double])
}

///|
/// Tuning declaration — `tuning Name = <mode> { … }`.
pub struct TuningDef {
  name : Ident
  mode : TuningMode
}

///|
pub fn TuningDef::new(name : Ident, mode : TuningMode) -> TuningDef {
  { name, mode }
}

///|
pub fn TuningDef::name(self : TuningDef) -> Ident {
  self.name
}

///|
pub fn TuningDef::mode(self : TuningDef) -> TuningMode {
  self.mode
}

///|
/// Groove template — per-slot timing offsets (in fractions of a slot)
/// that repeat every `length` slots. Positive offsets push the slot
/// late; negative offsets pull it early.
pub struct GrooveDef {
  name : Ident
  length : Int
  steps : Array[Double]
}

///|
pub fn GrooveDef::new(
  name : Ident,
  length : Int,
  steps : Array[Double],
) -> GrooveDef {
  { name, length, steps }
}

///|
pub fn GrooveDef::name(self : GrooveDef) -> Ident {
  self.name
}

///|
pub fn GrooveDef::length(self : GrooveDef) -> Int {
  self.length
}

///|
pub fn GrooveDef::steps(self : GrooveDef) -> Array[Double] {
  self.steps
}

///|
/// Effect declaration — names a reusable effect (or effect chain).
///
/// The body stays a free-form `Expr` so the surface can grow
/// (delays, reverbs, granular, custom DSP) without further AST work;
/// the evaluator validates the shape.
pub struct EffectDef {
  name : Ident
  body : @core.Spanned[Expr]
}

///|
pub fn EffectDef::new(name : Ident, body : @core.Spanned[Expr]) -> EffectDef {
  { name, body }
}

///|
pub fn EffectDef::name(self : EffectDef) -> Ident {
  self.name
}

///|
pub fn EffectDef::body(self : EffectDef) -> @core.Spanned[Expr] {
  self.body
}

///|
/// A bus inside a `mix { ... }` block — a named effect chain that
/// other tracks feed into via `send`.
pub struct BusDef {
  name : Ident
  chain : @core.Spanned[Expr]
}

///|
pub fn BusDef::new(name : Ident, chain : @core.Spanned[Expr]) -> BusDef {
  { name, chain }
}

///|
pub fn BusDef::name(self : BusDef) -> Ident {
  self.name
}

///|
pub fn BusDef::chain(self : BusDef) -> @core.Spanned[Expr] {
  self.chain
}

///|
/// A send routing — `send <bus> <amount>` — dispatches part of a
/// track's signal into a named bus.
pub struct SendDef {
  bus : Ident
  amount : @core.Spanned[Expr]
}

///|
pub fn SendDef::new(bus : Ident, amount : @core.Spanned[Expr]) -> SendDef {
  { bus, amount }
}

///|
pub fn SendDef::bus(self : SendDef) -> Ident {
  self.bus
}

///|
pub fn SendDef::amount(self : SendDef) -> @core.Spanned[Expr] {
  self.amount
}

///|
/// Sidechain link — the source track ducks the target's amplitude.
/// `amount` is the duck depth (0..1).
pub struct SidechainDef {
  source : Ident
  target : Ident
  amount : @core.Spanned[Expr]
}

///|
pub fn SidechainDef::new(
  source : Ident,
  target : Ident,
  amount : @core.Spanned[Expr],
) -> SidechainDef {
  { source, target, amount }
}

///|
pub fn SidechainDef::source(self : SidechainDef) -> Ident {
  self.source
}

///|
pub fn SidechainDef::target(self : SidechainDef) -> Ident {
  self.target
}

///|
pub fn SidechainDef::amount(self : SidechainDef) -> @core.Spanned[Expr] {
  self.amount
}

///|
/// Mix block — top-level routing graph. Tracks are the parts being
/// mixed; buses are named effect chains; sends route signal into the
/// buses; sidechains key amplitude ducking; master is the final chain
/// applied to the summed output.
pub struct MixDef {
  tracks : Array[@core.Spanned[Expr]]
  buses : Array[BusDef]
  sends : Array[SendDef]
  sidechains : Array[SidechainDef]
  master : (@core.Spanned[Expr])?
}

///|
pub fn MixDef::new(
  tracks : Array[@core.Spanned[Expr]],
  buses : Array[BusDef],
  sends : Array[SendDef],
  sidechains : Array[SidechainDef],
  master : (@core.Spanned[Expr])?,
) -> MixDef {
  { tracks, buses, sends, sidechains, master }
}

///|
pub fn MixDef::empty() -> MixDef {
  { tracks: [], buses: [], sends: [], sidechains: [], master: None }
}

///|
pub fn MixDef::tracks(self : MixDef) -> Array[@core.Spanned[Expr]] {
  self.tracks
}

///|
pub fn MixDef::buses(self : MixDef) -> Array[BusDef] {
  self.buses
}

///|
pub fn MixDef::sends(self : MixDef) -> Array[SendDef] {
  self.sends
}

///|
pub fn MixDef::sidechains(self : MixDef) -> Array[SidechainDef] {
  self.sidechains
}

///|
pub fn MixDef::master(self : MixDef) -> (@core.Spanned[Expr])? {
  self.master
}
