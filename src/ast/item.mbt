///|
/// Top-level item in a `Program`.
pub(all) enum Item {
  /// `scale Major = { R, M2, ... }`.
  ScaleDef(ScaleDef)
  /// `chord Tonic7 = [ R, M3, P5, M7 ]`.
  ChordDef(ChordDef)
  /// `synth Lead = { osc: Saw, env: { ... } }`.
  SynthDef(SynthDef)
  /// `tuning JustIntonation = ratios [ ... ]`.
  TuningDef(TuningDef)
  /// `groove Dilla = offsets { ... }`.
  GrooveDef(GrooveDef)
  /// `effect DubDelay = delay { ... }`.
  EffectDef(EffectDef)
  /// `mix { ... }` — top-level routing graph.
  MixDef(MixDef)
  /// Top-level `let x = expr`.
  LetBinding(LetBinding)
  /// Built-in configuration binding — `set key = C4`, `set tempo = 120`.
  SetBinding(SetBinding)
  /// Sugar for `let f = \x -> \y -> expr` — `let f x y = expr`.
  FunctionDef(FunctionDef)
  /// JavaScript-style `import` declaration.
  Import(ImportDecl)
  /// JavaScript-style `export` declaration.
  Export(ExportDecl)
  /// Module declaration — `mod foo`.
  Mod(ModDecl)
  /// Module import — `use foo::bar`.
  Use(UseDecl)
  /// Top-level expression statement (e.g. `render(...)`).
  ExprStmt(@core.Spanned[Expr])
}

///|
/// Top-level `let` binding.
pub struct LetBinding {
  pattern : @core.Spanned[Pattern]
  type_ann : TypeAnnotation?
  value : @core.Spanned[Expr]
}

///|
pub fn LetBinding::new(
  pattern : @core.Spanned[Pattern],
  type_ann : TypeAnnotation?,
  value : @core.Spanned[Expr],
) -> LetBinding {
  { pattern, type_ann, value }
}

///|
pub fn LetBinding::pattern(self : LetBinding) -> @core.Spanned[Pattern] {
  self.pattern
}

///|
pub fn LetBinding::type_ann(self : LetBinding) -> TypeAnnotation? {
  self.type_ann
}

///|
pub fn LetBinding::value(self : LetBinding) -> @core.Spanned[Expr] {
  self.value
}

///|
/// `set` binding for built-in configuration variables — `key`, `tempo`.
pub struct SetBinding {
  name : Ident
  value : @core.Spanned[Expr]
}

///|
pub fn SetBinding::new(name : Ident, value : @core.Spanned[Expr]) -> SetBinding {
  { name, value }
}

///|
pub fn SetBinding::name(self : SetBinding) -> Ident {
  self.name
}

///|
pub fn SetBinding::value(self : SetBinding) -> @core.Spanned[Expr] {
  self.value
}

///|
/// Function definition (sugar for a `LetBinding` containing a `Lambda`).
pub struct FunctionDef {
  name : Ident
  params : Array[@core.Spanned[Pattern]]
  return_type : TypeAnnotation?
  body : @core.Spanned[Expr]
}

///|
pub fn FunctionDef::new(
  name : Ident,
  params : Array[@core.Spanned[Pattern]],
  return_type : TypeAnnotation?,
  body : @core.Spanned[Expr],
) -> FunctionDef {
  { name, params, return_type, body }
}

///|
pub fn FunctionDef::name(self : FunctionDef) -> Ident {
  self.name
}

///|
pub fn FunctionDef::params(self : FunctionDef) -> Array[@core.Spanned[Pattern]] {
  self.params
}

///|
pub fn FunctionDef::return_type(self : FunctionDef) -> TypeAnnotation? {
  self.return_type
}

///|
pub fn FunctionDef::body(self : FunctionDef) -> @core.Spanned[Expr] {
  self.body
}

///|
/// `import` declaration.
pub struct ImportDecl {
  items : Array[ImportItem]
  from : String
}

///|
pub fn ImportDecl::new(items : Array[ImportItem], from : String) -> ImportDecl {
  { items, from }
}

///|
pub fn ImportDecl::items(self : ImportDecl) -> Array[ImportItem] {
  self.items
}

///|
pub fn ImportDecl::from(self : ImportDecl) -> String {
  self.from
}

///|
pub(all) enum ImportItem {
  /// `import foo from "module"`.
  Named(Ident)
  /// `import foo as bar from "module"`.
  Aliased(name~ : Ident, as_name~ : Ident)
  /// `import * from "module"`.
  All
  /// `import * as M from "module"`.
  AllAliased(Ident)
}

///|
/// `export` declaration.
pub(all) enum ExportDecl {
  /// `export foo, bar`.
  Named(Array[Ident])
  /// `export let foo = ...` — wraps a definition.
  Definition(Item)
  /// `export { foo } from "module"`.
  ReExport(items~ : Array[Ident], from~ : String)
}

///|
/// `mod foo` declaration.
pub struct ModDecl {
  name : Ident
}

///|
pub fn ModDecl::new(name : Ident) -> ModDecl {
  { name, }
}

///|
pub fn ModDecl::name(self : ModDecl) -> Ident {
  self.name
}

///|
/// `use foo::bar` declaration.
pub struct UseDecl {
  path : UsePath
}

///|
pub fn UseDecl::new(path : UsePath) -> UseDecl {
  { path, }
}

///|
pub fn UseDecl::path(self : UseDecl) -> UsePath {
  self.path
}

///|
/// Path in a `use` declaration.
pub struct UsePath {
  segments : Array[Ident]
  kind : UseKind
}

///|
pub fn UsePath::new(segments : Array[Ident], kind : UseKind) -> UsePath {
  { segments, kind }
}

///|
pub fn UsePath::segments(self : UsePath) -> Array[Ident] {
  self.segments
}

///|
pub fn UsePath::kind(self : UsePath) -> UseKind {
  self.kind
}

///|
/// Trailing shape of a `use` path.
pub(all) enum UseKind {
  /// `use foo::bar` — import the final segment as-is.
  Simple
  /// `use foo::*` — import everything.
  Glob
  /// `use foo::{bar, baz}` — import multiple items.
  Group(Array[UseItem])
}

///|
/// An item in a `use foo::{ ... }` group.
