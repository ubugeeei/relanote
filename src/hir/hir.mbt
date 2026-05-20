///|
/// Typed HIR expression. Wraps an `Expr`-shaped node with its inferred
/// type, preserving the original AST node's span for diagnostics.
pub struct TypedExpr {
  kind : TypedExprKind
  ty : @types.Type
  span : @core.Span
}

///|
pub fn TypedExpr::new(kind : TypedExprKind, ty : @types.Type) -> TypedExpr {
  { kind, ty, span: @core.Span::dummy() }
}

///|
pub fn TypedExpr::with_span(
  kind : TypedExprKind,
  ty : @types.Type,
  span : @core.Span,
) -> TypedExpr {
  { kind, ty, span }
}

///|
pub fn TypedExpr::kind(self : TypedExpr) -> TypedExprKind {
  self.kind
}

///|
pub fn TypedExpr::ty(self : TypedExpr) -> @types.Type {
  self.ty
}

///|
pub fn TypedExpr::span(self : TypedExpr) -> @core.Span {
  self.span
}

///|
/// Kinds of typed HIR expressions. Only the scalar / identifier /
/// composite forms are modelled today; music-specific constructs
/// (Block / Part / Section / …) are carried opaquely as their AST
/// node, mirroring how the evaluator handles them.
pub(all) enum TypedExprKind {
  /// Integer literal.
  TInteger(Int64)
  /// Float literal.
  TFloat(Double)
  /// String literal.
  TString(String)
  /// Boolean literal.
  TBool(Bool)
  /// Unit literal.
  TUnit
  /// Identifier reference (resolved to a top-level binding or local).
  TIdent(@core.InternedStr)
  /// Function application — `func(args...)`.
  TApp(TypedExpr, Array[TypedExpr])
  /// Lambda literal — `\x -> body`. Parameter list is preserved
  /// alongside the function's type so codegen knows which arguments
  /// to bind.
  TLambda(Array[@core.InternedStr], TypedExpr)
  /// Let-in expression — `let pat = value in body`.
  TLet(@core.InternedStr, TypedExpr, TypedExpr)
  /// Pipe — `arg |> func`.
  TPipe(TypedExpr, TypedExpr)
  /// If/then/else; the else branch is optional in source but the
  /// HIR fills in `TUnit` when missing so codegen always sees both.
  TIf(TypedExpr, TypedExpr, TypedExpr)
  /// Error recovery — propagates the inference failure forward.
  TError
  /// Catch-all for AST nodes the lowering pass doesn't model yet
  /// (Match / With / Field / InScale / Over, music structures).
  Placeholder
}

///|
/// HIR program — a list of typed items.
pub struct TypedProgram {
  items : Array[TypedItem]
}

///|
pub fn TypedProgram::new(items : Array[TypedItem]) -> TypedProgram {
  { items, }
}

///|
pub fn TypedProgram::empty() -> TypedProgram {
  { items: [] }
}

///|
pub fn TypedProgram::items(self : TypedProgram) -> Array[TypedItem] {
  self.items
}

///|
/// Top-level items in the HIR. Mirrors the AST's `Item` variants the
/// lowering pass cares about — scalar definitions, `let` / `set`
/// bindings, function definitions, and bare expression statements.
pub(all) enum TypedItem {
  /// `scale Name = { ... }` — name only; the interval list is kept
  /// for the renderer.
  TScaleDef(@core.InternedStr, @types.Type)
  /// `chord Name = [ ... ]`.
  TChordDef(@core.InternedStr, @types.Type)
  /// `synth Name = { ... }`.
  TSynthDef(@core.InternedStr, @types.Type)
  /// `let name = value`.
  TLetBinding(@core.InternedStr, TypedExpr)
  /// `set name = value`.
  TSetBinding(@core.InternedStr, TypedExpr)
  /// `let f x y = body` lowered to a typed lambda binding.
  TFunctionDef(@core.InternedStr, TypedExpr)
  /// Bare expression statement.
  TExprStmt(TypedExpr)
  /// Items the lowering pass treats as no-ops (imports / exports /
  /// mod / use, tuning / groove / effect / mix declarations).
  TNoop
}
