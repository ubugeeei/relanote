///|
/// Typed HIR expression. Mirrors `relanote_hir::hir::TypedExpr` in the
/// Rust crate, which is itself only a placeholder right now.
pub struct TypedExpr {
  kind : TypedExprKind
  ty : @types.Type
}

///|
pub fn TypedExpr::new(kind : TypedExprKind, ty : @types.Type) -> TypedExpr {
  { kind, ty }
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
/// Kinds of typed HIR expressions. The Rust crate still ships only the
/// `Placeholder` variant — the actual lowering work is tracked in #5.
pub(all) enum TypedExprKind {
  Placeholder
} derive(Eq)

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
/// Top-level items in the HIR. Mirrors `relanote_hir::hir::TypedItem`.
pub(all) enum TypedItem {
  Placeholder
} derive(Eq)
