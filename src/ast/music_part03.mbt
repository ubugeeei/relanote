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
  key : @core.Spanned[Expr]?
  scale : @core.Spanned[Expr]?
  tempo : @core.Spanned[Expr]?
}

///|
pub fn SectionContext::new(
  key : @core.Spanned[Expr]?,
  scale : @core.Spanned[Expr]?,
  tempo : @core.Spanned[Expr]?,
) -> SectionContext {
  { key, scale, tempo }
}

///|
pub fn SectionContext::key(self : SectionContext) -> @core.Spanned[Expr]? {
  self.key
}

///|
pub fn SectionContext::scale(self : SectionContext) -> @core.Spanned[Expr]? {
  self.scale
}

///|
pub fn SectionContext::tempo(self : SectionContext) -> @core.Spanned[Expr]? {
  self.tempo
}

///|
/// Layer expression: `layer [ part1, part2, ... ]`.
pub struct LayerExpr {
  parts : Array[@core.Spanned[Expr]]
}

///|
pub fn LayerExpr::new(parts : Array[@core.Spanned[Expr]]) -> LayerExpr {
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
